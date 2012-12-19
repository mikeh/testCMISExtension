//
//  main.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 19/12/2012.
//  Copyright 2012 Peter Schmidt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GD/GDios.h>
#import "AppDelegate.h"

int main(int argc, char* argv[])
{
    @autoreleasepool {
        [GDiOS initialiseWithClassNameConformingToUIApplicationDelegate:@"AppDelegate"];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}




