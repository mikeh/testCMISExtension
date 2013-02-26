/*
 ******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *****************************************************************************
 */

#import "AppDelegate.h"
#import <GD/GDNETiOS.h>
@implementation AppDelegate

@synthesize good = _good;

// change the app ID and version here to the ID and version enabled on the GC
NSString* kappId = @"__MyCompanyName__.Test31";
NSString* kappVersion = @"1.0.0.0";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setUpUserSettings];
    self.window = [[GDiOS sharedInstance] getWindow];
    self.good = [GDiOS sharedInstance];
    _good.delegate = self;
    started = NO;
    //Show the Good Authentication UI.
    [_good authorise:kappId andVersion:kappVersion];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return YES;
}

#pragma mark Good Dynamics Delegate Methods

-(void)handleEvent:(GDAppEvent*)anEvent
{
    /* Called from _good when events occur, such as system startup. */

    switch (anEvent.type) 
    {
		case GDAppEventAuthorised: 
        {
            [self onAuthorised:anEvent];
			break;
        }
		case GDAppEventNotAuthorised: 
        {
            [self onNotAuthorised:anEvent];
			break;
        }
		case GDAppEventRemoteSettingsUpdate: 
        {
            // handle app config changes
			break;
        }
        case GDAppEventServicesUpdate:
        {
            break;
        }
        case GDAppEventPolicyUpdate:
        {
            break;
        }
    }
}

-(void) onNotAuthorised:(GDAppEvent*)anEvent 
{
    /* Handle the Good Libraries not authorised event. */                            

    switch (anEvent.code) {
        case GDErrorActivationFailed:
        case GDErrorProvisioningFailed:
        case GDErrorPushConnectionTimeout:
        case GDErrorProvisioningCancelled: {
            // application can either handle this and show it's own UI or just call back into
            // the GD library and the welcome screen will be shown            
            [_good authorise:kappId andVersion:kappVersion];
            break;
        }
        case GDErrorSecurityError:
        case GDErrorAppDenied:
        case GDErrorBlocked:
        case GDErrorWiped:
        case GDErrorRemoteLockout: 
        case GDErrorPasswordChangeRequired: {
            // an condition has occured denying authorisation, an application may wish to log these events
            NSLog(@"onNotAuthorised %@", anEvent.message);
            break;
        }
        case GDErrorIdleLockout: {
            // idle lockout is benign & informational
            break;
        }
        default: 
            NSAssert(false, @"Unhandled not authorised event");
            break;
    }
}

-(void) onAuthorised:(GDAppEvent*)anEvent 
{
    /* Handle the Good Libraries authorised event. */                            

    switch (anEvent.code) {
        case GDErrorNone: {
            if (!started) {
                /** if we are NOT using GDHttpRequest API - ensure that we use the secure Communication API
                 ** see https://begood.good.com/message/9926#9926 
                 ** [GDURLLoadingSystem enableSecureCommunication];
                 */
                // launch application UI here
                started = YES;
            }
            break;
        }
        default:
            NSAssert(false, @"Authorised startup with an error");
            break;
    }
}

- (void)setUpUserSettings
{
    NSArray *serverSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverSettings"];
    if (nil == serverSettings)
    {
        NSMutableArray *settings = [NSMutableArray arrayWithCapacity:3];
        NSMutableDictionary *amazon = [NSMutableDictionary dictionary];
        [amazon setObject:@"http://ec2-54-247-141-218.eu-west-1.compute.amazonaws.com/alfresco/service/api/cmis" forKey:@"url"];
        [amazon setObject:@"" forKey:@"username"];
        [amazon setObject:@"" forKey:@"password"];
        [amazon setObject:@"368eca28-be2b-4a8d-8bbb-1d7997af7930" forKey:@"repositoryId"];
        [amazon setObject:@"" forKey:@"downloadId"];
        [amazon setObject:@"" forKey:@"uploadId"];
        
        [settings addObject:amazon];
        NSMutableDictionary *ts = [NSMutableDictionary dictionary];
        [ts setObject:@"https://ts.alfresco.com/alfresco/service/cmis" forKey:@"url"];
        [ts setObject:@"" forKey:@"username"];
        [ts setObject:@"" forKey:@"password"];
        [ts setObject:@"" forKey:@"repositoryId"];
        [ts setObject:@"" forKey:@"downloadId"];
        [ts setObject:@"" forKey:@"uploadId"];
        [settings addObject:ts];

        NSMutableDictionary *localHost = [NSMutableDictionary dictionary];
        [localHost setObject:@"http://localhost:8080/alfresco/service/cmis" forKey:@"url"];
        [localHost setObject:@"" forKey:@"username"];
        [localHost setObject:@"" forKey:@"password"];
        [localHost setObject:@"" forKey:@"repositoryId"];
        [localHost setObject:@"" forKey:@"downloadId"];
        [localHost setObject:@"" forKey:@"uploadId"];
        [settings addObject:localHost];
        
        [[NSUserDefaults standardUserDefaults] setObject:settings forKey:@"serverSettings"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
