//
//  TestCMISNetworkIO.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 19/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "TestCMISNetworkIO.h"
#import "CMISHttpDownloadRequest.h"
#import "CMISHttpUploadRequest.h"
#import "CMISErrors.h"
#import "CMISBindingSession.h"
#import "GDCWriteStream+OutputStream.h"
#import "GDCCustomReadStream.h"
#import <GD/GDFileSystem.h>

typedef enum {
    General = 0,
    Upload,
    Download
} requestType;

@interface TestCMISNetworkIO ()
@property NSInteger requestType;
@property (nonatomic, strong) GDCCustomReadStream * inputStream;
@property (nonatomic, strong) GDCWriteStream * outputStream;
@property (nonatomic, strong) NSData *requestBody;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, assign) NSString * requestMethod;
@property (nonatomic, copy) void (^completionBlock)(CMISHttpResponse *httpResponse, NSError *error);
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSDictionary *authenticationHeader;
@property (nonatomic, copy) void (^progressBlock)(unsigned long long bytesDownloaded, unsigned long long bytesTotal);
@property (nonatomic, assign) unsigned long long bytesProcessed;
+ (NSString *)httpMethodString:(CMISHttpRequestMethod) requestMethod;
@end

@implementation TestCMISNetworkIO
@synthesize httpRequest = _httpRequest;
@synthesize completionBlock = _completionBlock;
@synthesize requestBody = _requestBody;
@synthesize requestMethod = _requestMethod;
@synthesize headers = _headers;
@synthesize bytesProcessed = _bytesProcessed;
@synthesize progressBlock = _progressBlock;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize requestType = _requestType;
@synthesize receivedData = _receivedData;
@synthesize authenticationHeader = _authenticationHeader;

- (id)init
{
    self = [super init];
    if (nil != self)
    {
        self.httpRequest = [[GDHttpRequest alloc] init];
        self.httpRequest.delegate = self;
    }
    return self;
}

- (void)onStatusChange:(GDHttpRequest *)currentHttpRequest
{
    GDHttpRequest_state_t requestState = [currentHttpRequest getState];
    switch (requestState)
    {
        case GDHttpRequest_OPENED:
        {
            NSLog(@"GDHttpRequest_OPENED");
            [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
                [currentHttpRequest setRequestHeader:[key UTF8String] withValue:[value UTF8String]];
            }];
            if (self.headers)
            {
                if ([self.requestMethod isEqualToString:@"POST"])
                {
                    [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
                        [currentHttpRequest setPostValue:[key UTF8String] forKey:[value UTF8String]];
                    }];
                    
                }
                else
                {
                    [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
                        [currentHttpRequest setRequestHeader:[key UTF8String] withValue:[value UTF8String]];
                    }];
                    
                }
    
            }
            if (self.requestBody && 0 < [self.requestBody length])
            {
                NSUInteger length = [self.requestBody length];
                char * data[length];
                [self.requestBody getBytes:&data length:length];
                [currentHttpRequest send:(const char*)data withLength:length withTimeout:60];
            }
            else
            {
                [currentHttpRequest send];
            }
            NSLog(@"GDHttpRequest_OPENED - after sending request");
            
            break;
        }
        case GDHttpRequest_LOADING:
        {
            NSLog(@"GDHttpRequest_LOADING");
            BOOL isForStreamWriting = NO;
            GDDirectByteBuffer * buffer = [currentHttpRequest getReceiveBuffer];
            NSData *bufferData = [buffer unreadData];
            
            if (self.outputStream)
            {
                isForStreamWriting = YES;
                NSUInteger bufferLength = [bufferData length];
                uint8_t uBuffer[bufferLength];
                [bufferData getBytes:&uBuffer length:bufferLength];
                [self.outputStream write:(const uint8_t *)(&uBuffer) maxLength:bufferLength];
            }
            if (!isForStreamWriting)
            {
                [self.receivedData appendData:bufferData];
            }
            break;
        }
        case GDHttpRequest_HEADERS_RECEIVED:
        {
            NSLog(@"GDHttpRequest_HEADERS_RECEIVED");
            const char * headers = [currentHttpRequest getAllResponseHeaders];
            self.receivedData = [NSMutableData data];
            break;
        }
        case GDHttpRequest_DONE:
        {
            NSLog(@"GDHttpRequest_DONE");
            int statusCode = [currentHttpRequest getStatus];
            const char * msgChar = [currentHttpRequest getStatusText];
            NSString * message = [[NSString alloc] initWithUTF8String:msgChar];
            if (200 > statusCode || 299 < statusCode)
            {
                NSError * error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeFilterNotValid
                                              withDetailedDescription:message];
                self.completionBlock(nil, error);
            }
            else
            {
                GDDirectByteBuffer * buffer = [self.httpRequest getReceiveBuffer];
                NSData *bufferData = [buffer unreadData];
                
                BOOL isForStreamWriting = NO;
                if (self.outputStream)
                {
                    isForStreamWriting = YES;
                    NSUInteger bufferLength = [bufferData length];
                    uint8_t uBuffer[bufferLength];
                    [bufferData getBytes:&uBuffer length:bufferLength];
                    [self.outputStream write:(const uint8_t *)(&uBuffer) maxLength:bufferLength];
                }
                if (!isForStreamWriting)
                {
                    [self.receivedData appendData:bufferData];
                }
                
                CMISHttpResponse * httpResponse = [CMISHttpResponse responseWithStatusCode:statusCode statusMessage:message headers:nil responseData:self.receivedData];
                self.completionBlock(httpResponse, nil);
            }
            self.completionBlock = nil;
            break;
        }
    }
    
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


