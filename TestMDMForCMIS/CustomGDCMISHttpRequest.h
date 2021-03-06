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

@interface CustomGDCMISHttpRequest : GDHttpRequest <GDHttpRequestDelegate>
@property (nonatomic, strong) id<GDHttpRequestDelegate> strongHttpRequestDelegate;
- (void)cancel;
- (BOOL)prepareConnectionWithURL:(NSURL *)url
                         session:(CMISBindingSession *)session
                          method:(NSString *)httpMethod
                            body:(NSData *)body
                         headers:(NSDictionary *)headers
                     inputStream:(NSInputStream *)inputStream
                    outputStream:(GDCWriteStream *)outputStream
                   bytesExpected:(unsigned long long)expected
                 completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
                   progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

- (BOOL)prepareConnectionWithURL:(NSURL *)url
                         session:(CMISBindingSession *)session
                          method:(NSString *)httpMethod
                         headers:(NSDictionary *)headers
                        filePath:(NSString *)filePath
                   bytesExpected:(unsigned long long)expected
                 completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;
@end
