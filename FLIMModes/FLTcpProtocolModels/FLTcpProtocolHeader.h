//
//  FLTcpProtocolHeader.h
//  FuLiaoApplet
//
//  Created by john fine on 2018/2/28.
//  Copyright © 2018年 FuLiao. All rights reserved.
// 
//  describe: TCP服务器协议头
//

// 服务类型
enum
{
    SID_NONE              = 0,
    SID_COMM              = 1,   // 公用消息大类
};

// 公共消息类型
enum
{
    CID_COMM_HEART_BEAT            = 0,     // 心跳消息
    CID_COMM_ACK                   = 1,     // 成功提示消息
    CID_COMM_ANK                   = 2,     // 失败提示消息
    CID_COMM_USER_INFO_CHANGE      = 3,     //
    CID_COMM_NOTIFY                = 10,    // 通用的通知消息
};

#define CID_NONE 0

#define TimeOutInterval 10

#import <Foundation/Foundation.h>

@interface FLTcpProtocolHeader : NSObject

/** 包长度 = header + body*/
@property (nonatomic, assign) UInt32 length;

/** 版本号 1*/
@property (nonatomic, assign) UInt8 verson;

/** 校验码 发送前算一遍（整个帧的每个字节相加后取反再加1）接收时用于校验帧的对错（一个正确的帧每个字节相加结果应该等于0，不等于0时丢弃这个帧）*/
@property (nonatomic, assign) UInt8 checkCode;

/** 主命令码*/
@property (nonatomic, assign) UInt16 serviceID;

/** 子命令码*/
@property (nonatomic, assign) UInt16 commandID;

/** 序列号*/
@property (nonatomic, assign) UInt32 seqNO;

/** 用户ID*/
@property (nonatomic, assign) UInt32 uid;

@end
