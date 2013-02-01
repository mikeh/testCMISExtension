//
//  CustomGDCMISSocketRequest.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 31/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import "CustomGDCMISSocketRequest.h"
#import <CFNetwork/CFNetwork.h>
#import "CMISBase64Encoder.h"
#import "CMISConstants.h"
#import "CMISDateUtil.h"

NSString * HTTPSPACE = @" ";
NSString * HTTPCRLF = @"\r\n";
NSString * HTTPPROTOCOL = @"HTTP/1.1";
NSString * HTTPHOST = @"Host: ";
NSString * HTTPCODING = @"Transfer-Encoding: chunked";
NSString * HTTPCONTENTLENGTH = @"Content-Length: ";
NSString * HTTPCONNECTION = @"Connection: keep-alive";
NSString * HTTPBASE64 = @"Content-Encoding: base64";
NSString * HTTPLASTCHUNK = @"0\r\n";

@interface CustomGDCMISSocketRequest ()
{
    CFHTTPMessageRef httpResponseMessage;
}
@property (nonatomic, strong) NSString *requestMethod;
@property (nonatomic, strong) NSDictionary *authenticationHeader;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSString *serviceApi;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSInputStream * inputStream;
@property (nonatomic, copy) void (^completionBlock)(CMISHttpResponse *httpResponse, NSError *error);
@property (nonatomic, copy) void (^progressBlock)(unsigned long long bytesDownloaded, unsigned long long bytesTotal);
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) CMISProperties *properties;
@property NSUInteger bytesExpected;
- (NSString *)headerForRequest;
- (NSString *)headerWithContentLength:(NSUInteger)lengthInBytes;
+ (NSData *)xmlHeader:(CMISProperties *)properties;
+ (NSData *)xmlProperties:(CMISProperties *)properties;
+ (NSData *)xmlBodyOpenElementsWithMimeType:(NSString *)mimeType;
+ (NSData *)xmlBodyCloseElements;
+ (NSString *)extensionsFromChildren:(NSArray *)children;
- (NSUInteger)lengthOfEncodedStream;
@end


@implementation CustomGDCMISSocketRequest
@synthesize strongSocketDelegate = _strongSocketDelegate;
@synthesize requestMethod = _requestMethod;
@synthesize authenticationHeader = _authenticationHeader;
@synthesize headers = _headers;
@synthesize serviceApi = _serviceApi;
@synthesize host = _host;
@synthesize completionBlock = _completionBlock;
@synthesize progressBlock = _progressBlock;
@synthesize receivedData = _receivedData;
@synthesize inputStream = _inputStream;
@synthesize bytesExpected = _bytesExpected;

- (id)initWithHostName:(NSString *)hostName serviceAPI:(NSString *)serviceAPIString port:(int)port useSSL:(BOOL)useSSL
{
    self = [super init:[hostName UTF8String] onPort:port andUseSSL:useSSL];
    if (self != nil)
    {
        [self setDelegate:self];
        self.host = hostName;
        self.serviceApi = serviceAPIString;
    }
    return self;
}


- (void)setDelegate:(id<GDSocketDelegate>)httpDelegate
{
    [super setDelegate:httpDelegate];
    _strongSocketDelegate = [super delegate];
}

- (void)cancel
{
    [self disconnect];
}

- (void)prepareConnectionWithSession:(CMISBindingSession *)session
                              method:(NSString *)httpMethod
                             headers:(NSDictionary *)headers
                         inputStream:(NSInputStream *)inputStream
                       bytesExpected:(unsigned long long)expected
                            mimeType:(NSString *)mimeType
                          properties:(CMISProperties *)properties
                     completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
                       progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock
{
    self.requestMethod = httpMethod;
    self.headers = headers;
    self.inputStream = inputStream;
    self.completionBlock = completionBlock;
    self.progressBlock = progressBlock;
    self.mimeType = mimeType;
    self.properties = properties;
    self.bytesExpected = expected;
    id <CMISAuthenticationProvider> authenticationProvider = session.authenticationProvider;
    self.authenticationHeader = [NSDictionary dictionaryWithDictionary:authenticationProvider.httpHeadersToApply];

    [self connect];    
}


#pragma Socket Delegate methods

