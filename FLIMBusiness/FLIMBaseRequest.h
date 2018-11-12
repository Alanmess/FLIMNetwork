//
//  FLIMBaseRequest.h
//  FLApplet
//
//  Created by fangjun on 2018/3/1.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: IM 请求基类
//

#import <Foundation/Foundation.h>
#import "FLTcpProtocolHeader.h"

typedef void(^FLRequestCompletionBlock)(id response, NSError *error);

@interface FLIMBaseRequest : NSObject

/** 序列号*/
@property (nonatomic, assign, readonly) uint16_t seqNo;

@property (nonatomic, copy) FLRequestCompletionBlock completionBlock;

- (void)requestWithObject:(id)object completion:(FLRequestCompletionBlock)completion;

@end
