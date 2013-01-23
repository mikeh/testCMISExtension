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
@property (nonatomic, strong) NSString *urlString;
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

- (void)prepareWithURLString:(NSString *)urlString;
- (void)prepareWithURLString:(NSString *)urlString port:(NSUInteger)port isSSL:(BOOL)isSSL;

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
- (NSString *)preparedHeaders;
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
@synthesize urlString = _urlString;
@synthesize httpListDelegate = _httpListDelegate;
#pragma custom initialisers
- (void)prepareWithURLString:(NSString *)urlString
{
    [self prepareWithURLString:urlString port:443 isSSL:YES];
}


- (void)prepareWithURLString:(NSString *)urlString port:(NSUInteger)port isSSL:(BOOL)isSSL
{
    NSString *httpSeparator = @"http://";
    if ([urlString hasPrefix:@"https://"])
    {
        httpSeparator = @"https://";
    }
    NSArray *hostComponents = [self.urlString componentsSeparatedByString:httpSeparator];
    if (hostComponents.count <= 1)
    {
        return;
    }
    NSString *bareUrl = (NSString *)[hostComponents objectAtIndex:1];
    NSArray *restComponents = [bareUrl componentsSeparatedByString:@"/alfresco"];
    if (restComponents.count <= 1)
    {
        return;
    }
    NSString *host = [restComponents objectAtIndex:0];
    NSLog(@"the bare URL is %@", host);
    self.socket = [[GDSocket alloc] init:[host UTF8String] onPort:port andUseSSL:isSSL];
    self.socket.delegate = self;
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

- (void)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
                   body:(NSData *)body
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    [self prepareConnectionWithURL:url
                           session:session
                            method:[GDHttpUtilWithSockets httpMethodString:httpRequestMethod]
                              body:body
                           headers:additionalHeaders
                       inputStream:nil
                      outputStream:nil
                     bytesExpected:0
                   completionBlock:completionBlock
                     progressBlock:nil];
    
    NSString *urlString = [url absoluteString];
    [self prepareWithURLString:urlString port:80 isSSL:NO];
    [self.socket connect];
}

- (void)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
            inputStream:(NSInputStream *)inputStream
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    
    [self prepareConnectionWithURL:url
                           session:session
                            method:[GDHttpUtilWithSockets httpMethodString:httpRequestMethod]
                              body:nil
                           headers:additionalHeaders
                       inputStream:(GDCReadStream *)inputStream
                      outputStream:nil
                     bytesExpected:0
                   completionBlock:completionBlock
                     progressBlock:nil];
    
    NSString *urlString = [url absoluteString];
    [self prepareWithURLString:urlString port:80 isSSL:NO];
    [self.socket connect];
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
                            method:[GDHttpUtilWithSockets httpMethodString:httpRequestMethod]
                              body:nil
                           headers:additionalHeaders
                       inputStream:(GDCReadStream *)inputStream
                      outputStream:nil
                     bytesExpected:bytesExpected
                   completionBlock:completionBlock
                     progressBlock:progressBlock];
    requestObject.httpRequest = self;
    NSString *urlString = [url absoluteString];
    [self prepareWithURLString:urlString port:80 isSSL:NO];
    [self.socket connect];
    
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
                            method:[GDHttpUtilWithSockets httpMethodString:httpRequestMethod]
                              body:nil
                           headers:nil
                       inputStream:nil
                      outputStream:(GDCWriteStream *)outputStream
                     bytesExpected:bytesExpected
                   completionBlock:completionBlock
                     progressBlock:progressBlock];
    requestObject.httpRequest = self;
    NSString *urlString = [url absoluteString];
    [self prepareWithURLString:urlString port:80 isSSL:NO];
    [self.socket connect];
    
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

#pragma GDSocketDelegate methods
- (void)onClose:(id)socket
{
    NSLog(@"Closing connection");
    
}

- (void)onErr:(int)error inSocket:(GDSocket *)socket
{
    NSLog(@"An error occurred with code %d", error);
}

- (void)onOpen:(GDSocket *)socket
{
    NSLog(@"onOpen method");
    NSString *httpRequestHeader = [self preparedHeaders];
    NSLog(@"the http request header is:");
    NSLog(@"%@",httpRequestHeader);
    
    self.receivedData = [NSMutableData data];
    [socket.writeStream write:[httpRequestHeader UTF8String]];
    [socket write];
    NSLog(@"onOpen method - LEAVING");
}

- (void)onRead:(GDSocket *)socket
{
    NSData *received = [socket.readStream unreadData];
    [self.receivedData appendData:received];
    NSString *receivedByteString = [[NSString alloc] initWithData:received encoding:NSUTF8StringEncoding];
    NSLog(@"received string is %@",receivedByteString);
    [socket disconnect];
}

#pragma private methods

- (NSString *)preparedHeaders;
{
    if (!self.urlString)
    {
        return nil;
    }
    /*
     */
    NSString *httpSeparator = @"http://";
    if ([self.urlString hasPrefix:@"https://"])
    {
        httpSeparator = @"https://";
    }
    NSArray *hostComponents = [self.urlString componentsSeparatedByString:httpSeparator];
    if (hostComponents.count <= 1)
    {
        return nil;
    }
    NSString *bareUrl = [hostComponents objectAtIndex:1];
    NSArray *restComponents = [bareUrl componentsSeparatedByString:@"/alfresco"];
    if (restComponents.count <= 1)
    {
        return nil;
    }
    NSString *host = [NSString stringWithFormat:@"%@",[restComponents objectAtIndex:0]];
//    NSMutableString *apiString = [NSMutableString string];
    NSMutableString *apiString = [NSMutableString stringWithString:@"/alfresco"];
    for (int index = 1; index < restComponents.count; index++)
    {
        [apiString appendString:[restComponents objectAtIndex:index]];
    }
    NSMutableString *requestHeader = [NSMutableString string];
    
    [requestHeader appendString:[NSString stringWithFormat:@"%@ %@ HTTP/1.1 \n",self.requestMethod, apiString]];
    [requestHeader appendString:[NSString stringWithFormat:@"Host: %@\n",host]];
    [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
        [requestHeader appendString:[NSString stringWithFormat:@"%@: %@\n", key, value]];
    }];
    if (self.headers)
    {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *headerName, NSString *header, BOOL *stop) {
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@\n", headerName, header]];
        }];
    }

    
    return (NSString *)requestHeader;
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
    self.urlString = [url absoluteString];
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
