//
//  SampleTableViewController.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 09/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SampleTableViewController : UITableViewController
@property (nonatomic, weak) IBOutlet UILabel *uploadLabel;
@property (nonatomic, weak) IBOutlet UILabel *removeLabel;
@property (nonatomic, weak) IBOutlet UILabel *downloadLabel;
@property (nonatomic, weak) IBOutlet UITableViewCell *uploadCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *removeCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *downloadCell;
- (void)createCMISSession;
- (void)uploadFile;
- (void)removeFile;
- (void)downloadFile;
- (void)testGDFileIO;
@end
