//
//  FLIMBaseResponse.m
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: IM 推送消息
//

#import "FLIMBaseUnrequest.h"
#import "FLIMScheduler.h"

@implementation FLIMBaseUnrequest

- (BOOL)registerUnrequestInSchedule:(FLReceiveDataBlock)received {
    // 注册
    BOOL registerSuccess = [[FLIMScheduler sharedSchedule] registerUnrequest:(id<FLUnrequestProtocol>)self];
    
    // 赋值
    if (registerSuccess) {
        self.receiveDataBlock = received;
    }
    
    return registerSuccess;
}

@end
