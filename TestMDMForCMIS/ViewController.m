//
//  ViewController.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 19/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "ViewController.h"
#import "CMISSession.h"
#import "CMISSessionParameters.h"
#import "TestCMISNetworkIO.h"
#import <objc/runtime.h>
#import "GDCReadStream+InputStream.h"
#import "GDCWriteStream+OutputStream.h"
#import "TestFileManager.h"
#import "TestBaseEncoder.h"
#import "CMISConstants.h"
#import <GD/GDFileSystem.h>


@interface ViewController ()
@property (nonatomic, strong) CMISSession * session;
@property (nonatomic, strong) CMISFolder *rootFolder;
- (void)testGDIO;
@end

@implementation ViewController
@synthesize testCMISSessionButton = _testCMISSessionButton;
@synthesize session = _session;
@synthesize uploadButton = _uploadButton;
@synthesize removeButton = _removeButton;
@synthesize rootFolder = _rootFolder;
- (void)viewDidLoad
{
    NSLog(@"We are in viewDidLoad");
    [super viewDidLoad];
    
    self.uploadButton.enabled = NO;
    self.uploadButton.titleLabel.textColor = [UIColor lightGrayColor];
    self.removeButton.enabled = NO;
    self.removeButton.titleLabel.textColor = [UIColor lightGrayColor];
}


- (IBAction)createCMISSession:(id)sender
{
//    [self testGDIO];
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
    const char * inputName = class_getName([GDCReadStream class]);

    [paramExtensions setObject:[NSString stringWithUTF8String:fileManagerName] forKey:kCMISSessionParameterCustomFileManager];
    [paramExtensions setObject:[NSString stringWithUTF8String:baseEncoderName] forKey:kCMISSessionParameterCustomBaseEncoder];
    [paramExtensions setObject:[NSString stringWithUTF8String:outputName] forKey:kCMISSessionParameterCustomFileOutputStream];
    [paramExtensions setObject:[NSString stringWithUTF8String:inputName] forKey:kCMISSessionParameterCustomFileInputStream];
    
    [parameters setObject:paramExtensions forKey:kCMISSessionParameterCustomFileIO];
    
    const char * extensionName = class_getName([TestCMISNetworkIO class]);
    NSMutableDictionary *networkExtensions = [NSMutableDictionary dictionary];
    [networkExtensions setObject:[NSString stringWithUTF8String:extensionName] forKey:kCMISSessionParameterCustomRequest];
    
    //    [parameters setObject:networkExtensions forKey:kCMISSessionParameterCustomNetworkIO];
    
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
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_file.txt" ofType:nil];
    NSLog(@"The upload method is trying to locate a file at %@", filePath);
    BOOL isDir;
    BOOL fileExists = [GDFileSystem fileExistsAtPath:filePath isDirectory:&isDir];
    if (!fileExists)
    {
        NSError *error = nil;
        BOOL success = [GDFileSystem moveFileToSecureContainer:filePath error:&error];
        if (!success)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Couldn't move file to secure container"
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles: nil];
            [alert show];
        }
        else
        {
            fileExists = YES;
        }
    }
    if (fileExists)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat: @"yyyy-MM-dd'T'HH-mm-ss-Z'"];
        NSString *documentName = [NSString stringWithFormat:@"test_file_%@.txt", [formatter stringFromDate:[NSDate date]]];
        NSMutableDictionary *documentProperties = [NSMutableDictionary dictionary];
        [documentProperties setObject:documentName forKey:kCMISPropertyName];
        [documentProperties setObject:kCMISPropertyObjectTypeIdValueDocument forKey:kCMISPropertyObjectTypeId];
        if (self.rootFolder)
        {
            [self.rootFolder createDocumentFromFilePath:filePath
                                           withMimeType:@"text/plain"
                                         withProperties:documentProperties
                                        completionBlock:^(NSString *objectID, NSError * error){
                                            if (nil == objectID)
                                            {
                                                NSLog(@"CMIS upload of test document failed. Error is %d with message %@", [error code], [error localizedDescription]);
                                            }
                                            else
                                            {
                                                NSLog(@"Upload succeeded and the object ID is %@", objectID);
                                            }
                                        } progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal){}];
        }
        
    }
    
    
}

- (IBAction)remove:(id)sender
{
    
}

- (void)testGDIO
{
    GDCWriteStream *writeStream = [GDCWriteStream outputStreamToFileAtPath:@"test_file_2.txt" append:NO];
    if (writeStream)
    {
        NSLog(@"Creating the outputstream based on category was successful");
    }
}


@end
