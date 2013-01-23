//
//  CMISHttpRequestListDelegate.h
//  ObjectiveCMIS
//
//  Created by Peter Schmidt on 23/01/2013.
//  Copyright (c) 2013 Apache Software Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CMISHttpRequestListDelegate <NSObject>
- (void)addRequest:(id)request;
- (void)removeRequest:(id)request;
@end
