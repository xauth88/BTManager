//
//  SOCommManager.m
//  SmartOneKit-Playground
//
//  Created by Tereshkin Sergey on 01/10/15.
//

#import "SODeviceManager.h"
#import "SOBTManager.h"
#import "SOParser.h"
#import "SOUtils.h"

#define DELEGATES_MAX_NUMBER 7

#define CBPeripheralKey             @"CBPeripheralKey"
#define SODeviceInfoKey             @"SODeviceInfoKey"
#define lastConnectedDeviceIDKey    @"lastConnectedDeviceIDKey"

@interface SODeviceManager () <SOBTManagerDelegate>

@property (nonatomic, strong) SOBTManager *btManager;
@property (nonatomic, strong) SODevice *currentDevice;
@property (nonatomic, strong) SOParser *parser;
@property (nonatomic, strong) NSMutableArray *delegates;

@property (nonatomic, strong) NSString *lastConnectedDeviceID;

@property (nonatomic) BOOL isConnected;
@property (nonatomic) BOOL isLogEn;

@end

SODeviceManager *sharedManager;


@implementation SODeviceManager

#pragma mark Initalization

+ (instancetype) sharedManager
{
    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [[SODeviceManager alloc]init];
            sharedManager.delegates = [[NSMutableArray alloc]initWithArray:@[]];
            sharedManager.discoveredPeripherals = [[NSMutableDictionary alloc]initWithDictionary:@{}];
            sharedManager.connectionTimeoutInSeconds = [NSNumber numberWithDouble:20];
            sharedManager.btManager = [[SOBTManager alloc]initWithDelegate:sharedManager];
        }
    }
    return sharedManager;
}


#pragma mark - SODeviceManager interface methods
//###################################################
//#############     SODeviceManager
//###################################################

-(void)initBluetooth{
    [self.btManager initCentralManager];
}

-(CBCentralManagerState) bluetoothState{
    return [self.btManager currentCBCentralManagerState];
}

- (void) addDelegate:(id<SODeviceManagerDelegate>) delegate {
    
    if (![self.delegates containsObject:delegate]){
        if([self.delegates count] <= DELEGATES_MAX_NUMBER){
            [self.delegates addObject:delegate];
        }else{
            if (self.isLogEn) NSLog(@"SODeviceManager WARNING: Number of delegates for DeviceManager is limited to: [%i]. HINT: Use removeDelegate method to free space", DELEGATES_MAX_NUMBER);
        }
    }
    
}

- (void) removeDelegate:(id<SODeviceManagerDelegate>) delegate {
    
    if ([self.delegates containsObject:delegate])
        [self.delegates removeObject:delegate];
    
}

-(void)startDiscovery{
    
    [self setDiscoveredPeripherals:[[NSMutableDictionary alloc]initWithDictionary:@{}]];
    
    // ##############################
    if (self.connectedDevice) {
        
        CBPeripheral *peripheral = [self.btManager retrievePeripheralWithUUIDString:self.connectedDevice.deviceInfo.deviceID];
        
        NSDictionary *deviceItem = @{CBPeripheralKey:peripheral,
                                     SODeviceInfoKey:self.connectedDevice.deviceInfo};
        
        //if CBPeripheral exists it'll be overwritten
        [self.discoveredPeripherals setObject:deviceItem forKey:self.connectedDevice.deviceInfo.deviceID];
        
        for (id<SODeviceManagerDelegate> delegate in self.delegates)
            if ([delegate respondsToSelector:@selector(deviceManager:didDiscoverDeviceWithInfo:)])
                [delegate deviceManager:self didDiscoverDeviceWithInfo:self.connectedDevice.deviceInfo];
        
    }
    // ##############################
    
    [self.btManager startScan];
}

-(void)stopDiscovery{
    [self.btManager stopScan];
}

-(void)connect:(NSString *)deviceId{
    
    [self setIsConnected:NO];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self.btManager];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(verifyConnection) object:nil];
    
    NSDictionary *deviceItem = [self.discoveredPeripherals objectForKey:deviceId];
    CBPeripheral *peripheral = [deviceItem objectForKey:CBPeripheralKey];
    
    if(!peripheral){
        peripheral = [self.btManager retrievePeripheralWithUUIDString:deviceId];
    }
    
    [self disconnect];
    
    if ([self.lastConnectedDeviceID isEqualToString:deviceId]) {
        [self.btManager performSelector:@selector(connect:) withObject:peripheral afterDelay:3.0];
    }else{
        [self.btManager connect:peripheral];
    }
    
    [self setLastConnectedDeviceID:deviceId];
    
    [self performSelector:@selector(verifyConnection) withObject:nil afterDelay:[self.connectionTimeoutInSeconds doubleValue]];
    
}

-(void)disconnect{
    
    [self.btManager disconnect];
    
}

-(void)verifyConnection{
    
    if(![self isConnected]){
        [self disconnect];
        for (id<SODeviceManagerDelegate> delegate in self.delegates)
            if ([delegate respondsToSelector:@selector(deviceManager:didFailToConnectDeviceWithInfo:)])
                [delegate deviceManager:self didFailToConnectDeviceWithInfo:self.currentDevice.deviceInfo];
    }
    
}

