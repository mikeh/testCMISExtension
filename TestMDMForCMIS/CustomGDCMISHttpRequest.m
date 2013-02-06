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

#import "CustomGDCMISHttpRequest.h"

@interface CustomGDCMISHttpRequest ()
@property (nonatomic, strong) NSData *requestBody;
@property (nonatomic, strong) NSData *uploadData;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, assign) NSString * requestMethod;
@property (nonatomic, copy) void (^completionBlock)(CMISHttpResponse *httpResponse, NSError *error);
@property (nonatomic, copy) void (^progressBlock)(unsigned long long bytesDownloaded, unsigned long long bytesTotal);
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSDictionary *authenticationHeader;
@property (nonatomic, assign) unsigned long long bytesExpected;
@property (nonatomic, strong) GDCWriteStream * outputStream;
@property (nonatomic, strong) NSInputStream * inputStream;
@property (nonatomic, strong) NSString * filePath;
- (void)onOpened:(CustomGDCMISHttpRequest *)currentHttpRequest;
- (void)onHeaderReceived:(CustomGDCMISHttpRequest *)currentHttpRequest;
- (void)onDone:(CustomGDCMISHttpRequest *)currentHttpRequest;
- (void)prepareRequestHeadersForRequest:(CustomGDCMISHttpRequest *)request;
- (NSData *)dataFromInput;
- (void)readFromBuffer:(GDDirectByteBuffer *)buffer;

@end


@implementation CustomGDCMISHttpRequest

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        [self setDelegate:self];
    }
    return self;
}


- (void)setDelegate:(id<GDHttpRequestDelegate>)httpDelegate
{
    [super setDelegate:httpDelegate];
    _strongHttpRequestDelegate = [super delegate];
}

- (void)onStatusChange:(CustomGDCMISHttpRequest *)currentHttpRequest
{
    NSLog(@"ENTERING onStatusChange");
    GDHttpRequest_state_t requestState = [currentHttpRequest getState];
    switch (requestState)
    {
        case GDHttpRequest_UNSENT:
            break;
        case GDHttpRequest_OPENED:
        {
            NSLog(@"onStatusChange GDHttpRequest_OPENED");
            [self onOpened:currentHttpRequest];
            break;
        }
        case GDHttpRequest_SENT:
            break;
        case GDHttpRequest_HEADERS_RECEIVED:
        {
            NSLog(@"onStatusChange GDHttpRequest_HEADERS_RECEIVED");
            [self onHeaderReceived:currentHttpRequest];
            break;
        }
        case GDHttpRequest_LOADING:
        {
            NSLog(@"onStatusChange GDHttpRequest_LOADING");
            [self readFromBuffer:[currentHttpRequest getReceiveBuffer]];
            break;
        }
        case GDHttpRequest_DONE:
        {
            NSLog(@"onStatusChange GDHttpRequest_DONE");
            [self onDone:currentHttpRequest];
            break;
        }
        default:
            break;
    }
    
    
}

- (void)onOpened:(CustomGDCMISHttpRequest *)currentHttpRequest
{
    [self prepareRequestHeadersForRequest:currentHttpRequest];
    
    BOOL sendSuccess = NO;
    if (self.requestBody)
    {
        sendSuccess = [currentHttpRequest sendData:self.requestBody];
    }
    else if (self.inputStream)
    {
        self.uploadData = [self dataFromInput];
        if (nil == self.uploadData)
        {
            [currentHttpRequest close];
        }
        else
        {
            sendSuccess = [currentHttpRequest sendData:self.uploadData];
        }
    }
    else if (self.filePath)
    {
        sendSuccess = [currentHttpRequest sendWithFile:self.filePath withTimeout:60];
    }
    else
    {
        sendSuccess = [currentHttpRequest send];
    }
    NSLog(@"onOpened: the send was %@", ((sendSuccess) ? @"successful" : @"unsuccessful") );
}

- (void)onHeaderReceived:(CustomGDCMISHttpRequest *)currentHttpRequest
{
    NSLog(@"onHeaderReceived");
    if (!self.outputStream)
    {
        self.receivedData = [NSMutableData data];
    }
    const char * responseHeader = [currentHttpRequest getAllResponseHeaders];
    NSLog(@"The received header is \n%@",[NSString stringWithUTF8String:responseHeader]);
}


