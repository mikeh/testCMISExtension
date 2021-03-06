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
//#import "CustomGDCMISSocketRequest.h"

@interface CustomGDCMISNetworkProvider ()
+ (NSString *)httpMethodString:(CMISHttpRequestMethod) requestMethod;
@end

@implementation CustomGDCMISNetworkProvider



#pragma CMISNetworkProvider invoker methods


- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
          body:(NSData *)body
       headers:(NSDictionary *)additionalHeaders
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    if (cmisRequest.isCancelled)
    {
        if (completionBlock)
        {
            NSError *error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeCancelled detailedDescription:@"Request was cancelled"];
            completionBlock(nil, error);
        }
        return;
    }
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
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection detailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
    else
        cmisRequest.httpRequest = request;
    
}

/*
 */
- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    if (cmisRequest.isCancelled)
    {
        if (completionBlock)
        {
            NSError *error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeCancelled detailedDescription:@"Request was cancelled"];
            completionBlock(nil, error);
        }
        return;
    }
    CustomGDCMISHttpRequest *request = [[CustomGDCMISHttpRequest alloc] init];
    BOOL success = [request prepareConnectionWithURL:url
                                                    session:session
                                                     method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                                       body:nil
                                                    headers:additionalHeaders
                                                inputStream:(NSInputStream *)inputStream
                                               outputStream:nil
                                              bytesExpected:0
                                            completionBlock:completionBlock
                                              progressBlock:nil];
    if(!success && completionBlock)
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection detailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
    else
        cmisRequest.httpRequest = request;
}

/*
 The code below is an optional method on the CMISNetworkProvider protocol. It accepts a filepath as argument.
 This filepath needs to be in the standard file system area - and NOT in the secure storage area (acc to Good).
 
 NOTE/WARNING:
 The sendWithFile: method of GDHttpRequest is using PUT HTTP methods only (even if you pass in POST).
 This means we cannot use this method, as a PUT request would attempt to modify the folder itself, rather than creating a file in it.
 This issue has been flagged with Good
 https://begood.good.com/message/9774#9774
 */
/*
- (void)invoke:(NSURL *)url withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
      filePath:(NSString *)encodedFilePath
       headers:(NSDictionary *)additionalHeaders
 bytesExpected:(unsigned long long)bytesExpected
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
 requestObject:(CMISRequest *)requestObject
{
    CustomGDCMISHttpRequest *request = [[CustomGDCMISHttpRequest alloc] init];
    NSLog(@"uploading file %@",encodedFilePath);
    BOOL success = [request prepareConnectionWithURL:url
                                             session:session
                                              method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                             headers:additionalHeaders
                                            filePath:encodedFilePath
                                       bytesExpected:bytesExpected
                                     completionBlock:completionBlock];
    
    if(!success && completionBlock)
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection withDetailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
}
 */

/* 
 This is the method designed to be used with GDSockets - except this won't work when using SSL connections.
 */
/*
- (void)invoke:(NSURL *)url
withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
 bytesExpected:(unsigned long long)bytesExpected
      mimeType:(NSString *)mimeType
    properties:(CMISProperties *)properties
completionBlock:(void (^)(CMISHttpResponse *, NSError *))completionBlock
 progressBlock:(void (^)(unsigned long long, unsigned long long))progressBlock
 requestObject:(CMISRequest *)requestObject
{
    NSString *urlString = [url absoluteString];
    
    NSString *separator = ([urlString hasPrefix:@"https://"]) ? @"https://" : @"http://";
    NSArray *urlComponents = [urlString componentsSeparatedByString:separator];
    NSString *bareUrlString = [urlComponents objectAtIndex:1];
    NSLog(@"Bare URL is %@", bareUrlString);
    
    separator = @"/alfresco";
    NSArray *apiComponents = [bareUrlString componentsSeparatedByString:separator];
    NSString *host = [NSString stringWithFormat:@"%@",[apiComponents objectAtIndex:0]];
    NSLog(@"Host is %@", host);
    
    NSMutableString *serviceApiString = [NSMutableString stringWithString:separator];
    for (int i=1; i<apiComponents.count; i++)
    {
        [serviceApiString appendString:[apiComponents objectAtIndex:i]];
    }
    NSString *serviceApi = (NSString *)serviceApiString;
    int portID = 80;
    
    NSArray *hostArray = [host componentsSeparatedByString:@":"];
    host = [hostArray objectAtIndex:0];
    if (1 < hostArray.count)
    {
        NSString *portNumber = [hostArray objectAtIndex:1];
        portID = [portNumber intValue];
    }
    
    
    BOOL isSSL = ([separator isEqualToString:@"https://"] ? YES : NO);
    
    CustomGDCMISSocketRequest *request = [[CustomGDCMISSocketRequest alloc] initWithHostName:host
                                                                                  serviceAPI:serviceApi
                                                                                        port:portID
                                                                                      useSSL:isSSL];
    [request prepareConnectionWithSession:session
                                   method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                  headers:additionalHeaders
                              inputStream:inputStream
                            bytesExpected:bytesExpected
                                 mimeType:mimeType
                               properties:properties
                          completionBlock:completionBlock
                            progressBlock:progressBlock];
    
    
    if (request)
    {
        requestObject.httpRequest = request;
    }
    else
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection withDetailedDescription:detailedDescription];
        completionBlock(nil, cmisError);        
    }

}
*/

- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
 bytesExpected:(unsigned long long)bytesExpected
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
{
    /*
    NSString *urlString = [url absoluteString];
    
    NSString *separator = ([urlString hasPrefix:@"https://"]) ? @"https://" : @"http://";
    NSArray *urlComponents = [urlString componentsSeparatedByString:separator];
    NSString *bareUrlString = [urlComponents objectAtIndex:1];
    NSLog(@"Bare URL is %@", bareUrlString);
    
    separator = @"/alfresco";
    NSArray *apiComponents = [bareUrlString componentsSeparatedByString:separator];
    NSString *host = [NSString stringWithFormat:@"%@",[apiComponents objectAtIndex:0]];
    NSLog(@"Host is %@", host);
    
    NSMutableString *serviceApiString = [NSMutableString stringWithString:separator];
    for (int i=1; i<apiComponents.count; i++)
    {
        [serviceApiString appendString:[apiComponents objectAtIndex:i]];
    }
    NSString *serviceApi = (NSString *)serviceApiString;
    CustomGDCMISSocketRequest *request = [[CustomGDCMISSocketRequest alloc] initWithHostName:host
                                                                                  serviceAPI:serviceApi
                                                                                        port:80
                                                                                      useSSL:NO];
    [request prepareConnectionWithSession:session
                                   method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                  headers:additionalHeaders
                              inputStream:inputStream
                            bytesExpected:bytesExpected
                          completionBlock:completionBlock
                            progressBlock:progressBlock];
    
     */
    if (cmisRequest.isCancelled)
    {
        if (completionBlock)
        {
            NSError *error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeCancelled detailedDescription:@"Request was cancelled"];
            completionBlock(nil, error);
        }
        return;
    }
    CustomGDCMISHttpRequest *request = [[CustomGDCMISHttpRequest alloc] init];
    BOOL success = [request prepareConnectionWithURL:url
                                                    session:session
                                                     method:[CustomGDCMISNetworkProvider httpMethodString:httpRequestMethod]
                                                       body:nil
                                                    headers:additionalHeaders
                                                inputStream:(NSInputStream *)inputStream
                                               outputStream:nil
                                              bytesExpected:bytesExpected
                                            completionBlock:completionBlock
                                              progressBlock:progressBlock];
    if(!success && completionBlock)
    {
        NSString *detailedDescription = [NSString stringWithFormat:@"Could not create connection to %@", [url absoluteString]];
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection detailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
    else
    {
        cmisRequest.httpRequest = request;
    }
}

- (void)invoke:(NSURL *)url
    httpMethod:(CMISHttpRequestMethod)httpRequestMethod
       session:(CMISBindingSession *)session
  outputStream:(NSOutputStream *)outputStream
 bytesExpected:(unsigned long long)bytesExpected
   cmisRequest:(CMISRequest *)cmisRequest
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
{
    if (cmisRequest.isCancelled)
    {
        if (completionBlock)
        {
            NSError *error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeCancelled detailedDescription:@"Request was cancelled"];
            completionBlock(nil, error);
        }
        return;
    }
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
        NSError *cmisError = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeConnection detailedDescription:detailedDescription];
        completionBlock(nil, cmisError);
    }
    else
    {
        cmisRequest.httpRequest = request;
    }
}

- (void)invokeGET:(NSURL *)url
          session:(CMISBindingSession *)session
      cmisRequest:(CMISRequest *)cmisRequest
  completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
             httpMethod:HTTP_GET
                session:session
                   body:nil
                headers:nil
            cmisRequest:cmisRequest
        completionBlock:completionBlock];
}

- (void)invokePOST:(NSURL *)url
           session:(CMISBindingSession *)session
              body:(NSData *)body
           headers:(NSDictionary *)additionalHeaders
       cmisRequest:(CMISRequest *)cmisRequest
   completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
             httpMethod:HTTP_POST
                session:session
                   body:body
                headers:additionalHeaders
            cmisRequest:cmisRequest
        completionBlock:completionBlock];
}

- (void)invokePUT:(NSURL *)url
          session:(CMISBindingSession *)session
             body:(NSData *)body
          headers:(NSDictionary *)additionalHeaders
      cmisRequest:(CMISRequest *)cmisRequest
  completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
             httpMethod:HTTP_PUT
                session:session
                   body:body
                headers:additionalHeaders
            cmisRequest:cmisRequest
        completionBlock:completionBlock];
}

- (void)invokeDELETE:(NSURL *)url
             session:(CMISBindingSession *)session
         cmisRequest:(CMISRequest *)cmisRequest
     completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return [self invoke:url
             httpMethod:HTTP_DELETE
                session:session
                   body:nil
                headers:nil
            cmisRequest:cmisRequest
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
