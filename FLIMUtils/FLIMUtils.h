//
//  FLIMUtils.h
//  FLApplet
//
//  Created by john fine on 2018/3/2.
//  Copyright © 2018年 FuLiao. All rights reserved.
// 
//  describe:
//

#import <Foundation/Foundation.h>

@interface FLIMUtils : NSObject

+ (BOOL)isAppActive;

+ (int)verifyCheckCode:(NSData *)data;

@end
