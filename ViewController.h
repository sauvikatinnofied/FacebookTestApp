//
//  ViewController.h
//  FacebookTestApp
//
//  Created by Sauvik Dolui on 7/18/14.
//  Copyright (c) 2014 Innofied Solution Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *logInLogOutButton;
@property (assign, nonatomic) BOOL sessionStarted;
@property (strong,nonatomic)  FBFrictionlessRecipientCache* friendCache;

- (IBAction)onClickLogInLogOutButton:(id)sender;
- (IBAction)onClickUserInfoButton:(id)sender;
- (IBAction)onClickFriendListButton:(id)sender;


@end
