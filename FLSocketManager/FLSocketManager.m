//
//  FLSocketManager.m
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 底层 socket 通信管理: 连接、重连、心跳保活、数据收发
//

#import "FLSocketManager.h"
#import "GCDAsyncSocket.h"
#import "FLIMUtils.h"
#import <pthread/pthread.h>
#import "FLDataReader.h"
#import "FLTcpProtocolHeader.h"
#import "FLSocketManager+HeartBeat.h"
#import "FLSocketManager+SocketReconnect.h"

#define Lock() pthread_mutex_lock(&_lock)

#define Unlock() pthread_mutex_unlock(&_lock)

@interface FLSocketManager() <GCDAsyncSocketDelegate>

@end

@implementation FLSocketManager {
    GCDAsyncSocket *_socket;
    pthread_mutex_t _lock;

    void *IsOnManagerQueue;
    NSMutableData *_receiveBuffer;
    dispatch_queue_t _managerQueue;
}

#pragma mark - life circle

+ (FLSocketManager *)sharedManager {
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
        _receiveBuffer = [NSMutableData data];
        
        pthread_mutex_init(&_lock, NULL);
        
        _managerQueue = dispatch_queue_create("com.fuliao.imagent.manager", DISPATCH_QUEUE_SERIAL);
        
        IsOnManagerQueue = &IsOnManagerQueue;
        
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(_managerQueue, IsOnManagerQueue, nonNullUnusedPointer, NULL);
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_managerQueue];
    }
    return self;
}

- (void)dealloc {
#if !OS_OBJECT_USE_OBJC
    if (_managerQueue) dispatch_release(_managerQueue);
#endif
    _managerQueue = NULL;
}

#pragma mark - public method

- (BOOL)connect:(NSString *)host port:(NSInteger)port status:(NSInteger)status {
    __block BOOL result = NO;
    
    dispatch_block_t block = ^ {
        if (!_socket) {
            result = NO;
        } else {
            [self _cutoffCurrentConnect];
            
            NSError *error;
            result = [_socket connectToHost:host onPort:port error:&error];
            
            if (error) {
                
            }
        }
    };
    
    if (dispatch_get_specific(IsOnManagerQueue)) {
        block();
    } else {
        dispatch_async(_managerQueue, block);
    }
    
    return result;
}

- (void)disconnect {
    dispatch_block_t block = ^ {
        _socketStatus = FLSocketStatusCutoff;
        
        [_socket disconnect];
    };
    
    if (dispatch_get_specific(IsOnManagerQueue)) {
        block();
    } else {
        dispatch_async(_managerQueue, block);
    }
}

- (void)writeToScoket:(NSData *)data tag:(long)tag {
    dispatch_block_t block = ^ {
        if (_socket) {
            [_socket writeData:data withTimeout:-1 tag:tag];
        }
    };
    
    if (dispatch_get_specific(IsOnManagerQueue)) {
        block();
    } else {
        dispatch_async(_managerQueue, block);
    }
}

#pragma mark - private method

- (BOOL)_verifyPacket:(NSData *)data {
    Byte *bytes = (Byte *)[data bytes];
    
    char sum = 0;
    for (int i = 0; i < [data length]; i++) {
        sum += bytes[i];
    }
    
    return sum == 0;
}

- (void)_cutoffCurrentConnect {
    dispatch_block_t block = ^ {
        if (_socket && _socket.isConnected) {
            [_socket disconnect];
        }
    };
    
    if (dispatch_get_specific(IsOnManagerQueue)) {
        block();
    } else {
        dispatch_async(_managerQueue, block);
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    if (sock != _socket) {
        return;
    }
    
    _socketStatus = FLSocketStatusConnected;
    
    [_socket readDataWithTimeout:10 tag:0];
    
    // 启动心跳机制
    [self startHeartBeat];
    
    // 停止重连
    [self stopReconnect];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 发送 socket 连接通知
        [[NSNotificationCenter defaultCenter] postNotificationName:FLTcpStatusConnected object:nil];
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    if (sock != _socket) {
        return;
    }
    
    // 停止心跳机制
    [self stopHeartBeat];
    
    // 主动掐断socket连接不进行重连
    if (_socketStatus == FLSocketStatusCutoff) {
        return;
    }
    
    _socketStatus = FLSocketStatusDisconnected;
    
    // 开启重连
    [self startReconnect];
    
    // 需要重新登录服务器
    dispatch_async(dispatch_get_main_queue(), ^{
        // 发送 socket 断线通知
        [[NSNotificationCenter defaultCenter] postNotificationName:FLTcpStatusDisconnect object:nil];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (sock != _socket) {
        return;
    }
    
    Lock();
    
    [_receiveBuffer appendData:data];
    
    // 拆包
    while ([_receiveBuffer length] > FLTcpProtocolHeaderLength) {
        NSData *headerData = [_receiveBuffer subdataWithRange:NSMakeRange(0, FLTcpProtocolHeaderLength)];
        
        FLDataReader *dataReader = [[FLDataReader alloc] intWithData:headerData];
        
        uint32_t packetSize = [dataReader readInt];
        
        // 未接收完一个完整的包
        if (packetSize > [_receiveBuffer length]) {
            break;
        }
        
        // 接收完一个完整的包
        NSData *packetData = [_receiveBuffer subdataWithRange:NSMakeRange(0, packetSize)];
        if ([self _verifyPacket:packetData]) {
            // 数据回调
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(socketDidReceiveData:)]) {
                [self.dataSource socketDidReceiveData:packetData];
            }
        }
        
        // 删除包数据
        NSData *remainData = [_receiveBuffer subdataWithRange:NSMakeRange(packetSize, ([_receiveBuffer length] - packetSize))];
        [_receiveBuffer setData:remainData];
        
        [_socket readDataWithTimeout:30 tag:1];
    }
    
    Unlock();
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (sock != _socket) {
        return;
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(socketDidWriteDataWithTag:)]) {
        [self.dataSource socketDidWriteDataWithTag:tag];
    }
}

@end
