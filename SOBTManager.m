//
//  SOBTManager.m
//  SmartOneKit-Playground
//
//  Created by Tereshkin Sergey on 01/10/15.
//

#import "SOBTManager.h"
#import "SOUtils.h"

#define SO_MIN_CONNECTION_INTERVAL 10

@interface SOBTManager ()

@property (nonatomic, strong) CBCentralManager *mCBCentralManager;
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
@property (nonatomic, strong) NSMutableDictionary *characteristicsCheckList;

@end

@implementation SOBTManager

#pragma mark SOBTManagerInterface
//###################################################
//#############     SOBTManagerInterface
//###################################################

- (instancetype)initWithDelegate:(id) delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

-(void)initCentralManager{
    
    if(!self.mCBCentralManager){
        [self setMCBCentralManager:[[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil]];
    }

}

-(void)startScan{
    
//    [SODeviceManager sharedManager] la
    
    [self.mCBCentralManager stopScan];
    [self.mCBCentralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:CUSTOM_SERVICE]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    
}


-(void)stopScan{
    
    [self.mCBCentralManager stopScan];
    
}

-(void)connectoToPeripheral:(NSString *)deviceId{
    
    CBPeripheral *peripheral = [self retrievePeripheralWithUUIDString:deviceId];
    
    if(peripheral){     // == if  peripheral != nil
        [self connect:peripheral];
    }
    
}

- (void)connect:(CBPeripheral *)peripheral {
    
    @try{

        [self setConnectedPeripheral:peripheral];
        [self.mCBCentralManager connectPeripheral:peripheral options:nil];
        
    }
    @catch (NSException *exception) {
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"Exception raised during device connection");
    }
    
}

-(void)disconnect{
    
    @try {

        if (self.connectedPeripheral)
            [self.mCBCentralManager cancelPeripheralConnection:self.connectedPeripheral];
        [self setCharacteristicsCheckList:nil];
        
    }
    @catch (NSException *exception) {
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"Exception raised during device disconnection");
    }

}

-(void)sendCommand:(Byte)byte{
    
    if(self.connectedPeripheral){
        
        if(byte == Cod_TEST){
            
            unsigned char packet[] = PACKET_TEST;
            
            [SOUtils dumpPacket:packet];
            
            NSData *nspacket = [NSData dataWithBytes:packet length:sizeof(packet)];
            
            [self.connectedPeripheral writeValue:nspacket forCharacteristic:self.outDataCharacteristic type:CBCharacteristicWriteWithResponse];
            
        }else if(byte == Cod_ESC){
            
            unsigned char packet[] = EMPTY_PACKET;
            packet[1] = byte;
            packet[CHECKSUM_POS] = [SOUtils calculateCheckSum:packet withLength:18];
            
            [SOUtils dumpPacket:packet];
            
            NSData *nspacket = [NSData dataWithBytes:packet length:sizeof(packet)];
            
            [self.connectedPeripheral writeValue:nspacket forCharacteristic:self.outDataCharacteristic type:CBCharacteristicWriteWithResponse];
            
        }else{
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"Uknown command");
        }
        
    }
    
}

-(void)clear{
    
    [self setConnectedPeripheral:nil];
    
    @try {
        
        self.inDataCharacteristic           = nil;
        self.outDataCharacteristic          = nil;
        self.batteryCharacteristic          = nil;
        self.statusCharacteristic           = nil;
        self.protocolNameCharacteristic     = nil;
        self.volumeStepCharacteristic       = nil;
        self.softwareReviewCharacteristic   = nil;
        
    }
    @catch (NSException *exception) {
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"Exception raised during cleaning characteriscics %@", [exception description]);
    }

    
}

#pragma mark CBCentralManagerDelegate

//###################################################
//#############     CBCentralManagerDelegate
//###################################################

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"CENTRAL centralManagerDidUpdateState");
    
    [self setCurrentCBCentralManagerState:central.state];
    
    if([self.delegate respondsToSelector:@selector(btManager:centralManagerDidUpdateState:)])
       [self.delegate btManager:self centralManagerDidUpdateState:central];
    
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"CENTRAL didDiscoverPeripheral withname: %@", peripheral.name);
    
    if([peripheral.name hasPrefix:DEVICE_PREFIX])
    if([self.delegate respondsToSelector:@selector(btManager:didDiscoverPeripheral:advertisementData:RSSI:)])
        [self.delegate btManager:self didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"CENTRAL didConnectPeripheral");
    
    [self setCharacteristicsCheckList:[[NSMutableDictionary alloc]init]];
    
    
    if([self.delegate respondsToSelector:@selector(btManager:didConnectPeripheral:)])
        [self.delegate btManager:self didConnectPeripheral:peripheral];

    [self setConnectedPeripheral:peripheral];
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"CENTRAL didDisconnectPeripheral");
    
    if([self.delegate respondsToSelector:@selector(btManager:didDisconnectPeripheral:)])
        [self.delegate btManager:self didDisconnectPeripheral:peripheral];
    
    [self clear];
    
}


