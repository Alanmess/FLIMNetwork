//
//  FLIMSchedule.h
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: IM 请求调度器: 消息收发、消息派发、请求超时管理
//

#import <Foundation/Foundation.h>
#import "FLRequestProtocol.h"
#import "FLUnrequestProtocol.h"

@interface FLIMScheduler : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedSchedule;

/**
 注册IM请求

 @param request IM请求
 @return 是否注册成功
 */
- (BOOL)registerRequest:(id<FLRequestProtocol>)request;

/**
 注册 IM推送消息

 @param unRequest IM推送消息
 @return 是否注册成功
 */
- (BOOL)registerUnrequest:(id<FLUnrequestProtocol>)unRequest;

/**
 注册网络可用状态重发IM请求
 
 @param request IM请求
 @return 是否注册成功
 */
- (BOOL)registerNetAvaliableRequest:(id<FLRequestProtocol>)request;

/**
 注册超时IM请求

 @param request 超时IM请求
 */
- (void)registerTimeoutRequest:(id<FLRequestProtocol>)request;

/**
 注册重发消息请求

 @param request IM请求
 @param data 请求数据
 */
- (void)registerResendRequest:(id<FLRequestProtocol>)request data:(NSData *)data;

/**
 发送IM请求

 @param data IM请求数据
 */
- (void)sendData:(NSData *)data tag:(long)tag;

/**
 取消IM请求

 @param request IM请求
 */
- (void)cancelRequest:(id<FLRequestProtocol>)request;

/**
 取消所有IM请求
 */
- (void)cancelAllRequest;

@end
