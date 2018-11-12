//
//  FLSocketManager.h
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
// 
//  describe: 底层 socket 通信管理: 连接、重连、心跳保活、数据收发
//

#import <Foundation/Foundation.h>

/**
 socket 状态

 - FLSocketStatusNone: 未连接
 - FLSocketStatusConnected: 连接
 - FLSocketStatusDisconnected: 断线
 - FLSocketStatusCutoff: 连接被掐断
 - FLSocketStatusReconnectFailure: 重连失败
 */
typedef NS_ENUM(NSUInteger, FLSocketStatus) {
    FLSocketStatusNone,
    FLSocketStatusConnected,
    FLSocketStatusDisconnected,
    FLSocketStatusCutoff
};

#define FLTcpProtocolHeaderLength 18

#define FLTcpStatusDisconnect @"FLTcpStatusDisconnect"

#define FLTcpStatusConnected @"FLTcpStatusConnected"

@protocol FLSocketDataSource <NSObject>

- (void)socketDidReceiveData:(NSData *)data;

- (void)socketDidWriteDataWithTag:(long)tag;

@end

@interface FLSocketManager : NSObject

/** socket 状态*/
@property (nonatomic, assign) FLSocketStatus socketStatus;

/** socket数据代理*/
@property (nonatomic, assign) id<FLSocketDataSource> dataSource;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/**
 单例

 @return 单例
 */
+ (instancetype)sharedManager;

/**
 连接IM服务器

 @param host 服务器地址
 @param port 端口
 @param status 状态
 @return 是否连接成功
 */
- (BOOL)connect:(NSString *)host port:(NSInteger)port status:(NSInteger)status;

/**
 断开IM连接
 */
- (void)disconnect;

/**
 发送数据

 @param data 数据
 @param tag 序列号
 */
- (void)writeToScoket:(NSData *)data tag:(long)tag;

@end
