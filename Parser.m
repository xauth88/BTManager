//
//  Parser.m
//  BLEComm
//
//  Created by Tereshkin Sergey on 06/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "Parser.h"
#import "Defs.h"
#import "BTUtils.h"

@interface Parser ()

@property (nonatomic) int currentProtocolName;

@end

@implementation Parser

#pragma mark Initalization

- (instancetype)initWithProtocolName:(int) protocolName andDelegate:(id) delegate
{
    self = [super init];
    if (self) {
        self.currentProtocolName = protocolName;
        self.delegate = delegate;
    }
    return self;
}

- (void) handlePacket: (unsigned char *)packet  {
    
    [BTUtils dumpPacket:packet];
    
    if(self.delegate == nil)
        return;
    
    switch (self.currentProtocolName) {
            
        //###################################################
        //#############   SMARTONE ***** 8**  *** BEGIN
        //###################################################
        case SMARTONE_PROTOCOL_03:
        {
            int byeUsed = packet[PACKET_BYTE_POS];
            unsigned char curId01 = packet[1];
            
            switch(curId01)
            {
                case Cod_TEST_RESULTS:
                    
                    NSLog(@"CODE TEST RESULT");
                    
                    //###################################################
                    //#############   DATA CHANGED FOR CONFIDENTIAL PURPOSE
                    //###################################################
                    
                    [self.delegate testEndedWith:packet[1] <<8 | packet[2]
                                        pefValue:packet[3] <<8 | packet[4]
                                       fev1Value:packet[5] <<8 | packet[7]
                                  extVolumeValue:packet[8] <<8 | packet[9]
                                  timeToPefValue:packet[10]<<8 | packet[11]];
                    
                    break;
                case Cod_TARGET:
                case Cod_TEST:
                    
                    for(int start = 5; start < 17 && (start < byeUsed + 5); start += 2) {
                        
                        int value = packet[start]<<8 | packet[start+1];
                        [self.delegate flowValueUpdated:value];
                        
                    }
                    
                    break;
                    
                case Cod_ESC:
                    
                    [self.delegate deviceSentCodeEsc];
                    
                    break;
                    
                default:
                    NSLog(@"Data code not found") ;
                    break;
                    
            }
        }
        break;
        //###################################################
        //#############   SMARTONE_ *********** END <-----------!
        //###################################################
        default:
            
            NSLog(@"PARSER: Unsupported protocol name");
            break;
    }
    
    
    

}

@end
