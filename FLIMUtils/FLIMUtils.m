//
//  FLIMUtils.m
//  FLApplet
//
//  Created by john fine on 2018/3/2.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe:
//

#import "FLIMUtils.h"
#import <UIKit/UIKit.h>

@implementation FLIMUtils

+ (BOOL)isAppActive {
    return [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
}

+ (int)verifyCheckCode:(NSData *)data {
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
