//
//  FLSocketManager+HeartBeat.h
//  FLApplet
//
//  Created by john fine on 2018/3/8.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 心跳机制
//

#import "FLSocketManager.h"

@interface FLSocketManager (HeartBeat)

/** 心跳失败次数*/
@property (nonatomic, assign) int beatFalseTimes;

/** 心跳定时器*/
@property (nonatomic, strong) NSTimer *heartBeatTimer;

- (void)startHeartBeat;

- (void)stopHeartBeat;

@end