- (void)onOpen:(CustomGDCMISSocketRequest *)currentSocket
{
    NSLog(@"in onOpen. request method is %@ and serviceAPI is %@. The host is %@", self.requestMethod, self.serviceApi, self.host);
    if (!self.receivedData)
    {
        self.receivedData = [NSMutableData data];
    }
    /*
    
    httpResponseMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    NSString *header = [self headerForRequest];
    [currentSocket.writeStream write:[header UTF8String]];
    [currentSocket write];
    
    NSLog(@"The header is :\n%@", header);
    NSMutableData *requestMessageData = [NSMutableData data];
    [requestMessageData appendData:[CustomGDCMISSocketRequest xmlHeader:self.properties]];
    [requestMessageData appendData:[CustomGDCMISSocketRequest xmlBodyOpenElementsWithMimeType:self.mimeType]];

    NSString *hexLength = [NSString stringWithFormat:@"%x",requestMessageData.length];
    [currentSocket.writeStream write:[hexLength UTF8String]];
    [currentSocket.writeStream write:[HTTPCRLF UTF8String]];
    [currentSocket.writeStream writeData:requestMessageData];
    [currentSocket.writeStream write:[HTTPCRLF UTF8String]];
    [currentSocket write];
    while ([self.inputStream hasBytesAvailable])
    {
        NSMutableData *chunkData = [NSMutableData dataWithCapacity:8192];
        NSInteger bytes = [self.inputStream read:chunkData.mutableBytes maxLength:8192];
        if (0 < bytes)
        {
            [chunkData setLength:bytes];
            NSData *encoded = [CMISBase64Encoder dataByEncodingText:chunkData];
            hexLength = [NSString stringWithFormat:@"%x", encoded.length];
            NSLog(@"writing %@ (hex) bytes to chunk", hexLength);
            [currentSocket.writeStream write:[hexLength UTF8String]];
            [currentSocket.writeStream write:[HTTPCRLF UTF8String]];
            [currentSocket.writeStream writeData:encoded];
            [currentSocket.writeStream write:[HTTPCRLF UTF8String]];
            [currentSocket write];
        }
    }
    
    NSMutableData *bodyEndData = [NSMutableData data];
    [bodyEndData appendData:[CustomGDCMISSocketRequest xmlBodyCloseElements]];
    [bodyEndData appendData:[CustomGDCMISSocketRequest xmlProperties:self.properties]];
    hexLength = [NSString stringWithFormat:@"%x",bodyEndData.length];
    [currentSocket.writeStream write:[hexLength UTF8String]];
    [currentSocket.writeStream write:[HTTPCRLF UTF8String]];
    [currentSocket.writeStream writeData:bodyEndData];
    [currentSocket.writeStream write:[HTTPCRLF UTF8String]];
    [currentSocket.writeStream write:[HTTPLASTCHUNK UTF8String]];
    [currentSocket write];
     */
    
    if (0 < self.bytesExpected)
    {
        NSLog(@"***** WE ARE WRITING IN A BUFFERED MANNER. BYTE SIZE IS %d ******", self.bytesExpected);
        NSData *xmlHeader = [CustomGDCMISSocketRequest xmlHeader:self.properties];
        NSData *xmlBodyOpen = [CustomGDCMISSocketRequest xmlBodyOpenElementsWithMimeType:self.mimeType];
        NSData *xmlBodyClose = [CustomGDCMISSocketRequest xmlBodyCloseElements];
        NSData *xmlProperties = [CustomGDCMISSocketRequest xmlProperties:self.properties];
        
        NSUInteger length = xmlHeader.length + xmlBodyClose.length + xmlBodyOpen.length + xmlProperties.length;
        length += [self lengthOfEncodedStream];
        httpResponseMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
        NSString *header = [self headerWithContentLength:length];
        [currentSocket.writeStream write:[header UTF8String]];
        [currentSocket write];
        
        [currentSocket.writeStream writeData:xmlHeader];
        [currentSocket.writeStream writeData:xmlBodyOpen];
        [currentSocket write];
        
        while ([self.inputStream hasBytesAvailable])
        {
            const NSUInteger bufferSize = 8192;
            uint8_t buffer[bufferSize];
            NSInteger bytes = [self.inputStream read:buffer maxLength:bufferSize];
            if (0 < bytes)
            {
                NSData *chunkData = [NSData dataWithBytesNoCopy:buffer length:bytes];
                NSLog(@"**** read in data are %@ ****",[[NSString alloc] initWithData:chunkData encoding:NSUTF8StringEncoding]);
                NSData *encoded = [CMISBase64Encoder dataByEncodingText:chunkData];
                [currentSocket.writeStream writeData:encoded];
                [currentSocket write];
            }
        }
        
        
        [currentSocket.writeStream writeData:xmlBodyClose];
        [currentSocket.writeStream writeData:xmlProperties];
        [currentSocket write];
        
        
    }
    else
    {
        NSLog(@"<<<<<<<<< WE ARE WRITING THE WHOLE LOT IN ONE GO >>>>>>>>");
        NSMutableData *requestMessageData = [NSMutableData data];
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlHeader:self.properties]];
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlBodyOpenElementsWithMimeType:self.mimeType]];
        while ([self.inputStream hasBytesAvailable])
        {
            const NSUInteger bufferSize = 8192;
            uint8_t buffer[bufferSize];
            NSInteger bytes = [self.inputStream read:buffer maxLength:bufferSize];
            if (0 < bytes)
            {
                NSData *chunkData = [NSData dataWithBytesNoCopy:buffer length:bytes];
                NSData *encoded = [CMISBase64Encoder dataByEncodingText:chunkData];
                [requestMessageData appendData:encoded];
            }
        }
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlBodyCloseElements]];
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlProperties:self.properties]];
        
        NSUInteger messageLength = requestMessageData.length;
        httpResponseMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
        NSString *header = [self headerWithContentLength:messageLength];
        [currentSocket.writeStream write:[header UTF8String]];
        [currentSocket.writeStream writeData:requestMessageData];
        [currentSocket write];        
    }
    
    
}

