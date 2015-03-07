//
//  AppDelegate.m
//  SmartOneBata
//
//  Created by Tereshkin Sergey on 10/02/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "AppDelegate.h"
#import "ColorManager.h"

#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define TARGET_VERSION @"8.0"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Titles text attributes
    NSDictionary *selectedTitleTextAttributes       = @{NSForegroundColorAttributeName:[ColorManager get:ORANGE], NSFontAttributeName:[UIFont fontWithName:@"GothamMedium" size:14.0f]};
    NSDictionary *normalTitleTextAttributes         = @{NSForegroundColorAttributeName:[ColorManager get:GRAY_DARK], NSFontAttributeName:[UIFont fontWithName:@"GothamMedium" size:14.0f]};
    NSDictionary *navigationTitleTextAttributes     = @{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:@"GothamMedium" size:20.0f]};
    NSDictionary *segmentedTitleTextNormalAttr      = @{NSForegroundColorAttributeName:[UIColor blackColor], NSFontAttributeName:[UIFont fontWithName:@"GothamMedium" size:14.0f]};
    NSDictionary *segmentedTitleTextSelectedAttr    = @{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:@"GothamMedium" size:14.0f]};
    
    // Status bar setup
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Navigation bar setup
    if (SYSTEM_VERSION_GREATER_THAN(TARGET_VERSION))
        [[UINavigationBar appearance]setTranslucent:NO];
    
    //    [[UINavigationBar appearance]setShadowImage:[UIImage new]];
    //    [[UINavigationBar appearance]setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance]setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance]setBarTintColor:[ColorManager get:BLUE]];
    [[UINavigationBar appearance]setTitleTextAttributes:navigationTitleTextAttributes];
    
    // TabBar setup
    if (SYSTEM_VERSION_GREATER_THAN(TARGET_VERSION))
        [[UITabBar appearance]setTranslucent:NO];
    
    [[UITabBar appearance]setTintColor:[ColorManager get:ORANGE]];
    [[UITabBar appearance]setBarTintColor:[ColorManager get:GRAY_LIGHT]];
    [[UITabBarItem appearance]setTitleTextAttributes:normalTitleTextAttributes forState:UIControlStateNormal];
    [[UITabBarItem appearance]setTitleTextAttributes:selectedTitleTextAttributes forState:UIControlStateSelected];
    
    // Segmented control setup
    [[UISegmentedControl appearance]setTitleTextAttributes:segmentedTitleTextNormalAttr forState:UIControlStateNormal];
    [[UISegmentedControl appearance]setTitleTextAttributes:segmentedTitleTextSelectedAttr forState:UIControlStateSelected];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
