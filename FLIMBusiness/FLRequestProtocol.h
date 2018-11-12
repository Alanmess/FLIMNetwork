//
//  FLRequestScheduleProtocol.h
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: IM 发起请求消息处理协议
//

#import <Foundation/Foundation.h>

// 打包数据
typedef NSMutableData* (^FLPackageData)(id object, uint16_t seqNo);

// 解包数据
typedef id(^FLUnpackageData)(NSData *data);

@protocol FLRequestProtocol <NSObject>

/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutInterval;

/**
 *  请求失败失败重新请求次数
 *
 *  @return 重新请求次数
 */
- (int)requestResendCount;

/**
 *  socket 连接断开情况下，重新连接是否重新请求
 *
 *  @return 是否重新请求
 */
- (BOOL)requestWhenSocketConnected;

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID;

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID;

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID;

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID;

/**
 重新发送请求
 */
- (void)resendRequest;

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (FLUnpackageData)unpackageResponse;

/**
 *  打包数据的block
 *
 *  @return 打包数据的block
 */
- (FLPackageData)packageRequest;

@end
