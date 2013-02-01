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

#import "SampleTableViewController.h"
#import "CMISSession.h"
#import "CMISDocument.h"
#import "CMISFolder.h"
#import "CMISSessionParameters.h"
#import <objc/runtime.h>
#import "GDCCustomReadStream.h"
#import "GDCWriteStream+OutputStream.h"
#import "CMISConstants.h"
#import <GD/GDFileSystem.h>
#import "CMISFileManager.h"
#import "CustomGDCMISFileManager.h"
#import "CustomGDCMISNetworkProvider.h"

@interface SampleTableViewController ()
@property (nonatomic, strong) CMISSession * session;
@property (nonatomic, strong) CMISFolder *rootFolder;
@property (nonatomic, strong) CMISDocument *testDoc;
@property (nonatomic, strong) CMISRequest *request;
@property (nonatomic, strong) NSString *testDocId;
@property BOOL canActionCMISDoc;
@property BOOL canRemoveCMISDoc;
- (void)deselectRow;
- (NSString *)prepareTestFileForUpload;
@end

@implementation SampleTableViewController
@synthesize uploadLabel = _uploadLabel;
@synthesize removeLabel = _removeLabel;
@synthesize downloadLabel = _downloadLabel;
@synthesize uploadCell = _uploadCell;
@synthesize removeCell = _removeCell;
@synthesize downloadCell = _downloadCell;
@synthesize session = _session;
@synthesize rootFolder = _rootFolder;
@synthesize testDocId = _testDocId;
@synthesize canActionCMISDoc = _canActionCMISDoc;
@synthesize canRemoveCMISDoc = _canRemoveCMISDoc;
@synthesize testDoc = _testDoc;
@synthesize request = _request;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.uploadLabel.textColor = [UIColor lightGrayColor];
    self.removeLabel.textColor = [UIColor lightGrayColor];
    self.downloadLabel.textColor = [UIColor lightGrayColor];
    self.canRemoveCMISDoc = NO;
    self.canActionCMISDoc = NO;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source


#pragma mark - Table view delegate

- (void)deselectRow
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    switch (row)
    {
        case 0:
            [self createCMISSession];
            break;
        case 1:
            [self uploadFile];
            break;
        case 2:
            [self removeFile];
            break;
        case 3:
            [self downloadFile];
            break;
        default:
            break;
    }
    [self performSelector:@selector(deselectRow) withObject:nil afterDelay:0.5f];
}

- (void)createCMISSession
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
    /**
     File IO setting. We need to have the test manager defined here
    CMISFileManager *fileManager = [[CMISFileManager alloc] initWithClassName:@"CustomGDCMISFileManager"];
    parameters.fileManager = fileManager;
     */
    
    /*
    NSMutableDictionary *paramExtensions = [NSMutableDictionary dictionary];
    const char * fileManagerName = class_getName([TestFileManager class]);
    [paramExtensions setObject:[NSString stringWithUTF8String:fileManagerName] forKey:kCMISSessionParameterCustomFileManager];
    [parameters setObject:paramExtensions forKey:kCMISSessionParameterCustomFileIO];
     */


    /**
     Network IO setting. We need to provide the HTTP invoker here
     */
    CustomGDCMISNetworkProvider *networkProvider = [[CustomGDCMISNetworkProvider alloc] init];
    parameters.networkProvider = networkProvider;

    /*
    NSMutableDictionary *networkExtension = [NSMutableDictionary dictionary];
    const char * networkClassName = class_getName([GDHttpUtil class]);
    [networkExtension setObject:[NSString stringWithUTF8String:networkClassName] forKey:kCMISSessionParameterCustomRequest];
    [parameters setObject:networkExtension forKey:kCMISSessionParameterCustomNetworkIO];
     */
    
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
            [self.session retrieveRootFolderWithCompletionBlock:^(CMISFolder *rootFolder, NSError *foldererror){
                if (nil == rootFolder)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Couldn't obtain root folder"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles: nil];
                    [alert show];
                    NSLog(@"An error occurred when retrieving the rootfolder. Error code is %d and message is %@", [foldererror code], [foldererror localizedDescription]);
                }
                else
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                    message:@"CMIS session was created successfully and got the root folder"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles: nil];
                    [alert show];
                    NSLog(@"We succeeded in getting the root folder for the session");
                    self.uploadLabel.textColor = [UIColor blackColor];
                    self.uploadCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    self.uploadCell.selectionStyle = UITableViewCellSelectionStyleGray;
                    self.downloadLabel.textColor = [UIColor blackColor];
                    self.downloadCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    self.downloadCell.selectionStyle = UITableViewCellSelectionStyleGray;
                    self.canActionCMISDoc = YES;
                    self.rootFolder = rootFolder;
                }
            }];
        }
    }];
    
}

