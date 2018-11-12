//
//  FLResponseScheduleProtocol.h
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: IM 推送消息处理协议
//

#import <Foundation/Foundation.h>

typedef id(^FLUnpackageData)(NSData *data);

@protocol FLUnrequestProtocol <NSObject>

@required
/**
 *  数据包中的serviceID
 *
 *  @return serviceID
 */
- (int)responseServiceID;

/**
 *  数据包中的commandID
 *
 *  @return commandID
 */
- (int)responseCommandID;

/**
 *  解析数据包
 *
 *  @return 解析数据包的block
 */
- (FLUnpackageData)unpackageResponse;

@end
