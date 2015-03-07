//
//  BLEManager.m
//  BLEComm
//
//  Created by Tereshkin Sergey on 03/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "BTManager.h"
#import "BTUtils.h"
#import "Defs.h"
#import "Parser.h"

#define LAST_DEVICE_UUID_KEY @"lastDeviceUUIDString"

@interface BTManager () <CBCentralManagerDelegate, CBPeripheralDelegate>


@property (nonatomic, strong) CBCentralManager *mCBCentralManager;

// peripheral section
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong) CBPeripheral *tempPeripheral;
@property (nonatomic, strong) NSMutableArray *discardedPeripherals;

// characteristics section
@property (nonatomic, strong) CBCharacteristic *inDataCharacteristic;
@property (nonatomic, strong) CBCharacteristic *outDataCharacteristic;
@property (nonatomic, strong) CBCharacteristic *battaryCharacteristic;
@property (nonatomic, strong) CBCharacteristic *statusCharacteristic;
@property (nonatomic, strong) CBCharacteristic *protocolNameCharacteristic;
@property (nonatomic, strong) CBCharacteristic *volumeStepCharacteristic;

@property (nonatomic, strong) Parser *mParser;

// helpers
@property (nonatomic) BOOL directConnectOk;
@property (nonatomic) BOOL isScanToRestart;
@property (nonatomic) BOOL shouldStopScan;

@end

//if the instance of BLEManager already exists the reference to it passed, otherwise a brand new istance is made and passed

//static BTManager *sharedBTManager;

@implementation BTManager

#pragma mark Initalization

- (instancetype)initWithDelegate:(id) delegate
{
    self = [super init];
    if (self) {
        [self setDelegate:delegate];
        [self setMParser:[[Parser alloc]initWithProtocolName:SMARTONE_PROTOCOL_03 andDelegate:delegate]];
    }
    return self;
}

#pragma mark BTManager Controll Surface

//###################################################
//#############   BTManager Controll Surface
//###################################################

- (void) scanAndConnect
{
    self.connectedPeripheral = nil;
    self.discoveredPeripherals = [[NSMutableArray alloc]init];
    self.discardedPeripherals = [[NSMutableArray alloc]init];
    
    self.mCBCentralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    
    [self performSelector:@selector(stopScan) withObject:nil afterDelay:30.0f];
    
}

- (void) sendCommand:(Byte) byte
{
    if(self.connectedPeripheral)
    {
        
        unsigned char packet[] = EMPTY_PACKET;
        packet[1] = byte;
        packet[0] = packet[2] = packet[3] = packet[4] = 0x01;
        packet[CHECKSUM_POS] = [BTUtils calculateCheckSum:packet withLength:18];
        
        [BTUtils dumpPacket:packet];
        
        NSData *nspacket = [NSData dataWithBytes:packet length:sizeof(packet)];
        
        [self.connectedPeripheral writeValue:nspacket forCharacteristic:self.outDataCharacteristic type:CBCharacteristicWriteWithResponse];
        
    }
}

- (void) connectToDiscoveredPeripheral:(CBPeripheral *)peripheral
{
    
    @try {

        if(self.connectedPeripheral == nil){
            [self setConnectedPeripheral:peripheral]; // self.connectedPeripheral = peripheral
            [self setTempPeripheral:nil];
            [self.mCBCentralManager connectPeripheral:self.connectedPeripheral options:nil];
        }else{
            [self setTempPeripheral:peripheral];
            [self disconnectConnectedDevice];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception raised during device connection with NSException description: %@", [exception description]);
    }

}

- (BOOL) directConnectToDeviceWithUUIDString:(NSString *)UUIDString
{
    NSLog(@"directConnectToDeviceWithUUIDString: %@", UUIDString);
    self.connectedPeripheral = nil;
    
    NSUUID *UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
    
    if (!UUID) {
        // L'UUID nt valid
        NSLog(@"Device UUID seems not valid");
    }
    
    NSArray *array = [self.mCBCentralManager retrievePeripheralsWithIdentifiers:@[UUID]];
    
    if ([array count] > 0) {
        // Found device
        NSLog(@"Found device with requested UUID");
        self.tempPeripheral = [array objectAtIndex:0];
        
        [self connectToDiscoveredPeripheral:self.tempPeripheral];
        
        return YES;
        
    } else {
        // Didn't found the device
        NSLog(@"Didn't found device with requested UUID");
        
    }
    return NO;
}

- (void)disconnectConnectedDevice
{
    @try {
        NSLog(@"Disconnecting from peripheral %@", self.connectedPeripheral);
        [self.mCBCentralManager cancelPeripheralConnection:self.connectedPeripheral];
        self.connectedPeripheral = nil;
        
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:LAST_DEVICE_UUID_KEY];
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"lasConnectedDeviceName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception raised during device disconnection");
    }
    
}

