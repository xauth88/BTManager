//
//  DeviceController.m
//  BLEComm
//
//  Created by Tereshkin Sergey on 06/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "DeviceController.h"
#import "Parser.h"
#import "BTUtils.h"
#import "Defs.h"

@interface DeviceController () <BTManagerDelegate, ParserDelegate>

@property (nonatomic, strong) BTManager *mBTmanager;

@end

static DeviceController *sharedDeviceController;

@implementation DeviceController

#pragma mark Initalization

+ (instancetype) sharedDeviceController
{
    @synchronized(self) {
        if (!sharedDeviceController) {
            sharedDeviceController = [[DeviceController alloc] init];
        }
    }
    return sharedDeviceController;
}


- (void) scanAndConnectWithDelegate:(id) delegate
{
    [self setDelegate:delegate];
    
    self.mBTmanager = [[BTManager alloc]initWithDelegate:self];
    [self.mBTmanager scanAndConnect];
}

- (void) sendCommand:(Byte) byte
{
    if([BTUtils deviceStatusFor:IS_DEVICE_READY])
    {
        [self.mBTmanager sendCommand:byte];
    }

}

- (void) connectTo:(CBPeripheral *)peripheral
{
    [self.mBTmanager connectToDiscoveredPeripheral:peripheral];
}

- (void) disconnect
{
    [self.mBTmanager disconnectConnectedDevice];
}

- (NSArray *) getPeripheralsList
{
    return [self.mBTmanager discoveredPeripherals];
}
//###################################################
//#############   ParserDelegate
//###################################################
#pragma mark ParserDelegate

- (void) flowValueUpdated:(int)value
{
    [self.delegate flowValueUpdated:value];
    NSLog(@"FlowValueUpdate: %i", value);
}

- (void) testEndedWith:(int)quality pefValue:(int)pef fev1Value:(int)fev1 extVolumeValue:(int)extVolume timeToPefValue:(int)timeToPef
{
    [self.delegate testEndedWith:quality pefValue:pef fev1Value:fev1 extVolumeValue:extVolume timeToPefValue:timeToPef];
    
    NSLog(@"PEF: %i",           pef);
    NSLog(@"FEV1: %i",          fev1);
    NSLog(@"VEXT: %i",          extVolume);
    NSLog(@"TIME_TO_PEF: %i",   timeToPef);
}
-(void)deviceSentCodeEsc
{
    [self.delegate deviceSentCodeEsc];
    NSLog(@"DEVICE deviceSentCodeEsc");
}

//###################################################
//#############   BTManagerDelegate
//###################################################
#pragma mark BTManagerDelegate

-(void)deviceDisconnected
{
    [self.delegate deviceDisconnected];
    NSLog(@"DeviceController deviceDisconnected");
}

- (void) deviceWithRequestedProtocolNameConnected
{
    [self.delegate deviceWithRequestedProtocolNameConnected];
    NSLog(@"DeviceController deviceWithRequestedProtocolNameConnected");
}

- (void) scanIsStoppedByTomeout
{
    [self.delegate scanIsStoppedByTomeout];
    NSLog(@"DeviceController scanIsStoppedByTomeout");
}

- (void) bluetoothIsPoweredOff
{
    [self.delegate bluetoothIsPoweredOff];
    NSLog(@"DeviceController bluetoothIsPoweredOff ");
}

@end
