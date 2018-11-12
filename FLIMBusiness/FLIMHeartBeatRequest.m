//
//  FLIMHeartBeatRequest.m
//  FLApplet
//
//  Created by john fine on 2018/3/5.
//  Copyright © 2018年 FuLiao. All rights reserved.
//
//  describe: 心跳
//

#import "FLIMHeartBeatRequest.h"
#import "FLRequestProtocol.h"
#import "Comm.pbobjc.h"
#import "FLDataWriter.h"
#import "FLIMUtils.h"

@implementation FLIMHeartBeatRequest

- (int)requestServiceID {
    return SID_COMM;
}

- (int)responseServiceID {
    return SID_COMM;
}

- (int)requestCommendID {
    return CID_COMM_HEART_BEAT;
}

- (int)responseCommendID {
    return CID_COMM_HEART_BEAT;
}

- (FLUnpackageData)unpackageResponse {
    FLUnpackageData unpackage = (id)^(NSData *data) {
        PBHeartBeat *heartBeat = [PBHeartBeat parseFromData:data error:nil];
        return heartBeat;
    };
    return unpackage;
}

- (FLPackageData)packageRequest {
    FLPackageData package = (id)^(id object,uint16_t seqNo) {
        PBHeartBeat *heartBeat = [[PBHeartBeat alloc] init];
        heartBeat.iCurStep = 0;
        NSData *body = [heartBeat data];
        
        FLDataWriter *writer = [[FLDataWriter alloc] init];
        
        return [writer serializeDataWithSeqNo:seqNo serviceID:SID_COMM commandID:CID_COMM_HEART_BEAT body:body];
    };

    return package;
}

@end
