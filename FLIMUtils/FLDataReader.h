//
//  FLDataReader.h
//  FLApplet
//
//  Created by john fine on 2018/2/28.
//  Copyright © 2018年 FuLiao. All rights reserved.
// 
//  describe: 读取基本数据类型
//

#import <Foundation/Foundation.h>

@interface FLDataReader : NSObject {
    NSData *_data;
    NSInteger _length;
}

- (instancetype)intWithData:(NSData *)data;

+ (instancetype)dataReaderWithData:(NSData *)data;

/**
 读取 char 值

 @return 1字节长度数据
 */
- (int8_t)readChar;

/**
 读取 short 值

 @return 2字节长度数据
 */
- (int16_t)readShort;

/**
 读取 int 值

 @return 4字节长度数据
 */
- (int32_t)readInt;

/**
 读取 long 值
 
 @return 8字节长度数据
 */
- (int64_t)readLong;

/**
 读取 NSString 字符串

 @return 字符串
 */
- (NSString *)readUTF;

/**
 读取指定长度数据
 
 @param length 读取长度
 @return 指定长度数据
 */
- (NSData *)readDataWithLength:(int)length;

/**
 读取剩余数据
 
 @return 剩余数据
 */
- (NSData *)readLeftData;

/**
 获取可读数据长度

 @return 可读数据长度
 */
- (NSUInteger)getAvailabledLength;

@end
