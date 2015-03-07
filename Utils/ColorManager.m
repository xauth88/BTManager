//
//  ColorManager.m
//  CustomTabBar
//
//  Created by Tereshkin Sergey on 21/01/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "ColorManager.h"

static UIColor *orange;
static UIColor *green;
static UIColor *red;
static UIColor *blue;
static UIColor *grayDark;
static UIColor *grayLight;

@implementation ColorManager

+ (UIColor *) get:(int) color
{
    switch (color) {
        case ORANGE:
            if(!orange)
                orange      = [UIColor colorWithRed:241.0f/255.0f green:153.0f/255.0f blue:11.0f/255.0f alpha:1.0f];
            return orange;

        case GREEN:
            if(!green)
                green       = [UIColor colorWithRed:82.0f/255.0f green:175.0f/255.0f blue:119.0f/255.0f alpha:1.0f];
            return green;
            
        case RED:
            if(!red)
                red         = [UIColor colorWithRed:222.0f/255.0f green:54.0f/255.0f blue:46.0f/255.0f alpha:1.0f];
            return red;
            
        case BLUE:
            if(!blue)
                blue        = [UIColor colorWithRed:46.0f/255.0f green:46.0f/255.0f blue:68.0f/255.0f alpha:1.0f];
            return blue;
            
        case GRAY_DARK:
            if(!grayDark)
                grayDark    = [UIColor colorWithRed:131.0f/255.0f green:137.0f/255.0f blue:154.0f/255.0f alpha:1.0f];
            return grayDark;
            
        case GRAY_LIGHT:
            if(!grayLight)
                grayLight   = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:242.0f/255.0f alpha:1.0f];
            return grayLight;
            
        default:
            NSLog(@"! -> UKNOWN Color id: %i", color);
            break;
    }
    return [UIColor whiteColor];
}

@end
