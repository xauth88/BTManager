//
//  BTUtils.h
//  BLEComm
//
//  Created by Tereshkin Sergey on 06/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BTUtils : NSObject

+ (char) calculateCheckSum: (unsigned char*) packet withLength: (int) length;
+ (void) dumpPacket: ( unsigned char*) packet;
+ (BOOL) deviceStatusFor:(int) request;

@end