- (void) stopScan
{
    [self.mCBCentralManager stopScan];
    
    // Notify delegate (time out is over)
    if(!self.connectedPeripheral)
       [self.delegate scanIsStoppedByTomeout];
}

- (void) restartScan
{
    self.isScanToRestart = NO;
    self.mCBCentralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
}

- (void) isDirectConnectSucceeded
{
    if(!self.directConnectOk)
    {
        NSLog(@"DIRECT CONNECT did failed");
        
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:LAST_DEVICE_UUID_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.connectedPeripheral = nil;
        [self restartScan];
    }
    else
    {
        NSLog(@"DIRECT CONNECT directConnectOk");
    }
    
}

#pragma mark CBCentralManagerDelegate

//###################################################
//#############       CBCentralManagerDelegate
//###################################################

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"central manager did update state");
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@"OK CBCentralManagerStatePoweredOn started scan for custom service: %@ ", CUSTOM_SERVICE);
            
            
            NSString *lastConnectedDeviceUUID = [[NSUserDefaults standardUserDefaults] valueForKey:LAST_DEVICE_UUID_KEY];
            
            if (lastConnectedDeviceUUID.length > 0 && [self directConnectToDeviceWithUUIDString:lastConnectedDeviceUUID])
            {
                 NSLog(@"trying to retrieve periphral whit uuid: %@", lastConnectedDeviceUUID);
                [self performSelector:@selector(isDirectConnectSucceeded) withObject:nil afterDelay:10.0f];
                
            }
            else
            {
                [self.mCBCentralManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:CUSTOM_SERVICE] ] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
            }
            
            
        }
            break;
            
        case CBCentralManagerStatePoweredOff:
            // ble is switched off
            NSLog(@"WARNING CBCentralManagerStatePoweredOff");
            
            [self.delegate bluetoothIsPoweredOff];
            
            break;
            
        case CBCentralManagerStateUnsupported:
            NSLog(@"WARNING CBCentralManagerStateUnsupported");
            
            [self.delegate bluetoothIsPoweredOff];
            
            break;
            
        case CBCentralManagerStateUnauthorized:
            NSLog(@"WARNING CBCentralManagerStateUnauthorized");
            break;
            
        case CBCentralManagerStateUnknown:
            NSLog(@"WARNING CBCentralManagerStateUnknown");
            break;
            
        case CBCentralManagerStateResetting:
            NSLog(@"WARNING CBCentralManagerStateResetting");
            break;
            
        default:
            NSLog(@"WARNING default case");
            break;
    }
    
   
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Adv data, %@ \n%i", advertisementData, [RSSI intValue]);
    
    @try {
        
        if(![self.discoveredPeripherals containsObject:peripheral]
           && ![self.discardedPeripherals containsObject:peripheral])
            [self.discoveredPeripherals addObject:peripheral];

        
        if(![self.discardedPeripherals containsObject:peripheral])
            [self connectToDiscoveredPeripheral:peripheral];
        
        
    }
    @catch (NSException *exception) { }
    
//    NSLog(@"peripherals count: %lo", (unsigned long)[self.discoveredPeripherals count]);
    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{

    [self.connectedPeripheral setDelegate:self];
    [self.connectedPeripheral discoverServices:nil];
    
    self.tempPeripheral = nil;
    
    NSLog(@"CENTRAL didConnectPeripheral with name: %@", peripheral.name);
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{

    if(self.isScanToRestart)
        [self restartScan];
    
    self.inDataCharacteristic = nil;
    self.outDataCharacteristic = nil;
    self.battaryCharacteristic = nil;
    self.statusCharacteristic = nil;
    self.protocolNameCharacteristic = nil;
    self.volumeStepCharacteristic = nil;
    
    if(self.tempPeripheral != nil)
    {
        [self performSelector:@selector(connectToDiscoveredPeripheral:) withObject:self.tempPeripheral afterDelay:2.0f];
//        [self connectToDiscoveredPeripheral:self.tempPeripheral];
    }
    else
    {
        [self.delegate deviceDisconnected];
    }
    
    NSLog(@"CENTRAL didDisconnectPeripheral");
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"CENTRAL didFailToConnectPeripheral");
}

-(void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"! CENTRAL didRetrievePeripherals");
}

#pragma mark CBPeripheralDelegate