#pragma mark CBPeripheralDelegate

//###################################################
//#############             CBPeripheralDelegate
//###################################################

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"PERIPHERAL didDiscoverServices");
    
    // MARCO_01 ***************************************************************************************
    //get the total number of available services exposed by the peripheral
//    self.numberOfAvailableServices = peripheral.services.count;
    // MARCO_01 ***************************************************************************************
    
    for (CBService *service in peripheral.services) {
        
        if([service.UUID isEqual:[CBUUID UUIDWithString:CUSTOM_SERVICE]])
        {
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"FOUND SERVICE CUSTOM_SERVICE");
            [peripheral discoverCharacteristics:nil forService:service];
            
        }
        else if([service.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_SERVICE]])
        {
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"FOUND SERVICE UUID_BATTERY_SERVICE");
            [peripheral discoverCharacteristics:nil forService:service];
        }
        else if([service.UUID isEqual:[CBUUID UUIDWithString:UUID_DEVICE_INFO_SERVICE]])
        {
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"FOUND SERVICE UUID_DEVICE_INFO_SERVICE");
            [peripheral discoverCharacteristics:nil forService:service];
        }
        else
        {
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"FOUND UNKNOWN SERVICE %@", service.UUID);
            [peripheral discoverCharacteristics:nil forService:service];
        }
        
    }
    
}


-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"PERIPHERAL didDiscoverCharacteristicsForService");

//    self.numberOfDiscoveredServices += 1; //count the discovered services for which have been discovered the characteristics
    
    for(CBCharacteristic *characteristic in service.characteristics)
    {
        
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:IN_DATA]])
        {
            self.inDataCharacteristic = characteristic;
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"inDataCharacteristic %@", characteristic);
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:OUT_DATA]])
        {
            self.outDataCharacteristic = characteristic;
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"outDataCharacteristic %@", characteristic);
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:DEVICE_STATUS]])
        {
            self.statusCharacteristic = characteristic;
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"statusCharacteristic %@", characteristic);
            
            //save device status to nsdefaults
            [[NSUserDefaults standardUserDefaults] setInteger:[self intFromDataReverseOnlyLastByte:characteristic.value] forKey:CURRENT_DEVICE_STATUS];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_CHARACTERISTIC]])
        {
            self.batteryCharacteristic = characteristic;
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"batteryCharacteristic %@", characteristic);
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PROTOCOL_NAME]])
        {
            self.protocolNameCharacteristic = characteristic;
            
        }
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:VOLUME_STEP]])
        {
            self.volumeStepCharacteristic = characteristic;
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"volumeStepCharacteristic %@", characteristic);
            
        }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SOFTWARE_REVIEW]]){
            
            self.softwareReviewCharacteristic = characteristic;
            
            NSString *strVersion = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding];
            
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"softwareReviewCharacteristic %@ version str: %@", characteristic, strVersion);
            
        }
        
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:IN_DATA]]                        ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:VOLUME_STEP]]                    ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:OUT_DATA]]                       ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:DEVICE_STATUS]]                  ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_CHARACTERISTIC]]    ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:PROTOCOL_NAME]]                  ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:SOFTWARE_REVIEW]]                ||
           [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CSR_VERSION]])
        {
            [peripheral readValueForCharacteristic:characteristic];
        }
        
    }
    
    
    // MARCO_01 ***************************************************************************************
    
    //call the method to notify that the characteristics for the current service have been discovered
    if([self.delegate respondsToSelector:@selector(btManager:didDiscoverCharacteristicsForService:)])
        [self.delegate btManager:self didDiscoverCharacteristicsForService:service];
    
    // MARCO_01 ***************************************************************************************
    
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
     if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"PERIPHERAL didUpdateValueForCharacteristic");
    
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:IN_DATA]])
    {
        
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:IN_DATA];
        
        unsigned char *packet = (unsigned char*)[[characteristic value] bytes];
        
        if([self.delegate respondsToSelector:@selector(btManager:didRecieveInputData:)])
           [self.delegate btManager:self didRecieveInputData:packet];
        
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:OUT_DATA]])
    {
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:OUT_DATA];
        