- (NSUInteger)lengthOfEncodedStream
{
    if (0 == self.bytesExpected)
    {
        return 0;
    }
    NSUInteger length = (4 * ((self.bytesExpected / 3) + (1 - (3 - (self.bytesExpected % 3)) / 3)));
    return length;
}


- (void)onRead:(CustomGDCMISSocketRequest *)currentSocket
{
    NSLog(@"in onRead");
    NSData *returnedData = [currentSocket.readStream unreadData];
    
    const unsigned char *bytes = [returnedData bytes];
    
    if (!CFHTTPMessageAppendBytes(httpResponseMessage, bytes, returnedData.length))
    {
        NSLog(@"we got an error appending the bytes to the http message");
    }
    else
    {
        NSLog(@"We are appending %d bytes to the buffer",returnedData.length);
    }    
}

- (void)onClose:(CustomGDCMISSocketRequest *)currentSocket
{
    UInt32 statusCode_32;
    CFDataRef serializedData;
    CFStringRef statusline;
    if (CFHTTPMessageIsHeaderComplete(httpResponseMessage))
    {
        statusCode_32 =  CFHTTPMessageGetResponseStatusCode(httpResponseMessage);
        statusline = CFHTTPMessageCopyResponseStatusLine(httpResponseMessage);
        NSLog(@"message header is complete and the status code is %ld", statusCode_32);
        serializedData = CFHTTPMessageCopyBody(httpResponseMessage);
        NSData *data = (__bridge_transfer NSData*)serializedData;
        [self.receivedData appendData:data];
    }
    
    NSString *responseDataString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
    NSArray *crlfComponents = [responseDataString componentsSeparatedByString:HTTPCRLF];
    NSLog(@"THe number of crlf components is %d",crlfComponents.count);
    NSMutableData *cleanedData = [NSMutableData data];
    for (int i = 0 ; i < crlfComponents.count; ++i)
    {
        NSString *resultingString = [crlfComponents objectAtIndex:i];
        if (1 == i % 2)
        {
            [cleanedData appendData:[resultingString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    NSLog(@"the cleaned string is :\n%@",[[NSString alloc] initWithData:cleanedData encoding:NSUTF8StringEncoding]);
    
    NSString *statusMessage = (__bridge_transfer NSString *)statusline;
//    NSLog(@"in onClose. The amount of data we received is %d. The data string is\n %@", self.receivedData.length, [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding]);
    
    if (200 <= statusCode_32 && 299 >= statusCode_32)
    {
        CMISHttpResponse * httpResponse = [CMISHttpResponse responseWithStatusCode:statusCode_32 statusMessage:statusMessage headers:nil responseData:cleanedData];
        self.completionBlock(httpResponse, nil);
    }
    else
    {
        NSLog(@"We get a error as HTTP status: %ld and message %@", statusCode_32, statusMessage);
        NSError * error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeFilterNotValid
                                      withDetailedDescription:statusMessage];
        self.completionBlock(nil, error);
        
    }
    
    [currentSocket disconnect];
    self.completionBlock = nil;
    
}

- (void)onErr:(int)errorCode inSocket:(CustomGDCMISSocketRequest *)currentSocket
{
    NSError * error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeFilterNotValid
                                  withDetailedDescription:[NSString stringWithFormat:@"GDSocket fired error with code %d",errorCode]];
    self.completionBlock(nil, error);
    self.completionBlock = nil;    
}

#pragma private methods

- (NSString *)headerForRequest
{
    NSMutableString *requestHeader = [NSMutableString stringWithString:self.requestMethod];
    [requestHeader appendString:HTTPSPACE];
    [requestHeader appendString:self.serviceApi];
    [requestHeader appendString:HTTPSPACE];
    [requestHeader appendString:HTTPPROTOCOL];
    [requestHeader appendString:HTTPCRLF];
    
    if (self.authenticationHeader)
    {
        [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:HTTPCRLF];
        }];
    }
    if (self.headers)
    {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:HTTPCRLF];
        }];
    }
    [requestHeader appendString:HTTPHOST];
    [requestHeader appendString:self.host];
    [requestHeader appendString:HTTPCRLF];
    
    [requestHeader appendString:@"Accept: */*"];
    [requestHeader appendString:HTTPCRLF];
