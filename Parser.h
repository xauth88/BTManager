//
//  Parser.h
//  BLEComm
//
//  Created by Tereshkin Sergey on 06/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol ParserDelegate

- (void) flowValueUpdated:(int) value;
- (void) testEndedWith:(int) quality pefValue:(int)pef fev1Value:(int)fev1 extVolumeValue:(int) extVolume timeToPefValue:(int) timeToPef;
- (void) deviceSentCodeEsc;

@end

@interface Parser : NSObject

@property (strong, nonatomic) id<ParserDelegate> delegate;

- (instancetype)initWithProtocolName:(int) protocolName andDelegate:(id) delegate;
- (void) handlePacket: (unsigned char *)packet;

@end
