//
//  AppDelegate.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 19/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <GD/GDiOS.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate, GDiOSDelegate> {
    BOOL started;
}

-(void) onAuthorised:(GDAppEvent*)anEvent;
-(void) onNotAuthorised:(GDAppEvent*)anEvent;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) GDiOS *good;

@end
