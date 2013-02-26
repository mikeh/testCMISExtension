//
//  ServerDetailTableViewController.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 07/02/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import "ServerDetailTableViewController.h"

@interface ServerDetailTableViewController ()
@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong) NSString * repoID;
@property (nonatomic, strong) NSString * downloadID;
@property (nonatomic, strong) NSString * uploadID;
@end

@implementation ServerDetailTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source



- (IBAction)saveWhenDone:(id)sender
{
    NSArray *serverSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverSettings"];
    NSMutableDictionary *dictionary = nil;
    if ([self.serverName isEqualToString:@"Amazon"])
    {
        dictionary = [serverSettings objectAtIndex:0];
    }
    else if ([self.serverName isEqualToString:@"TS"])
    {
        dictionary = [serverSettings objectAtIndex:1];
    }
    else
    {
        dictionary = [serverSettings objectAtIndex:2];
    }
}



#pragma mark - Table view delegate


#pragma mark - Textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    switch (textField.tag)
    {
        case 1:
            self.username = textField.text;
            break;
        case 2:
            self.password = textField.text;
            break;
        case 3:
            self.repoID = textField.text;
            break;
        case 4:
            self.downloadID = textField.text;
            break;
        case 5:
            self.uploadID = textField.text;
            break;
    }
}

@end
