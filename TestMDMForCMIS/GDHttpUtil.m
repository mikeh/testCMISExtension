//
//  GDHttpUtil.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 09/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import "GDHttpUtil.h"
#import "CMISAuthenticationProvider.h"
#import "CMISErrors.h"
#import "CMISHttpRequest.h"
#import "CMISHttpDownloadRequest.h"
#import "CMISHttpUploadRequest.h"
#import "CMISRequest.h"
#import "CMISSessionParameters.h"
#import "CMISNetworkProvider.h"

@interface GDHttpUtil ()
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
@property (nonatomic, strong) GDCReadStream * inputStream;


- (void)prepareHeaders:(GDHttpRequest *)request;

- (NSData *)dataFromInput;

- (void)readFromBuffer:(GDDirectByteBuffer *)buffer;

- (void)prepareConnectionWithURL:(NSURL *)url
                         session:(CMISBindingSession *)session
                          method:(NSString *)httpMethod
                            body:(NSData *)body
                         headers:(NSDictionary *)headers
                     inputStream:(GDCReadStream *)inputStream
                    outputStream:(GDCWriteStream *)outputStream
                   bytesExpected:(unsigned long long)expected
                 completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
                   progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

+ (NSString *)httpMethodString:(CMISHttpRequestMethod) requestMethod;
@end

@implementation GDHttpUtil
@synthesize httpRequest = _httpRequest;
@synthesize completionBlock = _completionBlock;
@synthesize requestBody = _requestBody;
@synthesize requestMethod = _requestMethod;
@synthesize headers = _headers;
@synthesize receivedData = _receivedData;
@synthesize authenticationHeader = _authenticationHeader;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize bytesExpected = _bytesExpected;
@synthesize progressBlock = _progressBlock;
@synthesize uploadData = _uploadData;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.httpRequest = [[GDHttpRequest alloc] init];
        self.httpRequest.delegate = self;
    }
    return self;
}


- (void)onStatusChange:(GDHttpRequest *)request
{
    GDHttpRequest_state_t requestState = [request getState];
    switch (requestState)
    {
        case GDHttpRequest_OPENED:
        {
            NSLog(@"GDHttpRequest_OPENED");
            [self prepareHeaders:request];
            
            BOOL sendSuccess = NO;
            if (self.requestBody)
            {
                sendSuccess = [request sendData:self.requestBody];
            }
            else if (self.inputStream)
            {
                self.uploadData = [self dataFromInput];
                if (nil == self.uploadData)
                {
                    NSLog(@"since we got no data - close the request again");
                    [request close];
                }
                else
                {
                    NSLog(@"The data content we want to send is %@",[[NSString alloc] initWithData:self.uploadData encoding:NSUTF8StringEncoding]);
                    sendSuccess = [request sendData:self.uploadData];
                }
            }
            else
            {
                sendSuccess = [request send];                
            }
            
            NSLog(@"GDHttpRequest_OPENED - after sending request. THe send request was %@",(sendSuccess ? @"successful" : @"not successful"));
            break;
        }
        case GDHttpRequest_DONE:
        {
            NSLog(@"GDHttpRequest_DONE");
            int statusCode = [request getStatus];
            const char * messageText = [request getStatusText];
            NSString *message = [[NSString alloc] initWithUTF8String:messageText];
            GDDirectByteBuffer *buffer = [request getReceiveBuffer];
            int bytesAvailable = buffer.bytesUnread;
            if (0 < bytesAvailable)
            {
                [self readFromBuffer:buffer];
            }
            if (200 <= statusCode && 299 >= statusCode)
            {
                NSLog(@"The HTTP request returns with HTTP ok status code %d",statusCode);
                if (self.receivedData)
                {
                    NSLog(@"The amount of data we get back is %d and content is %@",[self.receivedData length], [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding]);
                }
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
            self.completionBlock = nil;
            [request close];
            break;
        }
        case GDHttpRequest_HEADERS_RECEIVED:
        {
            if (!self.outputStream)
            {
                self.receivedData = [NSMutableData data];
            }
            const char * responseHeader = [request getAllResponseHeaders];
            NSString *response = [[NSString alloc] initWithUTF8String:responseHeader];
            NSLog(@"The response header message is %@", response);
            break;
        }
        case GDHttpRequest_LOADING:
        {
            GDDirectByteBuffer *buffer = [request getReceiveBuffer];
            [self readFromBuffer:buffer];
            break;
        }
        case GDHttpRequest_SENT:
            break;
        case GDHttpRequest_UNSENT:
            break;
        default:
            break;
    }
    
}


- (void)cancel
{
    if (self.httpRequest)
    {
        [self.httpRequest abort];
        self.completionBlock = nil;
    }
}


- (CMISRequest *)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
                   body:(NSData *)body
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    CMISRequest *cancelRequest = [[CMISRequest alloc] init];
    [self prepareConnectionWithURL:url
                           session:session
                            method:[GDHttpUtil httpMethodString:httpRequestMethod]
                              body:body
                           headers:additionalHeaders
                       inputStream:nil
                      outputStream:nil
                     bytesExpected:0
                   completionBlock:completionBlock
                     progressBlock:nil];
    
    cancelRequest.httpRequest = self;
    return cancelRequest;
}

