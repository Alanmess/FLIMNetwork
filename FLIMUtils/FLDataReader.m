//
//  FLDataReader.m
//  FLApplet
//
//  Created by john fine on 2018/2/28.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 读取基本数据类型
//

#import "FLDataReader.h"

@interface FLDataReader()

- (int32_t)read;

@end

@implementation FLDataReader

- (instancetype)intWithData:(NSData *)data {
    if ([self init]) {
        _data = [[NSData alloc] initWithData:data];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _length = 0;
    }
    return self;
}

+ (instancetype)dataReaderWithData:(NSData *)data {
    FLDataReader *dataReader = [[self alloc] initWithData:data];
    return dataReader;
}

- (NSUInteger)getAvailabledLength {
    return [_data length];
}

- (int32_t)read {
    int8_t v;
    [_data getBytes:&v range:NSMakeRange(_length, 1)];
    _length++;
    return ((int32_t)v & 0x0ff);
}

- (int8_t)readChar {
    int8_t v;
    [_data getBytes:&v range:NSMakeRange(_length, 1)];
    _length++;
    return (v & 0x0ff);
}

- (int16_t)readShort {
    int32_t ch1 = [self read];
    int32_t ch2 = [self read];
    if ((ch1 | ch2) < 0) {
        @throw [NSException exceptionWithName:@"Exception" reason:@"EOFException" userInfo:nil];
    }
    return (int16_t)((ch1 << 8) + (ch2 << 0));
}

- (int32_t)readInt {
    int32_t ch1 = [self read];
    int32_t ch2 = [self read];
    int32_t ch3 = [self read];
    int32_t ch4 = [self read];
    if ((ch1 | ch2 | ch3 | ch4) < 0){
        @throw [NSException exceptionWithName:@"Exception" reason:@"EOFException" userInfo:nil];
    }
    return ((ch1 << 24) + (ch2 << 16) + (ch3 << 8) + (ch4 << 0));
}

- (int64_t)readLong {
    int8_t ch[8];
    [_data getBytes:&ch range:NSMakeRange(_length,8)];
    _length = _length + 8;
    
    return (((int64_t)ch[0] << 56) +
            ((int64_t)(ch[1] & 0x0ff) << 48) +
            ((int64_t)(ch[2] & 0x0ff) << 40) +
            ((int64_t)(ch[3] & 0x0ff) << 32) +
            ((int64_t)(ch[4] & 0x0ff) << 24) +
            ((ch[5] & 0x0ff) << 16) +
            ((ch[6] & 0x0ff) <<  8) +
            ((ch[7] & 0x0ff) <<  0));
}

- (NSString *)readUTF {
    int32_t utfLength = [self readInt];
    NSData *d = [_data subdataWithRange:NSMakeRange(_length,utfLength)];
    NSString *str = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    _length = _length + utfLength;
    return str;
}

-(NSData *)readDataWithLength:(int)length {
    NSData *d =[_data subdataWithRange:NSMakeRange(_length, length)];
    _length = _length +length;
    return d;
}

-(NSData *)readLeftData {
    if ([_data length] > _length) {
        NSData *data =[_data subdataWithRange:NSMakeRange(_length, [_data length] - _length)];
        _length = [_data length];
        return data;
    }
    return  nil;
}

@end
