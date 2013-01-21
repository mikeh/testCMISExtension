//
//  GDHttpUtilWithSockets.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 21/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import "GDHttpUtilWithSockets.h"
#import "CMISAuthenticationProvider.h"
#import "CMISErrors.h"
#import "CMISHttpRequest.h"
#import "CMISHttpDownloadRequest.h"
#import "CMISHttpUploadRequest.h"
#import "CMISRequest.h"
#import "CMISSessionParameters.h"
#import "CMISNetworkProvider.h"

@interface GDHttpUtilWithSockets ()
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
+ (NSString *)httpMethodString:(CMISHttpRequestMethod) requestMethod;
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
- (void)prepareHeaders;
- (NSData *)dataFromInput;
- (void)readFromBuffer:(GDDirectByteBuffer *)buffer;
@end

@implementation GDHttpUtilWithSockets
@synthesize socket = _socket;
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

#pragma custom initialisers
- (id)initWithURLString:(NSString *)urlString
{
    return [self initWithURLString:urlString port:443 isSSL:YES];
}


- (id)initWithURLString:(NSString *)urlString port:(NSUInteger)port isSSL:(BOOL)isSSL
{
    self = [super init];
    if (nil != self)
    {
        self.socket = [[GDSocket alloc] init:[urlString UTF8String] onPort:port andUseSSL:isSSL];
        self.socket.delegate = self;
    }
    return self;
}

#pragma custom cancel method needed for CMISRequest
- (void)cancel
{
    if (self.socket)
    {
        [self.socket disconnect];
    }
    self.completionBlock = nil;    
}


#pragma CMISHttpInvokerDelegate methods

- (CMISRequest *)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
                   body:(NSData *)body
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return nil;
}

- (CMISRequest *)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
            inputStream:(NSInputStream *)inputStream
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    return nil;
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

#pragma GDSocketDelegate methods
- (void)onClose:(id)socket
{
    
}

- (void)onErr:(int)error inSocket:(id)socket
{
    
}

- (void)onOpen:(id)socket
{
    
}

- (void)onRead:(id)socket
{
    
}

#pragma private methods

- (void)prepareHeaders
{
    
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
    //    [uploadData appendBytes:(const void *)nullBuffer length:1];
    //    bytesRead++;
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
            NSLog(@"failed to write data");
        }
        else
        {
            NSLog(@"We have written %d bytes to output stream", bytesWritten);
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
