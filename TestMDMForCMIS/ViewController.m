//
//  ViewController.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 19/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "ViewController.h"
#import "CMISSession.h"
#import "CMISDocument.h"
#import "CMISFolder.h"
#import "CMISSessionParameters.h"
#import "TestCMISNetworkIO.h"
#import <objc/runtime.h>
//#import "GDCReadStream+InputStream.h"
#import "GDCCustomReadStream.h"
#import "GDCWriteStream+OutputStream.h"
#import "TestFileManager.h"
#import "TestBaseEncoder.h"
#import "CMISConstants.h"
#import <GD/GDFileSystem.h>


@interface ViewController ()
@property (nonatomic, strong) CMISSession * session;
@property (nonatomic, strong) CMISFolder *rootFolder;
@property (nonatomic, strong) NSString *testDocId;
- (NSString *)prepareTestFileForUpload;
@end

@implementation ViewController
@synthesize testCMISSessionButton = _testCMISSessionButton;
@synthesize session = _session;
@synthesize uploadButton = _uploadButton;
@synthesize removeButton = _removeButton;
@synthesize rootFolder = _rootFolder;
@synthesize downloadButton = _downloadButton;
@synthesize testDocId = _testDocId;
- (void)viewDidLoad
{
    NSLog(@"We are in viewDidLoad");
    [super viewDidLoad];
    
    self.uploadButton.enabled = NO;
    self.uploadButton.titleLabel.textColor = [UIColor lightGrayColor];
    self.removeButton.enabled = NO;
    self.removeButton.titleLabel.textColor = [UIColor lightGrayColor];
    self.downloadButton.enabled = NO;
    self.downloadButton.titleLabel.textColor = [UIColor lightGrayColor];
}


- (IBAction)createCMISSession:(id)sender
{
    NSLog(@"We are in createCMISSession");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *envsPListPath = [bundle pathForResource:@"env-cfg" ofType:@"plist"];
    NSDictionary *environmentsDict = [[NSDictionary alloc] initWithContentsOfFile:envsPListPath];
    NSArray *environmentArray = [environmentsDict objectForKey:@"environments"];
    
    NSDictionary *environmentKeys = [environmentArray objectAtIndex:0];
    NSString *url = [environmentKeys valueForKey:@"url"];
    NSString *repositoryId = [environmentKeys valueForKey:@"repositoryId"];
    NSString *username = [environmentKeys valueForKey:@"username"];
    NSString *password = [environmentKeys valueForKey:@"password"];
    
    CMISSessionParameters *parameters = [[CMISSessionParameters alloc] initWithBindingType:CMISBindingTypeAtomPub];
    parameters.username = username;
    parameters.password = password;
    parameters.repositoryId = repositoryId;
    parameters.atomPubUrl = [NSURL URLWithString:url];
    
    NSMutableDictionary *paramExtensions = [NSMutableDictionary dictionary];
    const char * fileManagerName = class_getName([TestFileManager class]);
    const char * baseEncoderName = class_getName([TestBaseEncoder class]);
    const char * outputName = class_getName([GDCWriteStream class]);
    const char * inputName = class_getName([GDCCustomReadStream class]);

    [paramExtensions setObject:[NSString stringWithUTF8String:fileManagerName] forKey:kCMISSessionParameterCustomFileManager];
    [paramExtensions setObject:[NSString stringWithUTF8String:baseEncoderName] forKey:kCMISSessionParameterCustomBaseEncoder];
    [paramExtensions setObject:[NSString stringWithUTF8String:outputName] forKey:kCMISSessionParameterCustomFileOutputStream];
    [paramExtensions setObject:[NSString stringWithUTF8String:inputName] forKey:kCMISSessionParameterCustomFileInputStream];
    
    [parameters setObject:paramExtensions forKey:kCMISSessionParameterCustomFileIO];
    
    /** 
     We cannot use GD HTTP request on simulators.
     */
    const char * extensionName = class_getName([TestCMISNetworkIO class]);
    NSMutableDictionary *networkExtensions = [NSMutableDictionary dictionary];
    [networkExtensions setObject:[NSString stringWithUTF8String:extensionName] forKey:kCMISSessionParameterCustomRequest];
    
    [parameters setObject:networkExtensions forKey:kCMISSessionParameterCustomNetworkIO];

    [CMISSession connectWithSessionParameters:parameters completionBlock:^(CMISSession *session, NSError *error){
        if (nil == session)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Couldn't create CMIS session"
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles: nil];
            [alert show];
            NSLog(@"An error occurred when creating the session. Error code is %d and message is %@", [error code], [error localizedDescription]);
        }
        else
        {
            NSLog(@"We succeeded in creating a CMIS session");
            self.session = session;
            self.uploadButton.enabled = YES;
            self.uploadButton.titleLabel.textColor = [UIColor blueColor];
            self.downloadButton.enabled = YES;
            self.downloadButton.titleLabel.textColor = [UIColor blueColor];
            [self.session retrieveRootFolderWithCompletionBlock:^(CMISFolder *rootFolder, NSError *foldererror){
                if (nil == rootFolder)
                {
                    NSLog(@"An error occurred when retrieving the rootfolder. Error code is %d and message is %@", [foldererror code], [foldererror localizedDescription]);
                }
                else
                {
                    self.rootFolder = rootFolder;
                }
            }];
        }
    }];
    
}