- (void)onDone:(CustomGDCMISHttpRequest *)currentHttpRequest
{
    NSLog(@"onDone");
    int statusCode = [currentHttpRequest getStatus];
    const char * messageText = [currentHttpRequest getStatusText];
    NSString *message = [[NSString alloc] initWithUTF8String:messageText];
    [self readFromBuffer:[currentHttpRequest getReceiveBuffer]];
    if (200 <= statusCode && 299 >= statusCode)
    {
        NSLog(@"The HTTP request returns with HTTP ok status code %d",statusCode);
        CMISHttpResponse * httpResponse = [CMISHttpResponse responseWithStatusCode:statusCode statusMessage:message headers:nil responseData:self.receivedData];
        self.completionBlock(httpResponse, nil);
    }
    else
    {
        NSLog(@"We get a error as HTTP status: %d and message %@", statusCode, message);
        NSError * error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeFilterNotValid
                                      withDetailedDescription:message];
        self.completionBlock(nil, error);
    }
    
    /**
     for logging purposes
    if (self.receivedData)
    {
        NSLog(@"The amount of data we get back is %d and content is %@",[self.receivedData length], [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding]);
    }
     */
    self.completionBlock = nil;
    [currentHttpRequest close];
}


- (void)cancel
{
    [self abort];
}

- (BOOL)prepareConnectionWithURL:(NSURL *)url
                         session:(CMISBindingSession *)session
                          method:(NSString *)httpMethod
                            body:(NSData *)body
                         headers:(NSDictionary *)headers
                     inputStream:(NSInputStream *)inputStream
                    outputStream:(GDCWriteStream *)outputStream
                   bytesExpected:(unsigned long long)expected
                 completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
                   progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
{
    
    self.requestBody = body;
    self.requestMethod = httpMethod;
    self.headers = headers;
    self.inputStream = inputStream;
    self.outputStream = outputStream;
    self.filePath = nil;
    self.bytesExpected = expected;
    self.completionBlock = completionBlock;
    self.progressBlock = progressBlock;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    self.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];
    return [self open:[self.requestMethod UTF8String] withUrl:[[url absoluteString] UTF8String] withAsync:YES];
}


- (BOOL)prepareConnectionWithURL:(NSURL *)url
                         session:(CMISBindingSession *)session
                          method:(NSString *)httpMethod
                         headers:(NSDictionary *)headers
                        filePath:(NSString *)filePath
                   bytesExpected:(unsigned long long)expected
                 completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    self.requestBody = nil;
    self.requestMethod = httpMethod;
    self.headers = headers;
    self.bytesExpected = expected;
    self.completionBlock = completionBlock;
    self.progressBlock = nil;
    self.filePath = filePath;
    self.inputStream = nil;
    self.outputStream = nil;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    self.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];
    return [self open:[self.requestMethod UTF8String] withUrl:[[url absoluteString] UTF8String] withAsync:YES];
}


- (void)prepareRequestHeadersForRequest:(CustomGDCMISHttpRequest *)request
{
    [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
        [request setRequestHeader:[key UTF8String] withValue:[value UTF8String]];
    }];
    if (self.headers)
    {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *headerName, NSString *header, BOOL *stop) {
            [request setRequestHeader:[headerName UTF8String] withValue:[header UTF8String]];
        }];
    }
}


- (NSData *)dataFromInput
{
    BOOL streamIsReady = self.inputStream.streamStatus == NSStreamStatusOpen;
    if (!streamIsReady)
    {
        [self.inputStream open];
    }
    if (![self.inputStream hasBytesAvailable])
    {
        return nil;
    }
    NSMutableData *uploadData = [NSMutableData data];
    NSInteger bytesRead = 0;
    const char c = '\0';
    uint8_t nullBuffer[1];
    nullBuffer[0] = c;
    while ([self.inputStream hasBytesAvailable])
    {
        @autoreleasepool
        {
            const NSUInteger bufferSize = 16384;
            NSUInteger readBytes = 0;
            uint8_t buffer[bufferSize];
            readBytes = [self.inputStream read:buffer maxLength:bufferSize];
            [uploadData appendBytes:(const void *)buffer length:readBytes];
            bytesRead += readBytes;
        }
    }
    return uploadData;
}

- (void)readFromBuffer:(GDDirectByteBuffer *)buffer
{
    if (buffer.bytesUnread == 0)
    {
        return;
    }
    if (self.outputStream)
    {
        NSData *received = [buffer unreadData];
        NSUInteger dataSize = [received length];
        uint8_t buffer[dataSize];
        [received getBytes:buffer length:dataSize];
        NSUInteger bytesWritten = [self.outputStream write:(const uint8_t *)(&buffer) maxLength:dataSize];
        if (bytesWritten == -1)
        {
            NSLog(@"GDHttpUtil::readFromBuffer: failed to write data");
        }
        else
        {
            NSLog(@"GDHttpUtil::readFromBuffer: We have written %d bytes to output stream", bytesWritten);
        }
    }
    else
    {
        [self.receivedData appendData:[buffer unreadData]];
    }
}


@end
