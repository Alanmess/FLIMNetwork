//
//  FLIMBaseResponse.h
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
// 
//  describe: IM 推送消息
//

#import <Foundation/Foundation.h>

typedef void(^FLReceiveDataBlock)(id object, NSError *error);

@interface FLIMBaseUnrequest : NSObject

@property (nonatomic, copy) FLReceiveDataBlock receiveDataBlock;

- (BOOL)registerUnrequestInSchedule:(FLReceiveDataBlock)unrequest;

@end