//        self.outDataCharacteristic = characteristic;
        
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"outDataCharacteristic %@", characteristic);
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:DEVICE_STATUS]])
    {
        
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:DEVICE_STATUS];
        
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"statusCharacteristic %@", characteristic);
        
        [[NSUserDefaults standardUserDefaults] setInteger:[self intFromDataReverseOnlyLastByte:characteristic.value] forKey:CURRENT_DEVICE_STATUS];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if([self.delegate respondsToSelector:@selector(btManager:didUpdateValueForCharacteristic:)])
           [self.delegate btManager:self didUpdateValueForCharacteristic:characteristic];
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BATTERY_CHARACTERISTIC]])
    {
        
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:UUID_BATTERY_CHARACTERISTIC];
        
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"batteryCharacteristic %@", characteristic);
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"BATTERY LEVEL: %i", [self intFromData:self.batteryCharacteristic.value]);
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PROTOCOL_NAME]])
    {
        
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:PROTOCOL_NAME];
        
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"protocolNameCharacteristic %i", [self intFromData:self.protocolNameCharacteristic.value]);
        
        if([self intFromData:self.protocolNameCharacteristic.value] != SMARTONE_PROTOCOL_04) {
            
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"Wrong PROTOCOL_NAME %@", characteristic);
            
        }else{
            
            if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"DEVICE With requested PROTOCOL_NAME connected %@", characteristic);
            
        }
        
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:VOLUME_STEP]])
    {
        self.volumeStepCharacteristic = characteristic;
        
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:VOLUME_STEP];
        
        [[NSUserDefaults standardUserDefaults]setInteger:[self intFromData:characteristic.value] forKey:@"currentStepValue"];
        
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"volumeStepCharacteristic %@", characteristic);
        
    }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_CSR_VERSION]]){
        
        self.csrCharacteristic = characteristic;
        
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:UUID_CSR_VERSION];
        
        NSString *strVersion = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding];
        
        [[NSUserDefaults standardUserDefaults] setValue:strVersion forKey:@"csr_version_preference"];
        
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"UUID_CSR_VERSION %@", strVersion);
        
    }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SOFTWARE_REVIEW]]){
        
        self.softwareReviewCharacteristic = characteristic;
        
        if(self.characteristicsCheckList)
            [self.characteristicsCheckList setValue:[NSNumber numberWithBool:YES] forKey:SOFTWARE_REVIEW];
        
        NSString *strVersion = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding];
        
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"softwareReviewCharacteristic %@ version str: %@", characteristic, strVersion);
        
    }
    

    if(self.characteristicsCheckList)
    if([[self.characteristicsCheckList valueForKey:UUID_CSR_VERSION] boolValue] &&
       [[self.characteristicsCheckList valueForKey:VOLUME_STEP] boolValue] &&
       [[self.characteristicsCheckList valueForKey:UUID_BATTERY_CHARACTERISTIC] boolValue] &&
       [[self.characteristicsCheckList valueForKey:DEVICE_STATUS] boolValue] &&
       [[self.characteristicsCheckList valueForKey:IN_DATA] boolValue] &&
       [[self.characteristicsCheckList valueForKey:SOFTWARE_REVIEW] boolValue] &&
       [[self.characteristicsCheckList valueForKey:OUT_DATA] boolValue])
    {
        [self setCharacteristicsCheckList:nil];
        
        if([self.delegate respondsToSelector:@selector(btManager:didDiscoverAllCharacteristicsForAllServices:)]){
            [self.delegate btManager:self didDiscoverAllCharacteristicsForAllServices:peripheral];
        }
        
    }

    
}

-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    
    NSLog(@"%@ updated RSSI %i",peripheral.name, [peripheral.RSSI intValue]);
    
}

#pragma mark Utils

//###################################################
//#############             Utils
//###################################################

- (CBPeripheral *) retrievePeripheralWithUUIDString:(NSString *)UUIDString
{
    
    NSUUID *UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
    
    CBPeripheral *peripheral;
    
    if (!self.mCBCentralManager) {
        NSLog(@"SmartOneKit - WARNING: The method lastConnectedDeviceInfo cannot be called before using the initBluetooth method");
        return nil;
    }
    
    NSArray *array = [self.mCBCentralManager retrievePeripheralsWithIdentifiers:@[UUID]];
    
    if ([array count] > 0) {
        // Found device
        if ([[SODeviceManager sharedManager] isLogEnabled]) NSLog(@"Found device with requested UUID");
        peripheral = [array objectAtIndex:0];
    }
    
    return peripheral;
}

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
