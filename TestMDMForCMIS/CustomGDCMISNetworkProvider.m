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

#import "CustomGDCMISNetworkProvider.h"
#import "CMISAuthenticationProvider.h"
#import "CMISErrors.h"
#import "CMISHttpResponse.h"
#import "CMISHttpRequest.h"
#import "CMISHttpDownloadRequest.h"
#import "CMISHttpUploadRequest.h"
#import "CMISRequest.h"
#import "CMISSessionParameters.h"

@interface CustomGDCMISNetworkProvider ()
+ (NSString *)httpMethodString:(CMISHttpRequestMethod) requestMethod;
@end

@implementation CustomGDCMISNetworkProvider

#pragma CMISNetworkProvider invoker methods


- (void)invoke:(NSURL *)url
withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
          body:(NSData *)body
       headers:(NSDictionary *)additionalHeaders
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    CustomGDCMISHttpRequest *request = [[CustomGDCMISHttpRequest alloc] init];
    BOOL success = [request prepareConnectionWithURL:url
                                                    session:session
                                                     method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                                       body:body
                                                    headers:additionalHeaders
                                                inputStream:nil
                                               outputStream:nil
                                              bytesExpected:0
                                            completionBlock:completionBlock
                                              progressBlock:nil];
    
    if(!success && completionBlock)
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection withDetailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
}

- (void)invoke:(NSURL *)url
withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    CustomGDCMISHttpRequest *request = [[CustomGDCMISHttpRequest alloc] init];
    BOOL success = [request prepareConnectionWithURL:url
                                                    session:session
                                                     method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                                       body:nil
                                                    headers:additionalHeaders
                                                inputStream:(GDCReadStream *)inputStream
                                               outputStream:nil
                                              bytesExpected:0
                                            completionBlock:completionBlock
                                              progressBlock:nil];
    if(!success && completionBlock)
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection withDetailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
}


- (void)invoke:(NSURL *)url
withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
 bytesExpected:(unsigned long long)bytesExpected
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
 requestObject:(CMISRequest *)requestObject
{
    CustomGDCMISHttpRequest *request = [[CustomGDCMISHttpRequest alloc] init];
    BOOL success = [request prepareConnectionWithURL:url
                                                    session:session
                                                     method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                                       body:nil
                                                    headers:additionalHeaders
                                                inputStream:(GDCReadStream *)inputStream
                                               outputStream:nil
                                              bytesExpected:bytesExpected
                                            completionBlock:completionBlock
                                              progressBlock:progressBlock];
    if(!success && completionBlock)
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection withDetailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
    else
    {
        requestObject.httpRequest = request;
    }
}

- (void)invoke:(NSURL *)url
withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
  outputStream:(NSOutputStream *)outputStream
 bytesExpected:(unsigned long long)bytesExpected
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
 requestObject:(CMISRequest*)requestObject
{
    CustomGDCMISHttpRequest *request = [[CustomGDCMISHttpRequest alloc] init];
    BOOL success = [request prepareConnectionWithURL:url
                                                    session:session
                                                     method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                                       body:nil
                                                    headers:nil
                                                inputStream:nil
                                               outputStream:(GDCWriteStream *)outputStream
                                              bytesExpected:bytesExpected
                                            completionBlock:completionBlock
                                              progressBlock:progressBlock];
    if(!success && completionBlock)
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection withDetailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
    else
    {
        requestObject.httpRequest = request;
    }
}

- (void)invokeGET:(NSURL *)url
      withSession:(CMISBindingSession *)session
  completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
         withHttpMethod:HTTP_GET
            withSession:session
                   body:nil
                headers:nil
        completionBlock:completionBlock];
}

- (void)invokePOST:(NSURL *)url
       withSession:(CMISBindingSession *)session
              body:(NSData *)body
           headers:(NSDictionary *)additionalHeaders
   completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
         withHttpMethod:HTTP_POST
            withSession:session
                   body:body
                headers:additionalHeaders
        completionBlock:completionBlock];
}

- (void)invokePUT:(NSURL *)url
      withSession:(CMISBindingSession *)session
             body:(NSData *)body
          headers:(NSDictionary *)additionalHeaders
  completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
         withHttpMethod:HTTP_PUT
            withSession:session
                   body:body
                headers:additionalHeaders
        completionBlock:completionBlock];
}

- (void)invokeDELETE:(NSURL *)url
         withSession:(CMISBindingSession *)session
     completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
         withHttpMethod:HTTP_DELETE
            withSession:session
                   body:nil
                headers:nil
        completionBlock:completionBlock];
}

+ (NSString *)httpMethodString:(CMISHttpRequestMethod) requestMethod
{
    NSString *httpMethod;
    switch (requestMethod) {
        case HTTP_GET:
            httpMethod = @"GET";
            break;
        case HTTP_POST:
            httpMethod = @"POST";
            break;
        case HTTP_DELETE:
            httpMethod = @"DELETE";
            break;
        case HTTP_PUT:
            httpMethod = @"PUT";
            break;
        default:
            NSLog(@"Invalid http request method: %d", requestMethod);
            return nil;
    }
    return httpMethod;
}



@end
