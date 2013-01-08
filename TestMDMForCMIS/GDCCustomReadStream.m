//
//  GDCCustomReadStream.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 21/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "GDCCustomReadStream.h"
#import <objc/runtime.h>

@interface GDCCustomReadStream ()
{
	CFReadStreamClientCallBack copiedCallback;
	CFStreamClientContext copiedContext;
	CFOptionFlags requestedEvents;
}
@property (nonatomic, strong) GDCReadStream * parentStream;
@property (nonatomic, assign) NSStreamStatus streamStatus;
@property (nonatomic, weak) id<NSStreamDelegate> delegate;
- (id)initWithFile:(NSString *)filePathName;
@end

@implementation GDCCustomReadStream
@synthesize delegate = _delegate;
@synthesize streamStatus = _streamStatus;

+ (id)inputStreamWithFileAtPath:(NSString *)filePath
{
    GDCCustomReadStream *readStream = [[GDCCustomReadStream alloc] initWithFile:filePath];
    return readStream;
}

- (id)initWithFile:(NSString *)filePathName
{
    self = [super initWithFile:filePathName];
    if (nil != self)
    {
        _delegate = self;
        _streamStatus = NSStreamStatusNotOpen;
    }
    return self;
}

- (void)open
{
//    [super open];
    _streamStatus = NSStreamStatusOpen;
}

- (void)close
{
//    [super close];
    _streamStatus = NSStreamStatusClosed;
}

- (id<NSStreamDelegate>)delegate
{
    return _delegate;
}

- (void)setDelegate:(id<NSStreamDelegate>)delegate
{
    if (nil == delegate)
    {
        _delegate = self;
    }
    else
    {
        _delegate = delegate;
    }
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    //do we need an extra run loop? Let's try without
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    //do we need an extra run loop? Let's try without
}


#pragma Private methods based on CFReadStream. These are not provided by GDCReadStream
- (void)_scheduleInCFRunLook:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode
{
    //do we need an extra run loop? Let's try without
}

- (BOOL)_setCFClientFlags:(CFOptionFlags)flags callback:(CFReadStreamClientCallBack)callback context:(CFStreamClientContext*)context
{
    if (NULL != callback)
    {
        requestedEvents = flags;
        copiedCallback = callback;
        memcpy(&copiedContext, context, sizeof(CFStreamClientContext));
        if (copiedContext.info && copiedContext.retain)
        {
            copiedContext.retain(copiedContext.info);
        }
    }
    else
    {
        requestedEvents = kCFStreamEventNone;
        copiedCallback = NULL;
        if (copiedContext.info && copiedContext.retain)
        {
            copiedContext.retain(copiedContext.info);
        }
        memset(&copiedContext, 0, sizeof(CFStreamClientContext));
    }
    return YES;
}

- (void)_unscheduleInCFRunLook:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode
{
    //do we need an extra run loop? Let's try without    
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
	
	assert(aStream == self);
	
	switch (eventCode) {
		case NSStreamEventOpenCompleted:
			if (requestedEvents & kCFStreamEventOpenCompleted) {
				copiedCallback((__bridge CFReadStreamRef)self,
							   kCFStreamEventOpenCompleted,
							   copiedContext.info);
			}
			break;
			
		case NSStreamEventHasBytesAvailable:
			if (requestedEvents & kCFStreamEventHasBytesAvailable) {
				copiedCallback((__bridge CFReadStreamRef)self,
							   kCFStreamEventHasBytesAvailable,
							   copiedContext.info);
			}
			break;
			
		case NSStreamEventErrorOccurred:
			if (requestedEvents & kCFStreamEventErrorOccurred) {
				copiedCallback((__bridge CFReadStreamRef)self,
							   kCFStreamEventErrorOccurred,
							   copiedContext.info);
			}
			break;
			
		case NSStreamEventEndEncountered:
			if (requestedEvents & kCFStreamEventEndEncountered) {
				copiedCallback((__bridge CFReadStreamRef)self,
							   kCFStreamEventEndEncountered,
							   copiedContext.info);
			}
			break;
			
		case NSStreamEventHasSpaceAvailable:
			// This doesn't make sense for a read stream
			break;
			
		default:
			break;
	}
}

- (void) notifyEvent:(CFStreamEventType) event
{
    if ( [_delegate respondsToSelector:@selector(stream:handleEvent:)] )
        [_delegate stream:self handleEvent:event];
    
    if ( copiedCallback && ( event & requestedEvents ) )
        copiedCallback((__bridge CFReadStreamRef) self, event, copiedContext.info);
}


@end