- (IBAction)upload:(id)sender
{
//    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"chemistry_tm_logo_small.png" ofType:nil];
    NSString *filePath = [self prepareTestFileForUpload];
    if (filePath)
    {
        NSURL *fileURL = [NSURL URLWithString:filePath];
        NSString *documentName = [fileURL lastPathComponent];
        NSLog(@"trying to upload file %@",documentName);
        NSMutableDictionary *documentProperties = [NSMutableDictionary dictionary];
        [documentProperties setObject:documentName forKey:kCMISPropertyName];
        [documentProperties setObject:kCMISPropertyObjectTypeIdValueDocument forKey:kCMISPropertyObjectTypeId];
        if (self.rootFolder)
        {
            [self.rootFolder createDocumentFromFilePath:filePath
                                           withMimeType:@"test/plain"
                                         withProperties:documentProperties
                                        completionBlock:^(NSString *objectID, NSError * error){
                                            if (nil == objectID)
                                            {
                                                NSLog(@"CMIS upload of test document failed. Error is %d with message %@", [error code], [error localizedDescription]);
                                                self.testDocId = nil;
                                            }
                                            else
                                            {
                                                NSLog(@"Upload succeeded and the object ID is %@", objectID);
                                                self.testDocId = objectID;
                                            }
                                        } progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal){}];
        }
        
    }
    
    
}

- (IBAction)remove:(id)sender
{
    if (self.session && self.testDocId)
    {
        [self.session retrieveObject:self.testDocId completionBlock:^(CMISObject *object, NSError *error){
            if (object)
            {
                CMISDocument *doc = (CMISDocument *)object;
                [doc deleteAllVersionsWithCompletionBlock:^(BOOL documentDeleted, NSError *deleteError){
                    if (documentDeleted)
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                        message:@"The test doc was deleted successfully"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles: nil];
                        [alert show];
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:@"Failure to delete the test doc"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles: nil];
                        [alert show];
                        NSLog(@"Error deleting the test doc code=%d , message=%@",[deleteError code], [deleteError localizedDescription]);
                    }
                }];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Failure to retrieve the test doc"
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles: nil];
                [alert show];
                NSLog(@"Error deleting the test doc code=%d , message=%@",[error code], [error localizedDescription]);
                
            }
        }];
    }
    
}

- (IBAction)download:(id)sender
{
    if (self.session)
    {
        [self.session retrieveObjectByPath:@"/ios-test/versioned-quote.txt" completionBlock:^(CMISObject *object, NSError *error){
            if (nil == object)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Couldn't download test file"
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles: nil];
                [alert show];
                NSLog(@"An error occurred when downloading the test file. Error code is %d and message is %@", [error code], [error localizedDescription]);
                
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:@"we downloaded the file versioned-quote.txt"
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles: nil];
                [alert show];
            }
            
        }];
    }
}


#pragma private methods

- (NSString *)prepareTestFileForUpload
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_file.txt" ofType:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    NSData *content = [fileHandle readDataToEndOfFile];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd'T'HH-mm-ss-Z'"];
    NSString *documentName = [NSString stringWithFormat:@"test_file_%@.txt", [formatter stringFromDate:[NSDate date]]];
    
    if (content && 0 < [content length])
    {
        NSError *error = nil;
        GDCWriteStream *writeStream = [GDFileSystem getWriteStream:documentName appendmode:NO error:&error];
        if (writeStream)
        {
            if ([writeStream hasSpaceAvailable])
            {
                NSUInteger bufferSize = [content length];
                uint8_t buffer[bufferSize];
                [content getBytes:buffer length:bufferSize];
                if ([writeStream write:(const uint8_t *)(&buffer) maxLength:bufferSize] != -1 )
                {
                    NSLog(@"Managed to write content of file into secure container");
                }
                else
                {
                    NSLog(@"failed to write data into secure container");
                }
            }
            [writeStream close];
        }
    }
    else
    {
        NSLog(@"We were not able to create a valid GDCWriteStream instance for file %@", documentName);
    }
    
    [fileHandle closeFile];
    return documentName;
}



@end
