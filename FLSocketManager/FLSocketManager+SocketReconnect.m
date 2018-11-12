//
//  FLSocketManager+SocketReconnect.m
//  FLApplet
//
//  Created by john fine on 2018/3/8.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 重连机制
//

#import "FLSocketManager+SocketReconnect.h"
#import <objc/runtime.h>

static char *kReconnectTimesKey = "reconnectTimes";

static char *kDelayReconnectKey = "delayReconnect";

@implementation FLSocketManager (SocketReconnect)

- (void)setReconnectTimes:(int)reconnectTimes {
    objc_setAssociatedObject(self, kReconnectTimesKey, @(reconnectTimes), OBJC_ASSOCIATION_RETAIN);
}

- (int)reconnectTimes {
    return [objc_getAssociatedObject(self, kReconnectTimesKey) intValue];
}

- (void)setDelayTask:(GCDTask)delayTask {
    objc_setAssociatedObject(self, kDelayReconnectKey, delayTask, OBJC_ASSOCIATION_COPY);
}

- (GCDTask)delayTask {
    return objc_getAssociatedObject(self, kDelayReconnectKey);
}

- (void)startReconnect {
    int delaySeconds = 1;
    delaySeconds = self.reconnectTimes < 3 ? 1 : (self.reconnectTimes - 2) * 2 + 1;
    delaySeconds = delaySeconds < 60 ? delaySeconds : 60;
    
    [self _gcdCancelReconnect];
    
    [self _gcdDelayConnect:delaySeconds];
}

- (void)stopReconnect {
    self.reconnectTimes = 0;
    
    [self _gcdCancelReconnect];
}

- (void)_reconnect {
    self.reconnectTimes++;
    
    [self connect:@"192.168.1.200" port:35100 status:0];
}

- (void)_gcdCancelReconnect {
    if (self.delayTask) {
        self.delayTask(YES);
    }
}

- (void)_gcdDelayConnect:(NSTimeInterval)time {
    dispatch_block_t block = ^{
        [self _reconnect];
    };
    
    __block dispatch_block_t delayBlock = block;
    __block GCDTask delayTask;
    
    self.delayTask = ^(BOOL cancel) {
        if (delayBlock) {
            if (!cancel) {
                dispatch_async(dispatch_get_main_queue(), delayBlock);
            }
        }
        delayBlock = nil;
        delayTask = nil;
    };
    delayTask = self.delayTask;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (delayTask) {
            delayTask(NO);
        }
    });
}

@end
