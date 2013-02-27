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

NSUInteger kBUFFERSIZE = 524280;//must be integer-divisible by 3
NSString * kHTTPSPACE = @" ";
NSString * kHTTPCRLF = @"\r\n";
NSString * kHTTPPROTOCOL = @"HTTP/1.1";
NSString * kHTTPHOST = @"Host: ";
NSString * kHTTPCODING = @"Transfer-Encoding: chunked";
NSString * kHTTPCONTENTLENGTH = @"Content-Length: ";
NSString * kHTTPCONNECTION = @"Connection: keep-alive";
NSString * kHTTPBASE64 = @"Content-Encoding: base64";
NSString * kHTTPLASTCHUNK = @"0\r\n";

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
+ (NSUInteger)base64EncodedLength:(NSUInteger)contentSize;
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
/**
 Ok - so this requires some explanation:
 The POST method requires a Content-length entry in the HTTP request header, where the content length is the number of bytes including the base 64 encoded content plus the XML headers.
 The base64 encoded data length can be calculated upfront, if the size of the content (e.g. file size) is known. I.e. if the bytesExpected value passed into the class is != 0.
 The size of the XML headers can also be calculated.
 
 In case we CAN calculate the size upfront, we write the data to the socket in 524280 sized buffers. Please note, whatever buffersize you choose, it must be divisible by 3 (size % 3 == 0). Otherwise you will write more base64 encoded data to the stream than you calculated for the Content-length HTTP header value. Why? Because base64 encoding will write 4 bytes for each 3, padding any extra bytes in case (size % 3 != 0)
 
 We also cater for the case where the file/content size is NOT known upfront. In this case we have no other option but load the content in memory so we can calculate the size, then write the HTTP request header, following by writing the buffer to the Socket stream. 
 */
- (void)onOpen:(CustomGDCMISSocketRequest *)currentSocket
{
    NSLog(@"CustomGDCMISSocketRequest:: onOpen");
    if (!self.receivedData)
    {
        self.receivedData = [NSMutableData data];
    }
    
    httpResponseMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    if (0 < self.bytesExpected)
    {
        NSData *xmlHeader = [CustomGDCMISSocketRequest xmlHeader:self.properties];
        NSData *xmlBodyOpen = [CustomGDCMISSocketRequest xmlBodyOpenElementsWithMimeType:self.mimeType];
        NSData *xmlBodyClose = [CustomGDCMISSocketRequest xmlBodyCloseElements];
        NSData *xmlProperties = [CustomGDCMISSocketRequest xmlProperties:self.properties];
        
        NSUInteger length = xmlHeader.length + xmlBodyClose.length + xmlBodyOpen.length + xmlProperties.length;
        NSUInteger realLength = length;

        length += [CustomGDCMISSocketRequest base64EncodedLength:self.bytesExpected];
        NSString *header = [self headerWithContentLength:length];
        NSLog(@"CustomGDCMISSocketRequest:: onOpen - we are expected to write %d bytes to the stream", length);
        [currentSocket.writeStream write:[header UTF8String]];
        [currentSocket write];
        
        [currentSocket.writeStream writeData:xmlHeader];
        [currentSocket.writeStream writeData:xmlBodyOpen];
        [currentSocket write];
        
        while ([self.inputStream hasBytesAvailable])
        {
            @autoreleasepool
            {
                uint8_t buffer[kBUFFERSIZE];
                NSInteger bytes = [self.inputStream read:buffer maxLength:kBUFFERSIZE];
                if (0 < bytes)
                {
                    NSData *chunkData = [NSData dataWithBytes:buffer length:bytes];
                    NSData *encoded = [CMISBase64Encoder dataByEncodingText:chunkData];
                    [currentSocket.writeStream writeData:encoded];
                    [currentSocket write];
                    realLength += encoded.length;
                }
            }
        }
                
        [currentSocket.writeStream writeData:xmlBodyClose];
        [currentSocket.writeStream writeData:xmlProperties];
        [currentSocket write];
        NSLog(@"CustomGDCMISSocketRequest:: onOpen - we have written  %d bytes to the stream", realLength);

        if (length > realLength)
        {
            NSUInteger diff = length - realLength;
            for (int i = 0; i < diff; ++i)
            {
                [currentSocket.writeStream write:[kHTTPSPACE UTF8String]];
            }
        }
        [currentSocket write];
        
    }
    else
    {
        NSMutableData *requestMessageData = [NSMutableData data];
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlHeader:self.properties]];
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlBodyOpenElementsWithMimeType:self.mimeType]];
        while ([self.inputStream hasBytesAvailable])
        {
            @autoreleasepool
            {
                const NSUInteger bufferSize = kBUFFERSIZE;
                uint8_t buffer[bufferSize];
                NSInteger bytes = [self.inputStream read:buffer maxLength:bufferSize];
                if (0 < bytes)
                {
                    NSData *chunkData = [NSData dataWithBytes:buffer length:bytes];
                    NSData *encoded = [CMISBase64Encoder dataByEncodingText:chunkData];
                    [requestMessageData appendData:encoded];
                }
            }
        }
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlBodyCloseElements]];
        [requestMessageData appendData:[CustomGDCMISSocketRequest xmlProperties:self.properties]];
        
        NSUInteger messageLength = requestMessageData.length;
        NSString *header = [self headerWithContentLength:messageLength];
        [currentSocket.writeStream write:[header UTF8String]];
        [currentSocket.writeStream writeData:requestMessageData];
        [currentSocket write];        
    }
    
    
}

+ (NSUInteger)base64EncodedLength:(NSUInteger)contentSize
{
    if (0 == contentSize)
    {
        return 0;
    }
    NSUInteger adjustedThirdPartOfSize = (contentSize / 3) + ( (0 == contentSize % 3 ) ? 0 : 1 );
    
    return 4 * adjustedThirdPartOfSize;
}


