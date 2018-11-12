//
//  FLDataWriter.h
//  FLApplet
//
//  Created by john fine on 2018/2/28.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 写入基本类型
//

#import <Foundation/Foundation.h>

@interface FLDataWriter : NSObject {
    NSMutableData *_data;
    NSInteger _length;
}

/**
 写入一个 1-byte char 值，先写入高字节

 @param v 1字节变量
 */
- (void)writeChar:(int8_t)v;

/**
 写入一个 2-byte short 值，先写入高字节

 @param v 2字节变量
 */
- (void)writeShort:(int16_t)v;

/**
 写入一个 4-byte int 值，先写入高字节

 @param v 4字节变量
 */
- (void)writeInt:(int32_t)v;

/**
 写入一个 8-byte long 值，先写入高字节

 @param v 8字节变量
 */
- (void)writeLong:(int64_t)v;

/**
 写入一个字符串

 @param v 字符串
 */
- (void)writeUTF:(NSString *)v;

/**
 写入data

 @param v data
 */
- (void)writeData:(NSData *)v;

/**
 写入data

 @param v data
 */
- (void)directWriteData:(NSData *)v;

/**
 写入数据长度
 */
- (void)writeDataCount;

/**
 转换为可变data

 @return 可变data
 */
- (NSMutableData *)toMutableData;

/**
 获取结果

 @return 结果
 */
- (NSData *)resultData;

/**
 序列化请求

 @param seqNo 序列号
 @param serviceID 主命令码
 @param commanID 子命令码
 @param body 消息体
 @return 序列化请求数据流
 */
- (NSData *)serializeDataWithSeqNo:(int)seqNo serviceID:(int)serviceID commandID:(int)commanID body:(NSData *)body;

@end