- (void)cancel
{
    self.completionBlock = nil;
}

+ (id<CMISHttpRequestDelegate>)startRequestWithURL:(NSURL *)url
                                        httpMethod:(CMISHttpRequestMethod)httpRequestMethod
                                       requestBody:(NSData *)requestBody
                                           headers:(NSDictionary *)additionalHeaders
                                           session:(CMISBindingSession *)session
                                   completionBlock:(void (^)(CMISHttpResponse *, NSError *))completionBlock
{
    TestCMISNetworkIO *networkIO = [[self alloc] init];
    networkIO.completionBlock = completionBlock;
    networkIO.requestMethod = [TestCMISNetworkIO httpMethodString:httpRequestMethod];
    networkIO.requestBody = requestBody;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    networkIO.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];
    networkIO.headers = additionalHeaders;
    networkIO.requestType = General;
    BOOL success = [networkIO.httpRequest open:[networkIO.requestMethod UTF8String] withUrl:[[url absoluteString] UTF8String] withAsync:NO];
    if (success)
    {
        NSLog(@"the request was successfully opened");
        [networkIO.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [networkIO.httpRequest setRequestHeader:[key UTF8String] withValue:[value UTF8String]];
        }];
        [networkIO.httpRequest send];
    }
    else
    {
        NSLog(@"opening the request failed");
    }
    return networkIO;
}

+ (id<CMISHttpRequestDelegate>)startUploadRequestWithURL:(NSURL *)url
                                              httpMethod:(CMISHttpRequestMethod)httpRequestMethod
                                             inputStream:(id)inputStream
                                                 headers:(NSDictionary *)additionalHeaders
                                                 session:(CMISBindingSession *)session
                                           bytesExpected:(unsigned long long)bytesExpected
                                         completionBlock:(void (^)(CMISHttpResponse *, NSError *))completionBlock
                                           progressBlock:(void (^)(unsigned long long, unsigned long long))progressBlock
{
    TestCMISNetworkIO *networkIO = [[self alloc] init];
    networkIO.progressBlock = progressBlock;
    networkIO.completionBlock = completionBlock;
    networkIO.requestMethod = [TestCMISNetworkIO httpMethodString:httpRequestMethod];
    networkIO.requestBody = nil;
    networkIO.inputStream = inputStream;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    networkIO.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];
    networkIO.headers = additionalHeaders;
    networkIO.requestType = Upload;
    [networkIO.httpRequest open:[networkIO.requestMethod UTF8String] withUrl:[[url absoluteString] UTF8String] withAsync:YES];
    
    return networkIO;
    
}

+ (id<CMISHttpRequestDelegate>)startDownloadRequestWithURL:(NSURL *)url
                                                httpMethod:(CMISHttpRequestMethod)httpRequestMethod
                                              outputStream:(id)outputStream
                                                   session:(CMISBindingSession *)session
                                             bytesExpected:(unsigned long long)bytesExpected
                                           completionBlock:(void (^)(CMISHttpResponse *, NSError *))completionBlock
                                             progressBlock:(void (^)(unsigned long long, unsigned long long))progressBlock
{
    TestCMISNetworkIO *networkIO = [[self alloc] init];
    networkIO.progressBlock = progressBlock;
    networkIO.completionBlock = completionBlock;
    networkIO.requestMethod = [TestCMISNetworkIO httpMethodString:httpRequestMethod];
    networkIO.requestBody = nil;
    networkIO.requestType = Download;
    networkIO.outputStream = outputStream;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    networkIO.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];    
    [networkIO.httpRequest open:[networkIO.requestMethod UTF8String] withUrl:[[url absoluteString] UTF8String] withAsync:YES];
    
    return networkIO;    
}
@end
