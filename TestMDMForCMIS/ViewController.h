//
//  ViewController.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 19/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (nonatomic, weak) IBOutlet UIButton * testCMISSessionButton;
@property (nonatomic, weak) IBOutlet UIButton * uploadButton;
@property (nonatomic, weak) IBOutlet UIButton * removeButton;
@property (nonatomic, weak) IBOutlet UIButton * downloadButton;
- (IBAction)createCMISSession:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)download:(id)sender;
@end