- (void)uploadFile
{
    if (!self.canActionCMISDoc)
    {
        return;
    }
    NSLog(@"We are in uploadFile");
    NSString *filePath = [self prepareTestFileForUpload];
    if (filePath && self.rootFolder)
    {
        NSURL *fileURL = [NSURL URLWithString:filePath];
        NSString *documentName = [fileURL lastPathComponent];
        NSLog(@"trying to upload file %@",documentName);
        NSMutableDictionary *documentProperties = [NSMutableDictionary dictionary];
        [documentProperties setObject:documentName forKey:kCMISPropertyName];
        [documentProperties setObject:kCMISPropertyObjectTypeIdValueDocument forKey:kCMISPropertyObjectTypeId];
        NSError *error = nil;
        GDCReadStream *inputStream = [GDFileSystem getReadStream:filePath error:&error];
        GDFileStat myStat;
        NSError *outError = nil;
        BOOL success = [GDFileSystem getFileStat:filePath to:&myStat error:&outError];
        if (inputStream && success)
        {
            unsigned long long bytesExpected = myStat.fileLen;
            NSLog(@"the expected file length to be uploaded is %lld",myStat.fileLen);
            [self.rootFolder createDocumentFromInputStream:inputStream
                                              withMimeType:@"text/plain"
                                            withProperties:documentProperties
                                             bytesExpected:bytesExpected
                                           completionBlock:^(NSString *objectId, NSError *error){
                                               if (nil == objectId)
                                               {
                                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                   message:@"Failed to upload test doc"
                                                                                                  delegate:self
                                                                                         cancelButtonTitle:@"Ok"
                                                                                         otherButtonTitles: nil];
                                                   [alert show];
                                                   NSLog(@"CMIS upload of test document failed. Error is %d with message %@", [error code], [error localizedDescription]);
                                                   self.testDocId = nil;
                                               }
                                               else
                                               {
                                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                                                   message:@"The test doc was uploaded successfully"
                                                                                                  delegate:self
                                                                                         cancelButtonTitle:@"Ok"
                                                                                         otherButtonTitles: nil];
                                                   [alert show];
                                                   NSLog(@"Upload succeeded and the object ID is %@", objectId);
                                                   self.testDocId = objectId;
                                                   self.removeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                                                   self.removeCell.selectionStyle = UITableViewCellSelectionStyleGray;
                                                   self.removeLabel.textColor = [UIColor blackColor];
                                                   self.canRemoveCMISDoc = YES;
                                               }
                                           }
                                             progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal){}];
        }
        else
        {
            NSLog(@"either the input stream is nil or we couldn't get the file stats");
            if (error)
            {
                NSLog(@"input stream is nil. Error code is %d and message %@",[error code], [error localizedDescription]);
            }
            if(outError)
            {
                NSLog(@"file stats error. Error code is %d and message %@",[outError code], [outError localizedDescription]);                
            }
        }
        /*
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
                                                self.removeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                                                self.removeCell.selectionStyle = UITableViewCellSelectionStyleGray;
                                                self.removeLabel.textColor = [UIColor blackColor];
                                                self.canRemoveCMISDoc = YES;
                                            }
                                        } progressBlock:^(unsigned long long bytesUploaded, unsigned long long bytesTotal){}];
        }
        */
    }
    
}