-(SODeviceInfo *)lastConnectedDeviceInfo{
    
    SODeviceInfo *deviceInfo;
    NSString *lastConnectedDeviceID = [[NSUserDefaults standardUserDefaults] valueForKey:lastConnectedDeviceIDKey];
    
    if (lastConnectedDeviceID) {
        CBPeripheral *peripheral = [self.btManager retrievePeripheralWithUUIDString:lastConnectedDeviceID];
        if (peripheral) {
            deviceInfo = [SOUtils deviceInfoWithPeripheral:peripheral];
        }

    }
    
    return deviceInfo;
}

-(void) setLogEnabled:(BOOL)enabled{
    [self setIsLogEn:enabled];
}

-(BOOL) isLogEnabled{
    return self.isLogEn;
}

#pragma mark SOBTManagerDelegate
//###################################################
//#############     SOBTManagerDelegate
//###################################################

-(void)btManager:(SOBTManager *)btManager centralManagerDidUpdateState:(CBCentralManager *)central{
    
    if([central state] != CBCentralManagerStatePoweredOn){
        [self setConnectedDevice:nil];
    }
    
    for (id<SODeviceManagerDelegate> delegate in self.delegates)
        if ([delegate respondsToSelector:@selector(deviceManager:didUpdateBluetoothWithState:)])
            [delegate deviceManager:self didUpdateBluetoothWithState:[central state]];
    
}

-(void)btManager:(SOBTManager *)btManager didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    // the following check is needed because of a bad bug of Core BT that discovers each device twice
    // right after having swithced off and on the bluetooth
    if(![self.discoveredPeripherals objectForKey:[peripheral.identifier UUIDString]]){
        
        SODeviceInfo *deviceInfo = [SOUtils deviceInfoWithPeripheral:peripheral];
        
        [deviceInfo setRSSI:RSSI];
        
        NSDictionary *deviceItem = @{CBPeripheralKey:peripheral,
                                     SODeviceInfoKey:deviceInfo};
        
        //if CBPeripheral exists it'll be overwritten
        [self.discoveredPeripherals setObject:deviceItem forKey:deviceInfo.deviceID];
        
        for (id<SODeviceManagerDelegate> delegate in self.delegates)
            if ([delegate respondsToSelector:@selector(deviceManager:didDiscoverDeviceWithInfo:)])
                [delegate deviceManager:self didDiscoverDeviceWithInfo:deviceInfo];
    }
    
}

-(void)btManager:(SOBTManager *)btManager didConnectPeripheral:(CBPeripheral *)peripheral{

    SODevice *device = [[SODevice alloc]initWithID:self.btManager];
    [device setDeviceInfo:[SOUtils deviceInfoWithPeripheral:peripheral]];
    
    [self setCurrentDevice:device];
    
    //MARCO_03 .....
    self.parser = [[SOParser alloc]initWithProtocolName:SMARTONE_PROTOCOL_04 andDelegate:self.currentDevice];
    // .............
    
}

-(void)btManager:(SOBTManager *)btManager didDisconnectPeripheral:(CBPeripheral *)peripheral{

    [self setConnectedDevice:nil];
    
    for (id<SODeviceManagerDelegate> delegate in self.delegates)
        if ([delegate respondsToSelector:@selector(deviceManager:didDisconnectDevice:)])
            [delegate deviceManager:self didDisconnectDevice:self.currentDevice];
    
}

-(void)btManager:(SOBTManager *)btManager didRecieveInputData:(unsigned char *)package{
    
    if (self.isLogEn) NSLog(@"didRecieveInputData");
    
    [self.parser handlePacket:package];
    
}

-(void)btManager:(SOBTManager *)btManager didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic{
    
    if([characteristic isEqual:self.btManager.statusCharacteristic]){
        [self.parser deliverDeviceLastCommandStatus:[SOUtils deviceStatusFor:DEVICE_LAST_COMMAND]];
    }
    
}

-(void)btManager:(SOBTManager *)btManager didDiscoverCharacteristicsForService:(CBService *)service {
    
}

-(void)btManager:(SOBTManager *)btManager didDiscoverAllCharacteristicsForAllServices:(CBPeripheral *)peripheral {
    
    //MARCO_02 .......................................................................................
    // At this point the device is connected and all the characteristics...
    //... (for all the available service of the connected peripheral)....
    //... have been read
    
    [self setIsConnected:YES];
    [self setConnectedDevice:self.currentDevice];
    
    [[NSUserDefaults standardUserDefaults] setValue:self.currentDevice.deviceInfo.deviceID forKey:lastConnectedDeviceIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //get the device attributes coming from the characteristics
    [self.currentDevice setBatteryLevel:[SOUtils intFromData:btManager.batteryCharacteristic.value]];
    [self.currentDevice setVolumeStep:[SOUtils intFromData:btManager.volumeStepCharacteristic.value]];
    
    NSString *softwareVersion = [[NSString alloc] initWithData:btManager.softwareReviewCharacteristic.value encoding:NSASCIIStringEncoding];
    NSString *csrVersion = [[NSString alloc] initWithData:btManager.csrCharacteristic.value encoding:NSASCIIStringEncoding];
    
    [self.currentDevice setSoftwareVersion:softwareVersion];
    [self.currentDevice setBluetoothVersion:csrVersion];
    
    for (id<SODeviceManagerDelegate> delegate in self.delegates)
        if ([delegate respondsToSelector:@selector(deviceManager:didConnectDevice:)])
            [delegate deviceManager:self didConnectDevice:self.currentDevice];
    
    //................................................................................................
    
}



@end
