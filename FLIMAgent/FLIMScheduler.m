//
//  FLIMSchedule.m
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: IM 调度器: 消息收发、消息派发、请求超时管理
//

#import "FLIMScheduler.h"
#import "FLSocketManager.h"
#import "FLIMBaseRequest.h"
#import "FLIMBaseUnrequest.h"
#import "FLDataReader.h"

#define MAP_REQUEST_KEY(request) [NSString stringWithFormat:@"%i-%i-%i", [request requestServiceID], [request requestCommendID], [(FLIMBaseRequest *)request seqNo]]

#define MAP_RESPONSE_KEY(request) [NSString stringWithFormat:@"%i-%i-%i", [request responseServiceID], [request responseCommendID], [(FLIMBaseRequest *)request seqNo]]

#define MAP_DATA_RESPONSE_KEY(serviceID, commandID, seqNo) [NSString stringWithFormat:@"%i-%i-%i", serviceID, commandID, seqNo]

#define MAP_UNREQUEST_KEY(request) [NSString stringWithFormat:@"%i-%i", [request responseServiceID], [request responseCommandID]]

#define MAP_RESPONSE_UNREQUEST_KEY(serviceID, commandID) [NSString stringWithFormat:@"%i-%i", serviceID, commandID]

typedef NS_ENUM(NSUInteger, IMErrorCode) {
    TimeOut = 1001,
    Result = 1002
};

@interface FLIMScheduler () <FLSocketDataSource>

@end

@implementation FLIMScheduler {
    dispatch_queue_t _scheduleQueue;
    
    NSMutableDictionary *_requestMap; // IM 请求
    NSMutableDictionary *_responseMap; // IM 返回
    NSMutableDictionary *_unRequestMap; // 推送消息
    NSMutableDictionary *_netAvaliableRequestMap; // 网络可用时发送 IM 请求
    NSMutableDictionary *_requestPacketMap; // 重发消息体
    
    void *IsOnScheduleQueue;
}

+ (instancetype)sharedSchedule {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [FLSocketManager sharedManager].dataSource = self;
        
        _requestMap              = [[NSMutableDictionary alloc] init];
        _responseMap             = [[NSMutableDictionary alloc] init];
        _unRequestMap            = [[NSMutableDictionary alloc] init];
        _netAvaliableRequestMap  = [[NSMutableDictionary alloc] init];
        _requestPacketMap        = [[NSMutableDictionary alloc] init];

        _scheduleQueue = dispatch_queue_create("com.ipaychat.imschedule", DISPATCH_QUEUE_SERIAL);
        IsOnScheduleQueue = &IsOnScheduleQueue;
        
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(_scheduleQueue, IsOnScheduleQueue, nonNullUnusedPointer, NULL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(socketConcected) name:FLTcpStatusConnected object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(socketDisconnect) name:FLTcpStatusDisconnect object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
#if !OS_OBJECT_USE_OBJC
    if (_scheduleQueue) dispatch_release(_scheduleQueue);
#endif
    _scheduleQueue = NULL;
}

#pragma mark - nofification

- (void)socketConcected {
    dispatch_block_t block = ^ {
        [_netAvaliableRequestMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([_requestPacketMap.allKeys containsObject:key]) {
                NSData *data = [_requestPacketMap objectForKey:key];
                if (data && data.length) {
                    [self sendData:data tag:0];
                }
                
                [_requestPacketMap removeObjectForKey:key];
            }
            
            [_netAvaliableRequestMap removeObjectForKey:key];
        }];
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
}

- (void)socketDisconnect {
    dispatch_block_t block = ^ {
        [_requestMap removeAllObjects];
        [_responseMap removeAllObjects];
        [_netAvaliableRequestMap removeAllObjects];
        [_requestPacketMap removeAllObjects];
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
}

#pragma mark - public method

- (BOOL)registerNetAvaliableRequest:(id<FLRequestProtocol>)request {
    __block BOOL result = NO;
    
    dispatch_block_t block = ^ {
        if (![[_netAvaliableRequestMap allKeys] containsObject:MAP_REQUEST_KEY(request)]) {
            [_netAvaliableRequestMap setObject:request forKey:MAP_REQUEST_KEY(request)];
            result = YES;
        } else {
            result = NO;
        }
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
    
    return result;
}

- (BOOL)registerRequest:(id<FLRequestProtocol>)request {
    __block BOOL result = NO;
    
    dispatch_block_t block = ^ {
        if (![[_requestMap allKeys] containsObject:MAP_REQUEST_KEY(request)]) {
            [_requestMap setObject:request forKey:MAP_REQUEST_KEY(request)];
            result = YES;
        } else {
            result = NO;
        }
        
        if (![[_responseMap allKeys] containsObject:MAP_RESPONSE_KEY(request)]) {
            [_responseMap setObject:request forKey:MAP_RESPONSE_KEY(request)];
        }
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
    return result;
}

- (BOOL)registerUnrequest:(id<FLUnrequestProtocol>)unRequest {
    __block BOOL result = NO;
    
    dispatch_block_t block = ^ {
        if ([[_unRequestMap allKeys] containsObject:MAP_UNREQUEST_KEY(unRequest)]) {
            result = NO;
        } else {
            [_unRequestMap setObject:unRequest forKey:MAP_UNREQUEST_KEY(unRequest)];
            result = YES;
        }
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
    
    return result;
}

- (void)registerTimeoutRequest:(id<FLRequestProtocol>)request {
    double delaySeconds = [request requestTimeOutInterval];
    if (delaySeconds <= 0) {
        return;
    }
    
    BOOL resendWhennetAviable = [request requestWhenSocketConnected];
    if (resendWhennetAviable) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[_requestMap allKeys] containsObject:MAP_REQUEST_KEY(request)]) {
            FLRequestCompletionBlock completion = [(FLIMBaseRequest *)request completionBlock];
            NSError *error = [NSError errorWithDomain:@"请求超时" code:TimeOut userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, error);
                }
            });
            
            dispatch_async(_scheduleQueue, ^{
                [self _requestCompletion:request];
            });
        }
    });
}