- (void)removeFile
{
    if (!self.canRemoveCMISDoc || !self.canActionCMISDoc)
    {
        return;
    }
    if (self.session && self.testDocId)
    {
        [self.session retrieveObject:self.testDocId completionBlock:^(CMISObject *object, NSError *error){
            if (object)
            {
                NSLog(@"SampleTableViewController::removeFile We got the document we want to delete");
                self.testDoc = (CMISDocument *)object;
                /*
                [self.session.binding.objectService deleteObject:self.testDocId
                                                     allVersions:YES
                                                 completionBlock:^(BOOL objectDeleted, NSError *deleteError){
                                                     if (objectDeleted)
                                                     {
                                                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                                                         message:@"The test doc was deleted successfully"
                                                                                                        delegate:self
                                                                                               cancelButtonTitle:@"Ok"
                                                                                               otherButtonTitles: nil];
                                                         [alert show];
                                                         NSLog(@"We succeeded in deleting the object");
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
                 */
                [self.testDoc deleteAllVersionsWithCompletionBlock:^(BOOL documentDeleted, NSError *deleteError){
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
                    self.removeCell.accessoryType = UITableViewCellAccessoryNone;
                    self.removeLabel.textColor = [UIColor lightGrayColor];
                    self.canRemoveCMISDoc = NO;
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

- (void)downloadFile
{
    if (!self.canActionCMISDoc)
    {
        return;
    }
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
                CMISDocument *serverDoc = (CMISDocument *)object;
                NSError *writeError = nil;
                NSString *filePath = @"versionedtext.text";
                GDCWriteStream *outputStream = [GDFileSystem getWriteStream:filePath appendmode:NO error:&writeError];
                NSStreamStatus status = outputStream.streamStatus;
                NSLog(@"stream status is %d", status);
                [serverDoc downloadContentToOutputStream:outputStream completionBlock:^(NSError *downloadError){
                    if (downloadError)
                    {
                        [outputStream close];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:@"Couldn't download content of test document"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles: nil];
                        [alert show];

                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                        message:@"we downloaded the file versioned-quote.txt"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles: nil];
                        [alert show];
                        [outputStream close];
                        GDFileStat stats;
                        NSError *error = nil;
                        BOOL success = [GDFileSystem getFileStat:filePath to:&stats error:&error];
                        if (!success)
                        {
                            NSLog(@"Somehow we can't get the file stats to the downloaded file");
                        }
                        else
                        {
                            NSInteger offset = stats.fileLen;
                            NSLog(@"the file size is %d", offset);
                            NSError *readError = nil;
                            NSData *data = [GDFileSystem readFromFile:filePath error:&readError];
                            if (data)
                            {
                                NSLog(@"read in data are %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                            }
                        }
                    }
                } progressBlock:nil];
                
            }
            
        }];
    }
    
}

/**
 this is creating a tmp file in the standard IO file system
 */
- (NSString *)temporaryTestFileForUpload
{
    CMISFileManager *manager = [CMISFileManager defaultManager];
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_file.txt" ofType:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    NSData *content = [fileHandle readDataToEndOfFile];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd'T'HH-mm-ss-Z'"];
    NSString *documentName = [NSString stringWithFormat:@"test_file_%@.txt", [formatter stringFromDate:[NSDate date]]];
    NSString * tmpPath = [manager internalFilePathFromName:documentName];

    NSError *error = nil;
    [manager createFileAtPath:tmpPath contents:content error:&error];

    [fileHandle closeFile];
    return tmpPath;
}


- (NSString *)prepareTestFileForUpload
{
    NSLog(@"We are in prepareTestFileForUpload");
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