//    [requestHeader appendString:HTTPCONNECTION];
//    [requestHeader appendString:HTTPCRLF];
    [requestHeader appendString:HTTPCODING];
    [requestHeader appendString:HTTPCRLF];
    [requestHeader appendString:HTTPCRLF];
    return (NSString *)requestHeader;
}

- (NSString *)headerWithContentLength:(NSUInteger)lengthInBytes
{
    NSMutableString *requestHeader = [NSMutableString stringWithString:self.requestMethod];
    [requestHeader appendString:HTTPSPACE];
    [requestHeader appendString:self.serviceApi];
    [requestHeader appendString:HTTPSPACE];
    [requestHeader appendString:HTTPPROTOCOL];
    [requestHeader appendString:HTTPCRLF];
    
    if (self.authenticationHeader)
    {
        [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:HTTPCRLF];
        }];
    }
    if (self.headers)
    {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:HTTPCRLF];
        }];
    }
    [requestHeader appendString:HTTPHOST];
    [requestHeader appendString:self.host];
    [requestHeader appendString:HTTPCRLF];
    
    [requestHeader appendString:@"Accept: */*"];
    [requestHeader appendString:HTTPCRLF];
    [requestHeader appendString:HTTPBASE64];
    [requestHeader appendString:HTTPCRLF];
    NSString *lengthString = [NSString stringWithFormat:@"%@%d", HTTPCONTENTLENGTH, lengthInBytes];
    [requestHeader appendString:lengthString];
    [requestHeader appendString:HTTPCRLF];
    [requestHeader appendString:HTTPCRLF];
    return (NSString *)requestHeader;
}



+ (NSData *)xmlHeader:(CMISProperties *)properties
{
    NSString *atomEntryXmlStart = [NSString stringWithFormat:
                                   @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                                   "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\"  >"
                                   "<id>urn:uuid:00000000-0000-0000-0000-00000000000</id>"
                                   "<title>%@</title>",
                                   [properties propertyValueForId:kCMISPropertyName]];
    return [atomEntryXmlStart dataUsingEncoding:NSUTF8StringEncoding];    
}

