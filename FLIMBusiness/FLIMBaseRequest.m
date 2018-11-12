//
//  FLIMBaseRequest.m
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: IM 请求基类
//

#import "FLIMBaseRequest.h"
#import "FLRequestProtocol.h"
#import "FLTcpProtocolHeader.h"
#import "FLIMScheduler.h"

static uint16_t kTheSeqNo = 0;

@implementation FLIMBaseRequest

- (void)requestWithObject:(id)object completion:(FLRequestCompletionBlock)completion {
    kTheSeqNo++;
    
    _seqNo = kTheSeqNo;
        
    // 注册请求
    [[FLIMScheduler sharedSchedule] registerRequest:(id<FLRequestProtocol>)self];
    
    // 保存完成回调
    self.completionBlock = completion;
    
    // 数据打包
    FLPackageData package = [(id<FLRequestProtocol>)self packageRequest];
    NSData *data = package(object, _seqNo);
    
    // 注册网络可用重发请求
    if ([(id<FLRequestProtocol>)self requestWhenSocketConnected]) {
        [[FLIMScheduler sharedSchedule] registerNetAvaliableRequest:(id<FLRequestProtocol>)self];
        [[FLIMScheduler sharedSchedule] registerResendRequest:(id<FLRequestProtocol>)self data:data];
    } else if ([(id<FLRequestProtocol>)self requestTimeOutInterval] > 0) { // 注册超时请求
        [[FLIMScheduler sharedSchedule] registerTimeoutRequest:(id<FLRequestProtocol>)self];
    }
    
    if (data) {
        [[FLIMScheduler sharedSchedule] sendData:data tag:_seqNo];
    }
}

- (int)requestTimeOutInterval {
    return TimeOutInterval;
}

- (int)requestResendCount {
    return 0;
}

- (BOOL)requestWhenSocketConnected {
    return NO;
}

- (int)requestServiceID {
    return SID_NONE;
}

- (int)responseServiceID {
    return SID_NONE;
}

- (int)requestCommendID {
    return CID_NONE;
}

- (int)responseCommendID {
    return CID_NONE;
}

- (FLUnpackageData)unpackageResponse {
    return nil;
}

- (FLPackageData)packageRequest {
    return nil;
}

@end
