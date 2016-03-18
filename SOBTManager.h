//
//  SOBTManager.h
//  SmartOneKit-Playground
//
//  Created by Tereshkin Sergey on 01/10/15.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "Defs.h"


@class SOBTManager;

@protocol SOBTManagerDelegate <NSObject>

#pragma CBCentralManager delegate
- (void) btManager:(SOBTManager *)btManager centralManagerDidUpdateState:(CBCentralManager *)central;
- (void) btManager:(SOBTManager *)btManager didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
- (void) btManager:(SOBTManager *)btManager didConnectPeripheral:(CBPeripheral *)peripheral;
- (void) btManager:(SOBTManager *)btManager didDisconnectPeripheral:(CBPeripheral *)peripheral;
- (void) btManager:(SOBTManager *)btManager didDiscoverCharacteristicsForService:(CBService *)service;
- (void) btManager:(SOBTManager *)btManager didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;
// MARCO_01
- (void) btManager:(SOBTManager *)btManager didDiscoverAllCharacteristicsForAllServices:(CBPeripheral *)peripheral;
// MARCO_01

#pragma CBPeripheral delegate
- (void) btManager:(SOBTManager *)btManager didRecieveInputData:(unsigned char *)package;

@end

@interface SOBTManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

//// ############# characteristics section #############
@property (nonatomic, strong) CBCharacteristic *inDataCharacteristic;
@property (nonatomic, strong) CBCharacteristic *outDataCharacteristic;
@property (nonatomic, strong) CBCharacteristic *batteryCharacteristic;
@property (nonatomic, strong) CBCharacteristic *statusCharacteristic;
@property (nonatomic, strong) CBCharacteristic *protocolNameCharacteristic;
@property (nonatomic, strong) CBCharacteristic *volumeStepCharacteristic;
@property (nonatomic, strong) CBCharacteristic *softwareReviewCharacteristic;
@property (nonatomic, strong) CBCharacteristic *csrCharacteristic;

@property (nonatomic) CBCentralManagerState currentCBCentralManagerState;

@property (nonatomic, strong) id<SOBTManagerDelegate> delegate;

- (instancetype)initWithDelegate:(id) delegate;
- (void)initCentralManager;

-(void)startScan;
-(void)stopScan;
-(void)connectoToPeripheral:(NSString *)deviceId;
-(void)connect:(CBPeripheral *)peripheral;
-(void)disconnect;
-(void)sendCommand:(Byte)byte;
-(CBPeripheral *)retrievePeripheralWithUUIDString:(NSString *)UUIDString;
    
@end
