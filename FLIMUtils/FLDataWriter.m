//
//  FLDataWriter.m
//  FLApplet
//
//  Created by john fine on 2018/2/28.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 写入基本类型
//

#import "FLDataWriter.h"

@implementation FLDataWriter

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [[NSMutableData alloc] init];
        _length = 0;
    }
    return self;
}

- (void)writeChar:(int8_t)v {
    int8_t ch[1];
    ch[0] = (v & 0x0ff);
    [_data appendBytes:ch length:1];
    _length++;
}

- (void)writeShort:(int16_t)v {
    int8_t ch[2];
    ch[0] = (v & 0x0ff00)>>8;
    ch[1] = (v & 0x0ff);
    [_data appendBytes:ch length:2];
    _length = _length + 2;
}

- (void)writeInt:(int32_t)v {
    int8_t ch[4];
    for(int32_t i = 0; i < 4; i++){
        ch[i] = ((v >> ((3 - i)*8)) & 0x0ff);
    }
    [_data appendBytes:ch length:4];
    _length = _length + 4;
}

- (void)writeLong:(int64_t)v {
    int8_t ch[8];
    for(int32_t i = 0; i < 8; i++){
        ch[i] = ((v >> ((7 - i)*8)) & 0x0ff);
    }
    [_data appendBytes:ch length:8];
    _length = _length + 8;
}

- (void)writeUTF:(NSString *)v {
    NSData *d = [v dataUsingEncoding:NSUTF8StringEncoding];
    uint32_t len = (uint32_t)[d length];
    
    [self writeInt:len];
    [_data appendData:d];
    _length = _length + len;
}

- (void)writeData:(NSData *)v {
    int32_t len = (int32_t)[v length];
    [self writeInt:len];
    [_data appendData:v];
    
    _length = _length + len;
}

- (void)directWriteData:(NSData *)v {
    int32_t len = (int32_t)[v length];
    [_data appendData:v];
    _length = _length + len;
}

-(void)writeDataCount {
    int8_t ch[4];
    for(int32_t i = 0;i<4;i++){
        ch[i] = ((_length >> ((3 - i)*8)) & 0x0ff);
    }
    
    [_data replaceBytesInRange:NSMakeRange(0, 4) withBytes:ch];
}

- (NSMutableData *)toMutableData {
    return [[NSMutableData alloc] initWithData:_data];
}

- (NSData *)resultData {
    return _data;
}

- (NSData *)serializeDataWithSeqNo:(int)seqNo serviceID:(int)serviceID commandID:(int)commanID body:(NSData *)body {
    [self writeInt:(int32_t)(body.length+18)];
    [self writeChar:1];
    [self writeChar:0];
    [self writeShort:serviceID];
    [self writeShort:commanID];
    [self writeInt:seqNo];
    [self writeInt:0];
    [self directWriteData:body];
    int checkCode = [self verifyCheckCode:_data];
    
    Byte arr[] = {checkCode};
    NSMutableData *data = [self toMutableData];
    [data replaceBytesInRange:NSMakeRange(5, 1) withBytes:arr];
    
    return data;
}

- (int)verifyCheckCode:(NSData *)data {
    Byte *bytes = (Byte *)[data bytes];
    
    int sum = 0;
    for (int i = 0; i < [data length]; i++) {
        sum += bytes[i];
    }
    
    sum = ~sum;
    sum += 1;
    return sum;
}

@end
