//
//  FLSocketManager+SocketReconnect.h
//  FLApplet
//
//  Created by john fine on 2018/3/8.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 重连机制
//

#import "FLSocketManager.h"

typedef void(^GCDTask)(BOOL cancel);

@interface FLSocketManager (SocketReconnect)

/** 重连次数*/
@property (nonatomic, assign) int reconnectTimes;

/** 延时重连*/
@property (nonatomic, copy) GCDTask delayTask;

- (void)startReconnect;

- (void)stopReconnect;

@end
