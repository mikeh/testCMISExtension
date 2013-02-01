//
//  CustomGDCMISSocketRequest.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 31/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GD/GDNETiOS.h>
#import <GD/GDFileSystem.h>
#import "CMISNetworkProvider.h"
#import "CMISAuthenticationProvider.h"
#import "CMISErrors.h"
#import "CMISHttpResponse.h"
#import "CMISHttpRequest.h"
#import "CMISHttpDownloadRequest.h"
#import "CMISHttpUploadRequest.h"
#import "CMISRequest.h"
#import "CMISSessionParameters.h"
#import "CMISProperties.h"

@interface CustomGDCMISSocketRequest : GDSocket <GDSocketDelegate>
@property (nonatomic, strong) id<GDSocketDelegate> strongSocketDelegate;
- (id)initWithHostName:(NSString *)hostName serviceAPI:(NSString *)serviceAPIString port:(int)port useSSL:(BOOL)useSSL;
- (void)cancel;
- (void)prepareConnectionWithSession:(CMISBindingSession *)session
                              method:(NSString *)httpMethod
                             headers:(NSDictionary *)headers
                         inputStream:(NSInputStream *)inputStream
                       bytesExpected:(unsigned long long)expected
                            mimeType:(NSString *)mimeType
                          properties:(CMISProperties *)properties
                     completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
                       progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;
@end
