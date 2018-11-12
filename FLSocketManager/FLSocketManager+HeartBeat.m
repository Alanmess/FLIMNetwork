//
//  FLSocketManager+HeartBeat.m
//  FLApplet
//
//  Created by john fine on 2018/3/8.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 心跳机制
//

#import "FLSocketManager+HeartBeat.h"
#import "FLIMHeartBeatRequest.h"
#import <objc/runtime.h>

@implementation FLSocketManager (HeartBeat)

static char *kTimerKey = "HeartBeatTimer";

static char *kBeatFalseTimesKey = "BeatFalseTimes";

- (void)setHeartBeatTimer:(NSTimer *)heartBeatTimer {
    objc_setAssociatedObject(self, kTimerKey, heartBeatTimer, OBJC_ASSOCIATION_RETAIN);
}

- (NSTimer *)heartBeatTimer {
    return objc_getAssociatedObject(self, kTimerKey);
}

- (void)setBeatFalseTimes:(int)beatFalseTimes {
    objc_setAssociatedObject(self, kBeatFalseTimesKey, @(beatFalseTimes), OBJC_ASSOCIATION_RETAIN);
}

- (int)beatFalseTimes {
    return [objc_getAssociatedObject(self, kBeatFalseTimesKey) intValue];
}

- (void)startHeartBeat {
    [self stopHeartBeat];
    
    [self heartBeat];
    
    self.heartBeatTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(heartBeat) userInfo:nil repeats:YES];
    NSRunLoop* runloop = [NSRunLoop mainRunLoop];
    [runloop addTimer:self.heartBeatTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopHeartBeat {
    self.beatFalseTimes = 0;
    
    if (self.heartBeatTimer) {
        [self.heartBeatTimer invalidate];
    }
}

- (void)heartBeat {
    FLIMHeartBeatRequest *heartBeatRequest = [[FLIMHeartBeatRequest alloc] init];
    [heartBeatRequest requestWithObject:nil completion:^(id response, NSError *error) {
        if (error != nil) {
            self.beatFalseTimes++;
            if (self.beatFalseTimes > 3) {
                [self stopHeartBeat];
                [[NSNotificationCenter defaultCenter] postNotificationName:FLTcpStatusDisconnect object:nil];
            }
        } else {
            self.beatFalseTimes = 0;
        }
    }];
}

@end