- (CMISRequest *)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
            inputStream:(NSInputStream *)inputStream
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    CMISRequest *cancelRequest = [[CMISRequest alloc] init];

    [self prepareConnectionWithURL:url
                           session:session
                            method:[GDHttpUtil httpMethodString:httpRequestMethod]
                              body:nil
                           headers:additionalHeaders
                       inputStream:(GDCReadStream *)inputStream
                      outputStream:nil
                     bytesExpected:0
                   completionBlock:completionBlock
                     progressBlock:nil];
        
    cancelRequest.httpRequest = self;
    return cancelRequest;
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
    [self prepareConnectionWithURL:url
                           session:session
                            method:[GDHttpUtil httpMethodString:httpRequestMethod]
                              body:nil
                           headers:additionalHeaders
                       inputStream:(GDCReadStream *)inputStream
                      outputStream:nil
                     bytesExpected:bytesExpected
                   completionBlock:completionBlock
                     progressBlock:progressBlock];
    requestObject.httpRequest = self;
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
    [self prepareConnectionWithURL:url
                           session:session
                            method:[GDHttpUtil httpMethodString:httpRequestMethod]
                              body:nil
                           headers:nil
                       inputStream:nil
                      outputStream:(GDCWriteStream *)outputStream
                     bytesExpected:bytesExpected
                   completionBlock:completionBlock
                     progressBlock:progressBlock];
    requestObject.httpRequest = self;
}



- (CMISRequest *)invokeGET:(NSURL *)url
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

- (CMISRequest *)invokePOST:(NSURL *)url
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

- (CMISRequest *)invokePUT:(NSURL *)url
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

- (CMISRequest *)invokeDELETE:(NSURL *)url
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



#pragma private methods

- (void)prepareHeaders:(GDHttpRequest *)request
{
    NSLog(@"GDHttpUtil::prepareHeaders");
    NSLog(@"Authentication header");
    [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
        [request setRequestHeader:[key UTF8String] withValue:[value UTF8String]];
        NSLog(@"%@:%@",key,value);
    }];
    if (self.headers)
    {
        NSLog(@"Other headers");
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *headerName, NSString *header, BOOL *stop) {
            [request setRequestHeader:[headerName UTF8String] withValue:[header UTF8String]];
            NSLog(@"%@:%@",headerName,header);
        }];
        /*
        if ([self.requestMethod isEqualToString:@"POST"])
        {
            [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *headerName, NSString *header, BOOL *stop) {
                [request setPostValue:[header UTF8String] forKey:[headerName UTF8String]];
            }];
        }
        else
        {
            [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *headerName, NSString *header, BOOL *stop) {
                [request setRequestHeader:[headerName UTF8String] withValue:[header UTF8String]];
            }];
        }
         */
    }    
}

- (void)prepareConnectionWithURL:(NSURL *)url
                         session:(CMISBindingSession *)session
                          method:(NSString *)httpMethod
                            body:(NSData *)body
                         headers:(NSDictionary *)headers
                     inputStream:(GDCReadStream *)inputStream
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
    self.bytesExpected = expected;
    self.completionBlock = completionBlock;
    self.progressBlock = progressBlock;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    self.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];
    BOOL success = [self.httpRequest open:[self.requestMethod UTF8String] withUrl:[[url absoluteString] UTF8String] withAsync:YES];
    NSLog(@"GDHttpUtil::prepareConnectionWithURL request opened with URL %@",[url absoluteString]);
    if (success)
    {
        NSLog(@"We were able to create the httpRequest");
    }
    else
    {
        NSLog(@"We failed to create the httpRequest");
    }
}

- (NSData *)dataFromInput
{
    if (![self.inputStream hasBytesAvailable])
    {
        NSLog(@"No data are available in the input stream.");
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
            NSLog(@"bytes being read in is %d", readBytes);
            [uploadData appendBytes:(const void *)buffer length:readBytes];
            bytesRead += readBytes;
        }
    }
    NSLog(@"GDHttpUtil::dataFromInput Number of bytes being read from input stream is %d", bytesRead);
    return uploadData;    
}

- (void)readFromBuffer:(GDDirectByteBuffer *)buffer
{
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
