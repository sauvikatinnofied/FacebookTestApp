//
//  AppDelegate.h
//  FacebookTestApp
//
//  Created by Sauvik Dolui on 7/18/14.
//  Copyright (c) 2014 Innofied Solution Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Declaring a Facebook Session Object to keep track of the cuurent session on Facebook
@property (strong , nonatomic) FBSession *session;

@end