- (void)onRead:(CustomGDCMISSocketRequest *)currentSocket
{
    NSData *returnedData = [currentSocket.readStream unreadData];
    NSLog(@"CustomGDCMISSocketRequest:: onRead - reading in %d bytes", returnedData.length);
    
    const unsigned char *bytes = [returnedData bytes];
    
    if (!CFHTTPMessageAppendBytes(httpResponseMessage, bytes, returnedData.length))
    {
        NSLog(@"we got an error appending the bytes to the http message");
    }
}

- (void)onClose:(CustomGDCMISSocketRequest *)currentSocket
{
    NSLog(@"CustomGDCMISSocketRequest:: onClose");
    UInt32 statusCode_32;
    CFDataRef serializedData;
    CFStringRef statusline;
    if (CFHTTPMessageIsHeaderComplete(httpResponseMessage))
    {
        statusCode_32 =  CFHTTPMessageGetResponseStatusCode(httpResponseMessage);
        statusline = CFHTTPMessageCopyResponseStatusLine(httpResponseMessage);
        serializedData = CFHTTPMessageCopyBody(httpResponseMessage);
        NSData *data = (__bridge_transfer NSData*)serializedData;
        [self.receivedData appendData:data];
    }
    
    NSString *responseDataString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
    NSArray *crlfComponents = [responseDataString componentsSeparatedByString:kHTTPCRLF];
    NSMutableData *cleanedData = [NSMutableData data];
    for (int i = 0 ; i < crlfComponents.count; ++i)
    {
        NSString *resultingString = [crlfComponents objectAtIndex:i];
        if (1 == i % 2)
        {
            [cleanedData appendData:[resultingString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    NSLog(@"Received data are %@", [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding]);
    
    
    NSString *statusMessage = (__bridge_transfer NSString *)statusline;
    if (nil == statusMessage)
    {
        statusMessage = @"No message given";
    }
    if (200 <= statusCode_32 && 299 >= statusCode_32)
    {
        NSLog(@"The statusCode is %ld",statusCode_32);
        CMISHttpResponse * httpResponse = [CMISHttpResponse responseWithStatusCode:statusCode_32 statusMessage:statusMessage headers:nil responseData:cleanedData];
        self.completionBlock(httpResponse, nil);
    }
    else
    {
//        NSLog(@"We get a error as HTTP status: %ld and message %@", statusCode_32, statusMessage);
        NSError * error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeFilterNotValid
                                      detailedDescription:@"An error occurred on the socket"];
        self.completionBlock(nil, error);
        
    }
    
    [currentSocket disconnect];
    self.completionBlock = nil;
    
}

- (void)onErr:(int)errorCode inSocket:(CustomGDCMISSocketRequest *)currentSocket
{
    NSError * error = [CMISErrors createCMISErrorWithCode:kCMISErrorCodeFilterNotValid
                                  detailedDescription:[NSString stringWithFormat:@"GDSocket fired error with code %d",errorCode]];
    self.completionBlock(nil, error);
    self.completionBlock = nil;    
}

#pragma private methods

- (NSString *)headerForRequest
{
    NSMutableString *requestHeader = [NSMutableString stringWithString:self.requestMethod];
    [requestHeader appendString:kHTTPSPACE];
    [requestHeader appendString:self.serviceApi];
    [requestHeader appendString:kHTTPSPACE];
    [requestHeader appendString:kHTTPPROTOCOL];
    [requestHeader appendString:kHTTPCRLF];
    
    if (self.authenticationHeader)
    {
        [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:kHTTPCRLF];
        }];
    }
    if (self.headers)
    {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:kHTTPCRLF];
        }];
    }
    [requestHeader appendString:kHTTPHOST];
    [requestHeader appendString:self.host];
    [requestHeader appendString:kHTTPCRLF];
    
    [requestHeader appendString:@"Accept: */*"];
    [requestHeader appendString:kHTTPCRLF];
    [requestHeader appendString:kHTTPCODING];
    [requestHeader appendString:kHTTPCRLF];
    [requestHeader appendString:kHTTPCRLF];
    return (NSString *)requestHeader;
}

- (NSString *)headerWithContentLength:(NSUInteger)lengthInBytes
{
    NSMutableString *requestHeader = [NSMutableString stringWithString:self.requestMethod];
    [requestHeader appendString:kHTTPSPACE];
    [requestHeader appendString:self.serviceApi];
    [requestHeader appendString:kHTTPSPACE];
    [requestHeader appendString:kHTTPPROTOCOL];
    [requestHeader appendString:kHTTPCRLF];
    
    if (self.authenticationHeader)
    {
        [self.authenticationHeader enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:kHTTPCRLF];
        }];
    }
    if (self.headers)
    {
        [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [requestHeader appendString:[NSString stringWithFormat:@"%@: %@", key, value]];
            [requestHeader appendString:kHTTPCRLF];
        }];
    }
    [requestHeader appendString:kHTTPHOST];
    [requestHeader appendString:self.host];
    [requestHeader appendString:kHTTPCRLF];
    
    [requestHeader appendString:@"Accept: */*"];
    [requestHeader appendString:kHTTPCRLF];
    [requestHeader appendString:kHTTPBASE64];
    [requestHeader appendString:kHTTPCRLF];
    NSString *lengthString = [NSString stringWithFormat:@"%@%d", kHTTPCONTENTLENGTH, lengthInBytes];
    [requestHeader appendString:lengthString];
    [requestHeader appendString:kHTTPCRLF];
    [requestHeader appendString:kHTTPCRLF];
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