//###################################################
//#############        CBPeripheralDelegate
//###################################################

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"PERIPHERAL didDiscoverServices");
    
    for (CBService *service in peripheral.services) {
        
        if([service.UUID isEqual:[CBUUID UUIDWithString:CUSTOM_SERVICE]])
        {
            NSLog(@"FOUND SERVICE CUSTOM_SERVICE");
            [self.connectedPeripheral discoverCharacteristics:nil forService:service];
            
        }
        else if([service.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_SERVICE]])
        {
            NSLog(@"FOUND SERVICE UUID_BATTERY_SERVICE");
            [self.connectedPeripheral discoverCharacteristics:nil forService:service];
        }
        else if([service.UUID isEqual:[CBUUID UUIDWithString:UUID_DEVICE_INFO_SERVICE]])
        {
            NSLog(@"FOUND SERVICE UUID_DEVICE_INFO_SERVICE");
            [self.connectedPeripheral discoverCharacteristics:nil forService:service];
        }
        else
        {
            NSLog(@"FOUND UNKNOWN SERVICE %@", service.UUID);
        }
        
    }


}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"PERIPHERAL didDiscoverCharacteristicsForService");
    
    for(CBCharacteristic *characteristic in service.characteristics)
    {
        
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:IN_DATA]])
        {
            self.inDataCharacteristic = characteristic;
            NSLog(@"inDataCharacteristic %@", characteristic);
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:OUT_DATA]])
        {
            self.outDataCharacteristic = characteristic;
            NSLog(@"outDataCharacteristic %@", characteristic);
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:DEVICE_STATUS]])
        {
            self.statusCharacteristic = characteristic;
            NSLog(@"statusCharacteristic %@", characteristic);
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_CHARACTERISTIC]])
        {
            self.battaryCharacteristic = characteristic;
            NSLog(@"battaryCharacteristic %@", characteristic);
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PROTOCOL_NAME]])
        {
            self.protocolNameCharacteristic = characteristic;
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:VOLUME_STEP]])
        {
            self.volumeStepCharacteristic = characteristic;
            NSLog(@"volumeStepCharacteristic %@", characteristic);
        }
        
        [self.connectedPeripheral setNotifyValue:YES forCharacteristic:characteristic];
        
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:IN_DATA]]                        ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:VOLUME_STEP]]                    ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:OUT_DATA]]                       ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:DEVICE_STATUS]]                  ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_CHARACTERISTIC]]    ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:PROTOCOL_NAME]])
        {
            [peripheral readValueForCharacteristic:characteristic];
        }
    
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:IN_DATA]])
    {
    
        unsigned char *packet = (unsigned char*)[[characteristic value] bytes];
        
        [self.mParser handlePacket:packet];
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:OUT_DATA]])
    {
        
         NSLog(@"outDataCharacteristic %@", characteristic);
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:DEVICE_STATUS]])
    {
        
         NSLog(@"statusCharacteristic %@", characteristic);
        
        [[NSUserDefaults standardUserDefaults] setInteger:[self intFromDataReverseOnlyLastByte:characteristic.value] forKey:CURRENT_DEVICE_STATUS];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_CHARACTERISTIC]])
    {
        
         NSLog(@"battaryCharacteristic %@", characteristic);
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PROTOCOL_NAME]])
    {
        
        NSLog(@"protocolNameCharacteristic %i", [self intFromData:self.protocolNameCharacteristic.value]);
        
        if([self intFromData:self.protocolNameCharacteristic.value] != SMARTONE_PROTOCOL_03){
            NSLog(@"Wrong PROTOCOL_NAME %@", characteristic);
            
            @try {
                [self.discardedPeripherals addObject:self.connectedPeripheral];
                [self.discoveredPeripherals removeObject:self.connectedPeripheral];
            }
            @catch (NSException *exception) {
                
            }

            [self setIsScanToRestart:YES];
            [self disconnectConnectedDevice];
            
        }else{
            NSLog(@"DEVICE With requested PROTOCOL_NAME connected %@", characteristic);
            
            [[NSUserDefaults standardUserDefaults] setValue:[self.connectedPeripheral.identifier UUIDString] forKey:LAST_DEVICE_UUID_KEY];
            [[NSUserDefaults standardUserDefaults] setValue:self.connectedPeripheral.name forKey:@"lasConnectedDeviceName"];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // Notify delegate that device is connected
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate deviceWithRequestedProtocolNameConnected];
            });
            
            [self setDirectConnectOk:YES];
            [self stopScan];
        }
        
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:VOLUME_STEP]])
    {
        self.volumeStepCharacteristic = characteristic;

        [[NSUserDefaults standardUserDefaults]setInteger:[self intFromData:characteristic.value] forKey:@"currentStepValue"];
        
        NSLog(@"volumeStepCharacteristic %@", characteristic);
    }
    
    NSLog(@"PERIPHERAL didUpdateValueForCharacteristic");
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"PERIPHERAL didWriteValueForCharacteristic");
}


#pragma mark Utils

//###################################################
//#############             Utils
//###################################################
- (int)intFromDataReverseOnlyLastByte:(NSData *)longData
{
    NSData *data = [longData subdataWithRange:NSMakeRange(1, 1)];
    
    int intSize = sizeof(int);// change it to fixe length
    unsigned char * buffer = malloc(intSize * sizeof(unsigned char));
    [data getBytes:buffer length:intSize];
    int num = 0;
    for (int i = intSize - 1; i >= 0; i--) {
        num = (num << 8) + buffer[i];
    }
    free(buffer);
    return num;
}

- (int)intFromData:(NSData *)data
{
    const uint8_t *bytes = [data bytes];
    int value = bytes[0];
    
    return value;
}


@end
