//
//  DeviceController.h
//  BLEComm
//
//  Created by Tereshkin Sergey on 06/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTManager.h"

@protocol DeviceControllerDelegate <NSObject>

- (void) deviceWithRequestedProtocolNameConnected;
- (void) deviceDisconnected;
- (void) scanIsStoppedByTomeout;
- (void) bluetoothIsPoweredOff;
- (void) deviceSentCodeEsc;

- (void) flowValueUpdated:(int)value;
- (void) testEndedWith:(int)quality pefValue:(int)pef fev1Value:(int)fev1 extVolumeValue:(int)extVolume timeToPefValue:(int)timeToPef;

@end

@interface DeviceController : NSObject

@property (nonatomic, strong) id<DeviceControllerDelegate> delegate;

+ (instancetype)sharedDeviceController;
- (void) scanAndConnectWithDelegate:(id) delegate;
- (void) sendCommand:(Byte) byte;
- (void) disconnect;

- (NSArray *) getPeripheralsList;
- (void) connectTo:(CBPeripheral *)peripheral;



@end
