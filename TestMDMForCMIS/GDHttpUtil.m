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
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, assign) NSString * requestMethod;
@property (nonatomic, copy) void (^completionBlock)(CMISHttpResponse *httpResponse, NSError *error);
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSDictionary *authenticationHeader;
- (void)prepareConnectionWithURL:(NSURL *)url
                      httpMethod:(CMISHttpRequestMethod)method
                         session:(CMISBindingSession *)session
                            body:(NSData *)bodyData
                         headers:(NSDictionary *)headers
                 completionBlock:(void (^)(CMISHttpResponse *, NSError *))completionBlock;
+ (NSString *)httpMethodString:(CMISHttpRequestMethod) requestMethod;
@end

@implementation GDHttpUtil
@synthesize httpRequest = _httpRequest;
@synthesize completionBlock = _completionBlock;
@synthesize requestBody = _requestBody;
@synthesize requestMethod = _requestMethod;
@synthesize headers = _headers;
@synthesize receivedData = _receivedData;
@synthesize authenticationHeader = _authenticationHeader;- (id)init
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
            [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
                [request setRequestHeader:[key UTF8String] withValue:[value UTF8String]];
            }];
            if (self.headers)
            {
                
            }
            [request send];
            NSLog(@"GDHttpRequest_OPENED - after sending request");
            break;
        }
        case GDHttpRequest_DONE:
        {
            NSLog(@"GDHttpRequest_DONE");
            int statusCode = [request getStatus];
            const char * messageText = [request getStatusText];
            NSString *message = [[NSString alloc] initWithUTF8String:messageText];
            if (200 <= statusCode && 299 >= statusCode)
            {
                NSLog(@"The HTTP request returns with HTTP status code ok, i.e. within 200-299");
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
            break;
        }
        case GDHttpRequest_HEADERS_RECEIVED:
            break;
        case GDHttpRequest_LOADING:
            break;
        case GDHttpRequest_SENT:
            break;
        case GDHttpRequest_UNSENT:
            break;
        default:
            break;
    }
    
}

- (void)prepareConnectionWithURL:(NSURL *)url
                      httpMethod:(CMISHttpRequestMethod)method
                         session:(CMISBindingSession *)session
                            body:(NSData *)bodyData
                         headers:(NSDictionary *)headers
                 completionBlock:(void (^)(CMISHttpResponse *, NSError *))completionBlock
{
    self.requestMethod = [GDHttpUtil httpMethodString:method];
    self.completionBlock = completionBlock;
    self.requestBody = bodyData;
    self.headers = headers;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    self.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];
    BOOL success = [self.httpRequest open:[self.requestMethod UTF8String] withUrl:[[url absoluteString] UTF8String] withAsync:YES];
    if (success)
    {
        NSLog(@"We were able to create the httpRequest");
    }
    else
    {
        NSLog(@"We failed to create the httpRequest");
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

+ (CMISRequest *)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
                   body:(NSData *)body
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    CMISRequest *cancelRequest = [[CMISRequest alloc] init];
    GDHttpUtil *httpUtil = [[GDHttpUtil alloc] init];
    [httpUtil prepareConnectionWithURL:url httpMethod:httpRequestMethod session:session body:body headers:additionalHeaders completionBlock:completionBlock];
    cancelRequest.httpRequest = httpUtil;
    return cancelRequest;
}

+ (CMISRequest *)invoke:(NSURL *)url
         withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
            withSession:(CMISBindingSession *)session
            inputStream:(NSInputStream *)inputStream
                headers:(NSDictionary *)additionalHeaders
        completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
{
    CMISRequest *cancelRequest = [[CMISRequest alloc] init];
    GDHttpUtil *httpUtil = [[GDHttpUtil alloc] init];
    
    cancelRequest.httpRequest = httpUtil;
    return cancelRequest;
}


+ (void)invoke:(NSURL *)url
withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
   inputStream:(NSInputStream *)inputStream
       headers:(NSDictionary *)additionalHeaders
 bytesExpected:(unsigned long long)bytesExpected
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
 requestObject:(CMISRequest *)requestObject
{
    GDHttpUtil *httpUtil = [[GDHttpUtil alloc] init];
    requestObject.httpRequest = httpUtil;
}

+ (void)invoke:(NSURL *)url
withHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
   withSession:(CMISBindingSession *)session
  outputStream:(NSOutputStream *)outputStream
 bytesExpected:(unsigned long long)bytesExpected
completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
 progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
 requestObject:(CMISRequest*)requestObject
{
    GDHttpUtil *httpUtil = [[GDHttpUtil alloc] init];
    requestObject.httpRequest = httpUtil;    
}



+ (CMISRequest *)invokeGET:(NSURL *)url
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

+ (CMISRequest *)invokePOST:(NSURL *)url
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

+ (CMISRequest *)invokePUT:(NSURL *)url
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

+ (CMISRequest *)invokeDELETE:(NSURL *)url
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