+ (NSData *)xmlProperties:(CMISProperties *)properties
{
    NSMutableString *propertiesString = [NSMutableString stringWithString:@"<cmisra:object><cmis:properties>"];
    
    // TODO: support for multi valued properties
    for (id propertyKey in properties.propertiesDictionary)
    {
        CMISPropertyData *propertyData = [properties propertyForId:propertyKey];
        switch (propertyData.type)
        {
            case CMISPropertyTypeString:
            {
                [propertiesString appendString:[NSString stringWithFormat:@"<cmis:propertyString propertyDefinitionId=\"%@\"><cmis:value>%@</cmis:value></cmis:propertyString>",
                                                propertyData.identifier, propertyData.propertyStringValue]];
                break;
            }
            case CMISPropertyTypeInteger:
            {
                [propertiesString appendString:[NSString stringWithFormat:@"<cmis:propertyInteger propertyDefinitionId=\"%@\"><cmis:value>%d</cmis:value></cmis:propertyInteger>",
                                                propertyData.identifier, propertyData.propertyIntegerValue.intValue]];
                break;
            }
            case CMISPropertyTypeBoolean:
            {
                [propertiesString appendString:[NSString stringWithFormat:@"<cmis:propertyBoolean propertyDefinitionId=\"%@\"><cmis:value>%@</cmis:value></cmis:propertyBoolean>",
                                                propertyData.identifier,
                                                [propertyData.propertyBooleanValue isEqualToNumber:[NSNumber numberWithBool:YES]] ? @"true" : @"false"]];
                break;
            }
            case CMISPropertyTypeId:
            {
                [propertiesString appendString:[NSString stringWithFormat:@"<cmis:propertyId propertyDefinitionId=\"%@\"><cmis:value>%@</cmis:value></cmis:propertyId>",
                                                propertyData.identifier, propertyData.propertyIdValue]];
                break;
            }
            case CMISPropertyTypeDateTime:
            {
                [propertiesString appendString:[NSString stringWithFormat:@"<cmis:propertyDateTime propertyDefinitionId=\"%@\"><cmis:value>%@</cmis:value></cmis:propertyDateTime>",
                                                propertyData.identifier, [CMISDateUtil stringFromDate:propertyData.propertyDateTimeValue]]];
                break;
            }
            default:
            {
                NSLog(@"Property type did not match: %u", propertyData.type);
                break;
            }
        }
    }
    
    // Add extensions to properties
    if (properties.extensions != nil)
    {
        NSString *extensions = [CustomGDCMISSocketRequest extensionsFromChildren:properties.extensions];
        [propertiesString appendString:extensions];
    }
    [propertiesString appendString:@"</cmis:properties></cmisra:object></entry>"];
    
    return [propertiesString dataUsingEncoding:NSUTF8StringEncoding];
    
}

+ (NSData *)xmlBodyOpenElementsWithMimeType:(NSString *)mimeType
{
    NSString *contentXMLStart = [NSString stringWithFormat:@"<cmisra:content><cmisra:mediatype>%@</cmisra:mediatype><cmisra:base64>", mimeType];
    return [contentXMLStart dataUsingEncoding:NSUTF8StringEncoding];    
}

+ (NSData *)xmlBodyCloseElements
{
    NSString *contentXMLEnd = @"</cmisra:base64></cmisra:content>";
    return [contentXMLEnd dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)extensionsFromChildren:(NSArray *)children
{
    NSMutableString *propertiesExtensionString = [NSMutableString string];
    
    for (CMISExtensionElement *extensionElement in children)
    {
        [propertiesExtensionString appendString:[NSString stringWithFormat:@"<%@ xmlns=\"%@\"", extensionElement.name, extensionElement.namespaceUri]];
        // Opening XML tag
        
        // Attributes
        if (extensionElement.attributes != nil)
        {
            for (NSString *attributeName in extensionElement.attributes)
            {
                [propertiesExtensionString appendString:[NSString stringWithFormat:@" %@=\"%@\"", attributeName, [extensionElement.attributes objectForKey:attributeName]]];
            }
        }
        [propertiesExtensionString appendString:@">"];
        
        // Value
        if (extensionElement.value != nil)
        {
            [propertiesExtensionString appendString:extensionElement.value];
        }
        
        // Children
        if (extensionElement.children != nil && extensionElement.children.count > 0)
        {
            NSString *childExtension = [CustomGDCMISSocketRequest extensionsFromChildren:extensionElement.children];
            [propertiesExtensionString appendString:childExtension];
        }
        // Closing XML tag
        [propertiesExtensionString appendString:[NSString stringWithFormat:@"</%@>", extensionElement.name]];
    }
    
    return propertiesExtensionString;
    
}


@end