- (void)registerResendRequest:(id<FLRequestProtocol>)request data:(NSData *)data {
    dispatch_block_t block = ^ {
        if (![_requestPacketMap.allKeys containsObject:MAP_REQUEST_KEY(request)] && data && data.length) {
            [_requestPacketMap setObject:data forKey:MAP_REQUEST_KEY(request)];
        }
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
}

- (void)sendData:(NSData *)data tag:(long)tag {
    dispatch_block_t block = ^ {
        [[FLSocketManager sharedManager] writeToScoket:data tag:tag];
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
}

- (void)cancelRequest:(id<FLRequestProtocol>)request {
    if ([[_requestMap allKeys] containsObject:MAP_REQUEST_KEY(request)]) {
        [_requestMap removeObjectForKey:MAP_REQUEST_KEY(request)];
    }
    
    if ([[_responseMap allKeys] containsObject:MAP_RESPONSE_KEY(request)]) {
        [_responseMap removeObjectForKey:MAP_RESPONSE_KEY(request)];
    }
    
    if ([[_netAvaliableRequestMap allKeys] containsObject:MAP_REQUEST_KEY(request)]) {
        [_netAvaliableRequestMap removeObjectForKey:MAP_REQUEST_KEY(request)];
    }
    
    if ([[_requestPacketMap allKeys] containsObject:MAP_REQUEST_KEY(request)]) {
        [_requestPacketMap removeObjectForKey:MAP_REQUEST_KEY(request)];
    }
    
    FLIMBaseRequest *newRequest = (FLIMBaseRequest *)request;
    newRequest.completionBlock = nil;
}

- (void)cancelAllRequest {
    [_requestMap removeAllObjects];
    [_responseMap removeAllObjects];
    [_netAvaliableRequestMap removeAllObjects];
    [_requestPacketMap removeAllObjects];
}

#pragma mark - private method

- (void)_requestCompletion:(id<FLRequestProtocol>)request {
    [_requestMap removeObjectForKey:MAP_REQUEST_KEY(request)];
    [_responseMap removeObjectForKey:MAP_RESPONSE_KEY(request)];
    [_netAvaliableRequestMap removeObjectForKey:MAP_REQUEST_KEY(request)];
    [_requestPacketMap removeObjectForKey:MAP_REQUEST_KEY(request)];
}

#pragma mark - FLSocketDataSource

- (void)socketDidReceiveData:(NSData *)data {
    FLDataReader *reader = [[FLDataReader alloc] intWithData:data];
    [reader readInt];
    [reader readChar];
    [reader readChar];
    int serviceID = [reader readShort];
    int commandID = [reader readShort];
    int seqNO = [reader readInt];
    [reader readInt];
    NSData *body = [reader readLeftData];
    
    dispatch_block_t block = ^ {
        NSString *key = MAP_DATA_RESPONSE_KEY(serviceID, commandID, seqNO);
        id<FLRequestProtocol> request = _responseMap[key];
        if (request) {
            FLRequestCompletionBlock completion = [(FLIMBaseRequest *)request completionBlock];
            FLUnpackageData unpackage = [request unpackageResponse];
            id response = unpackage(body);
            // 清除缓存
            [self _requestCompletion:request];
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(response, nil);
                });
            }
        } else {
            NSString *unrequestKey = MAP_RESPONSE_UNREQUEST_KEY(serviceID, commandID);
            id<FLUnrequestProtocol> unrequest = _unRequestMap[unrequestKey];
            if (unrequest) {
                FLUnpackageData unpackage = [unrequest unpackageResponse];
                id response = unpackage(body);
                FLReceiveDataBlock receiveDataBlock = [(FLIMBaseUnrequest *)unrequest receiveDataBlock];
                dispatch_async(dispatch_get_main_queue(), ^{
                    receiveDataBlock(response, nil);
                });
            }
        }
    };
    
    if (dispatch_get_specific(IsOnScheduleQueue)) {
        block();
    } else {
        dispatch_async(_scheduleQueue, block);
    }
}

- (void)socketDidWriteDataWithTag:(long)tag {
    
}

@end
