//
//  ServerDetailTableViewController.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 07/02/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServerDetailTableViewController : UITableViewController <UITextFieldDelegate>
@property (nonatomic, strong) NSString * serverName;
@property (nonatomic, weak) IBOutlet UITextField *userField;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UITextField *repoIDField;
@property (nonatomic, weak) IBOutlet UITextField *downloadField;
@property (nonatomic, weak) IBOutlet UITextField *uploadField;
- (IBAction)saveWhenDone:(id)sender;
@end
