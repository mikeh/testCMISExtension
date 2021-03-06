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

#import <UIKit/UIKit.h>

@interface SampleTableViewController : UITableViewController
@property (nonatomic, weak) IBOutlet UILabel *uploadLabel;
@property (nonatomic, weak) IBOutlet UILabel *removeLabel;
@property (nonatomic, weak) IBOutlet UILabel *downloadLabel;
@property (nonatomic, weak) IBOutlet UILabel *uploadBigLabel;
@property (nonatomic, weak) IBOutlet UITableViewCell *uploadCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *removeCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *downloadCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *uploadBigCell;
- (void)createCMISSession;
- (void)uploadFile;
- (void)removeFile;
- (void)downloadFile;
- (void)uploadBigFile;
@end
