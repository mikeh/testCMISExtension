//
//  GDHttpRequest+Request.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 09/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import "GDHttpRequest+Request.h"

@implementation GDHttpRequest (Request)
- (void)cancel
{
    [self abort];
}
@end
