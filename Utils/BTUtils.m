//
//  BTUtils.m
//  BLEComm
//
//  Created by Tereshkin Sergey on 06/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "BTUtils.h"
#import "Defs.h"

@implementation BTUtils

+ (char) calculateCheckSum: (unsigned char*) packet withLength: (int) length {
    
    int lastPos = length-1 ;
    unsigned long int sum = 0 ;
    for(int i=0; i<lastPos ; i++) {
        sum+= packet[i];
    }
    
    return (char)(sum&0xff);
    
}

+ (void) dumpPacket: ( unsigned char*) packet {
    
    for(int i=0; i<18; i++) {
        printf("%02x ", packet[i]);
    }
    printf("\n") ;
}

+ (NSString *) reverseString:(NSString *)str
{
    NSMutableString *reversedString = [NSMutableString string];
    NSInteger charIndex = [str length];
    while (charIndex > 0) {
        charIndex--;
        NSRange subStrRange = NSMakeRange(charIndex, 1);
        [reversedString appendString:[str substringWithRange:subStrRange]];
    }
    return reversedString;
    
}

+ (NSString *)intToBinary:(NSInteger)intValue
{
    int bytes = 2;
    int byteBlock = 8; // Bits per byte
    int totalBits = bytes * byteBlock; // Total bits
    int binaryDigit = totalBits; // Which digit are we processing
    
    // C array - storage plus one for null
    char ndigit[totalBits + 1];
    
    while (binaryDigit-- > 0) {
        // Set digit in array based on rightmost bit
        ndigit[binaryDigit] = (intValue & 1) ? '1' : '0';
        
        // Shift incoming value one to right
        intValue >>= 1;
    }
    
    // Append null
    ndigit[totalBits] = 0;
    
    // Return the binary string
    return [self reverseString:[NSString stringWithUTF8String:ndigit]];
}

+ (BOOL) deviceStatusFor:(int) request
{
    NSString *state = [self intToBinary:(int)[[NSUserDefaults standardUserDefaults] integerForKey:CURRENT_DEVICE_STATUS]];
    NSLog(@"CURRENT DEVICE STATUS: %@", state);
    
    switch(request)
    {
        case DEVICE_LAST_COMMAND:
            if([[state substringWithRange:NSMakeRange(6, 1)] isEqualToString:@"1"])
                return YES;
            break;
        case IS_DEVICE_READY:
            if([[state substringWithRange:NSMakeRange(7, 1)] isEqualToString:@"1"])
                return YES;
            break;
    }
    
    return NO;
    
}

@end
