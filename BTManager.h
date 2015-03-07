//
//  BLEManager.h
//  BLEComm
//
//  Created by Tereshkin Sergey on 03/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@protocol BTManagerDelegate <NSObject>

- (void) deviceWithRequestedProtocolNameConnected;
- (void) deviceDisconnected;
- (void) scanIsStoppedByTomeout;
- (void) bluetoothIsPoweredOff;

@end

@interface BTManager : NSObject 

@property (nonatomic, strong) id<BTManagerDelegate> delegate;

- (instancetype) initWithDelegate:(id) delegate;
- (void) scanAndConnect;
- (void) sendCommand:(Byte) byte;
- (void) disconnectConnectedDevice;
- (void) connectToDiscoveredPeripheral:(CBPeripheral *)peripheral;

@property (nonatomic, strong) NSMutableArray *discoveredPeripherals;

@end
