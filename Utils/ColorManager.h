//
//  ColorManager.h
//  CustomTabBar
//
//  Created by Tereshkin Sergey on 21/01/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define ORANGE      1
#define GREEN       2
#define RED         3
#define BLUE        4
#define GRAY_LIGHT  5
#define GRAY_DARK   6

@interface ColorManager : NSObject

+ (UIColor *) get:(int) color;

@end
