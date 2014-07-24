//
//  ViewController.m
//  FacebookTestApp
//
//  Created by Sauvik Dolui on 7/18/14.
//  Copyright (c) 2014 Innofied Solution Pvt. Ltd. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
@property (strong , nonatomic) NSMutableArray *arrayForFriendsList;
@end

@implementation ViewController

@synthesize friendCache = _friendCache;
@synthesize arrayForFriendsList;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickLogInLogOutButton:(id)sender {
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _sessionStarted = appDelegate.session.isOpen;
    
    
    if (!_sessionStarted) {
    
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"email", @"public_profile", @"user_friends",
                                nil];
        
        // Attempt to open the session. If the session is not open, show the user the Facebook login UX
        [FBSession openActiveSessionWithReadPermissions:permissions
                                           allowLoginUI:TRUE
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            
            NSLog(@"InCompletion Handler");
            // Did something go wrong during login? I.e. did the user cancel?
            if (status == FBSessionStateClosedLoginFailed || status == FBSessionStateClosed || status == FBSessionStateCreatedOpening) {
                
                NSLog(@"Login Failure");
                // If so, just send them round the loop again
                [[FBSession activeSession] closeAndClearTokenInformation];
                [FBSession setActiveSession:nil];
                
                appDelegate.session  = nil;
            }
            else {
                
                _sessionStarted = YES;
                NSLog(@"Login Success");
                // Adding this session to the AppDelegate's FBSession Object
                AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                appDelegate.session  = session;
                
                
                // -----------------------------------------
                // frictionless friends cache primary value
                        _friendCache = nil;
                // -----------------------------------------
                
                [self reRequestFriendPermission];
                
                // Updating the button title(LogIn -> LogOut)
                [self updateView];
                
            }
        }];

    }else{
        
        NSLog(@"A session was found prevoiusly, Not going to recreate the session again");
    }
    
    
    
}

-(void) sendRequest:(NSArray*) friendIDs withScore:( const int )nScore
{
    // Normally this won't be hardcoded but will be context specific, i.e. players you are in a match with, or players who recently played the game etc
    NSArray *suggestedFriends = [[NSArray alloc] initWithObjects:
                                 @"223400030", @"286400088", @"767670639", @"516910788",
                                 nil];
    
    SBJsonWriter *jsonWriter = [SBJsonWriter new];
    NSDictionary *challenge =  [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", nScore], @"challenge_score", nil];
    NSString *challengeStr = [jsonWriter stringWithObject:challenge];
    
    
    // Create a dictionary of key/value pairs which are the parameters of the dialog
    
    // 1. No additional parameters provided - enables generic Multi-friend selector
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     // 2. Optionally provide a 'to' param to direct the request at a specific user
                                     [friendIDs componentsJoinedByString:@","], @"to", // Ali
                                     // 3. Suggest friends the user may want to request, could be game context specific?
                                     [suggestedFriends componentsJoinedByString:@","], @"suggestions",
                                     challengeStr, @"data",
                                     nil];
    
    
    if (!_friendCache) {
        _friendCache = [[FBFrictionlessRecipientCache alloc] init];
    }
    
    [_friendCache prefetchAndCacheForSession:nil];
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:[NSString stringWithFormat:@"I just smashed %d friends! Can you beat it?", nScore]
                                                    title:@"Smashing!"
                                               parameters:params
                                                  handler:^(FBWebDialogResult result,
                                                            NSURL *resultURL,
                                                            NSError *error) {
                                                      if (error) {
                                                          // Case A: Error launching the dialog or sending request.
                                                          NSLog(@"Error sending request.");
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // Case B: User clicked the "x" icon
                                                              NSLog(@"User canceled request.");
                                                          } else {
                                                              NSLog(@"Request Sent.");
                                                          }
                                                      }
                                                  }
                                              friendCache:_friendCache];
}

- (IBAction)onClickUserInfoButton:(id)sender {
    
    // Start the facebook request
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *result, NSError *error)
     {
         // Did everything come back okay with no errors?
         if (!error && result) {
             
             
             /*
              
              Result = {
              email = "sauvikdolui@gmail.com";
              "first_name" = Sauvik;
              gender = male;
              id = 675938339154902;
              "last_name" = Dolui;
              link = "https://www.facebook.com/app_scoped_user_id/675938339154902/";
              locale = "en_US";
              name = "Sauvik Dolui";
              timezone = "5.5";
              "updated_time" = "2014-05-29T06:14:07+0000";
              verified = 1;
              }
              
              */
             // If so we can extract out the player's Facebook ID and first name
            // NSString *firstname = [[NSString alloc] initWithString:result.first_name];
             //callback(true);
             NSLog(@"My informations = %@",result);
             
            
         }
         
         else {
             //callback(false);
         }
     }];
}

- (IBAction)onClickFriendListButton:(id)sender {
    // Facebook profile picture url htttps://graph.facebook.com/675938339154902/picture?width=256&height=256
    
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (!error && result)
        {
            //NSArray* fetchedFriendData = [[NSArray alloc] initWithArray:[result objectForKey:@"data"]];
            NSLog(@"Result = %@",result);
            
        }
        else
        {
            
        }
        
    }];
    
}

-(void)reRequestFriendPermission
{
    NSArray *permissions = [[NSArray alloc] initWithObjects:@"user_friends",@"publish_stream", @"publish_actions", nil];
    [[FBSession activeSession] requestNewReadPermissions:permissions completionHandler:^(FBSession *session, NSError *error) {
        
        if (!error) {
            NSLog(@"Permission is granted");

        }
        else {
            
            NSLog(@"Permission is granted");
        }
    }];
}


- (IBAction)sendInvite:(id)sender
{
    //AVmJ2fEgZ8KwYe0Jk8G_RwO04wYJ-zRrGKaTnFh_V9VnmbhHG8tgdXzviQDumXq0-nQPqphupBPWRJjP_ab_RkK5f1i1dcagXbP3NVzW38yNGA
    //AaIJI73yXCC2ZWHwiZ6OvyZDBz22QFLQOKZtD8wAXKqlvTC-bYVVaLkhYzJQEqpVlz-hAUxxUq-OcLRYBCPh-xT_PhZkuuQzrIN7yM0kH7wXmQ
    
    NSMutableDictionary* params;
    
    NSArray *friendInvitesID=@[@"AVmJ2fEgZ8KwYe0Jk8G_RwO04wYJ-zRrGKaTnFh_V9VnmbhHG8tgdXzviQDumXq0-nQPqphupBPWRJjP_ab_RkK5f1i1dcagXbP3NVzW38yNGA"];

    if( friendInvitesID)
    {
        params = [NSMutableDictionary dictionaryWithObjectsAndKeys: [friendInvitesID componentsJoinedByString:@","], @"to", nil];
    }
    else {
        params = [NSMutableDictionary dictionaryWithObjectsAndKeys: nil];
    }
    
    NSLog(@"SendInvite params = %@",params);
    if (_friendCache == NULL) {
        _friendCache = [[FBFrictionlessRecipientCache alloc] init];
    }
    
    [_friendCache prefetchAndCacheForSession:nil];
    
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:[NSString stringWithFormat:@"Come join me in the friend smash times!"]
                                                    title:@"Smashing Invite!"
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      
                                                      NSLog(@"result url : %@", resultURL);
                                                      NSLog(@"result : %u", result);
                                                      if (error) {
                                                          // Case A: Error launching the dialog or sending request.
                                                          NSLog(@"Error sending request.");
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // Case B: User clicked the "x" icon
                                                              NSLog(@"User canceled request.");
                                                          } else
                                                          {
                                                              NSLog(@"Request Sent.");
                                                          }
                                                      }}
                                              friendCache:_friendCache];
}


- (IBAction)sendMessage:(id)sender
{
//    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
//    
//    if ([FBDialogs canPresentMessageDialogWithParams:params])
//    {
//        
//        NSLog(@"fb dialogs can present");
//        
//        [FBDialogs presentMessageDialogWithLink:[NSURL URLWithString:@"https://itunes.apple.com/us/app/docanddo/id836459438?ls=1&mt=8"]
//                                        handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                            if(error) {
//                                                
//                                                
//                                                NSLog(@"%@", [NSString stringWithFormat:@"Error messaging link: %@", error.description]);
//
//                                            } else {
//                                                // Success
//                                                NSLog(@"message result: %@", results);
//                                            }
//                                        }];    }
//    else
//    {
//        NSLog(@"fb dialogs cannot present");
//        // Disable button or other UI for Message Dialog
//    }

//===================================================================================================================
    

    //--------------------------------------share post-----------------------------------//

    
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                   @"Sharing Tutorial", @"name",
//                                   @"Build great social apps and get more installs.", @"caption",
//                                   @"Allow your users to share stories on Facebook from your app using the iOS SDK.", @"description",
//                                   @"https://developers.facebook.com/docs/ios/share/", @"link",
//                                   @"http://i.imgur.com/g3Qc1HN.png", @"picture",
//                                   nil];
//    
//    [FBWebDialogs presentFeedDialogModallyWithSession:nil
//                                           parameters:nil
//                                              handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
//                                                  if (error) {
//                                                      NSLog(@"Error publishing story: %@", error.description);
//                                                  } else {
//                                                      if (result == FBWebDialogResultDialogNotCompleted) {
//                                                          // User canceled.
//                                                          NSLog(@"User cancelled.");
//                                                      } else {
//                                                          // Handle the publish feed callback
//                                                          NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
//                                                          
//                                                          if (![urlParams valueForKey:@"post_id"]) {
//                                                              // User canceled.
//                                                              NSLog(@"User cancelled.");
//                                                              
//                                                          } else {
//                                                              // User clicked the Share button
//                                                              NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
//                                                              NSLog(@"result %@", result);
//                                                          }
//                                                      }
//                                                  }
//                                              }];
//
    
//===================================================================================================================
   
    
    
    //--------------------------------------tagging code-----------------------------------//
    
//    
//    
//    /*
//     AaKNxNhT8CqakqXsA1DjKyYeZX3j73mje24KewJr_rKTeivJCVvQ9FVEOlNIdWze7BJTLXtrToOvf0K8v-KNIUQTf8NHn1GiF0iybQb3NaVzHA
//     AaIQBScCINhOQuLb2wIGuLYj0zn5PutZ9CVnJixp489rPGKKBI80a9pwP6dcC_BbRmOm5Mf1CL9dL2rk-lsfAVnWjDHgFpS2pwhBAvQ4scFx9A
//     AaKZKPnY-Xs_MVEuxgN5MP6AO-LeeFl2CsYN1AISJZxz7g6FNzHUj3uEFFPyDMdir9oq42ZR6EuiBPAVV7HLIMd8ZcD4EOVGd1j2f9LU1N_GjA
//     
//     
//     */
//
//    [FBRequestConnection startForPostStatusUpdate:@"test message with place and tags"
//                                            place:@"155021662189"
//                                             tags:@[@"AaKNxNhT8CqakqXsA1DjKyYeZX3j73mje24KewJr_rKTeivJCVvQ9FVEOlNIdWze7BJTLXtrToOvf0K8v-KNIUQTf8NHn1GiF0iybQb3NaVzHA",@"AaIQBScCINhOQuLb2wIGuLYj0zn5PutZ9CVnJixp489rPGKKBI80a9pwP6dcC_BbRmOm5Mf1CL9dL2rk-lsfAVnWjDHgFpS2pwhBAvQ4scFx9A",@"AaKZKPnY-Xs_MVEuxgN5MP6AO-LeeFl2CsYN1AISJZxz7g6FNzHUj3uEFFPyDMdir9oq42ZR6EuiBPAVV7HLIMd8ZcD4EOVGd1j2f9LU1N_GjA"]
//                                completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
//     {
//        NSLog(@"startForPostStatusUpdate: %@, error: %@", result, error);
//    }];
    
    
//===================================================================================================================
    
    //--------------------------------------bragging code-----------------------------------//
//
//    
//    
//    // This function will invoke the Feed Dialog to post to a user's Timeline and News Feed
//    // It will attempt to use the Facebook Native Share dialog
//    // If that's not supported we'll fall back to the web based dialog.
//    NSString *linkURL = [NSString stringWithFormat:@"https://itunes.apple.com/us/app/docanddo/id836459438?ls=1&mt=8"];
//    // Prepare the native share dialog parameters
//    FBShareDialogParams *shareParams = [[FBShareDialogParams alloc] init];
//    shareParams.link = [NSURL URLWithString:linkURL];
//    shareParams.name = @"Check out my Doc & Do!";
//    //shareParams.caption= @"Join me!";
//    //shareParams.picture= [NSURL URLWithString:pictureUrl];
//    shareParams.description =[NSString stringWithFormat:@"Download this awesome app. I am using it"];
//    
//    if ([FBDialogs canPresentShareDialogWithParams:shareParams]){
//        
//        [FBDialogs presentShareDialogWithParams:shareParams
//                                    clientState:nil
//                                        handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                            if(error) {
//                                                NSLog(@"Error publishing story in if.");
//                                            } else if (results[@"completionGesture"] && [results[@"completionGesture"] isEqualToString:@"cancel"]) {
//                                                NSLog(@"User canceled story publishing in if.");
//                                            } else {
//                                                NSLog(@"Story published in if.");
//                                            }
//                                        }];
//        
//    } else {
//        
//        // Prepare the web dialog parameters
//        NSDictionary *params = @{
//                                 @"name" : shareParams.name,
//                                 @"caption" : shareParams.caption,
//                                 @"description" : shareParams.description,
//                                 //@"picture" : pictureUrl,
//                                 @"link" : linkURL
//                                 };
//        
//        // Invoke the dialog
//        [FBWebDialogs presentFeedDialogModallyWithSession:nil
//                                               parameters:params
//                                                  handler:
//         ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
//             if (error) {
//                 NSLog(@"Error publishing story in else.");
//             } else {
//                 if (result == FBWebDialogResultDialogNotCompleted) {
//                     NSLog(@"User canceled story publishing in else.");
//                 } else {
//                     NSLog(@"Story published in else.");
//                 }
//             }}];
//    }
//    
    
//===================================================================================================================
    
    //--------------------------------------stories code-----------------------------------//
    
    if (FBSession.activeSession)
    {
        
        //---------------------custom story--------------------//
        //1.install game
        
        NSMutableDictionary<FBGraphObject> *newAction = [FBGraphObject graphObject];
        newAction[@"game"] = @"http://samples.ogp.me/163382137069945";
        // specify that this Open Graph object will be posted to Facebook
        newAction.provisionedForPost = YES;
        
        [FBRequestConnection startForPostWithGraphPath:@"me/innofiedtestapp:install"
                                           graphObject:newAction
                                     completionHandler:^(FBRequestConnection *connection,
                                                         id result,
                                                         NSError *error){
                                         if (error )
                                         {
                                             NSLog(@"error : %@", error);
                                         }
                                         else
                                         {
                                             NSLog(@"result : %@", result);
                                         }
                                         // handle the result
                                     }];
        
        /*------------------------------------------------------------*/
        //2. Play game
        NSMutableDictionary<FBGraphObject> *action = [FBGraphObject graphObject];
        action[@"game"] = @"http://samples.ogp.me/163382137069945";
        
        [FBRequestConnection startForPostWithGraphPath:@"me/innofiedtestapp:play"
                                           graphObject:action
                                     completionHandler:^(FBRequestConnection *connection,
                                                         id result,
                                                         NSError *error) {
                                         if (error )
                                         {
                                             NSLog(@"error : %@", error);
                                         }
                                         else
                                         {
                                             NSLog(@"result : %@", result);
                                         }
                                         // handle the result
                                     }];
        
        
        //---------------------built in story--------------------//
        
//        // Create a like action
//        id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
//        
//        // Link that like action to the restaurant object that we have created
//        [action setObject:@"https://itunes.apple.com/us/app/docanddo/id836459438?ls=1&mt=8" forKey:@"object"];
//        
//        // Post the action to Facebook
//        [FBRequestConnection startForPostWithGraphPath:@"me/og.likes"
//                                           graphObject:action
//                                     completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//                                         __block NSString *alertText;
//                                         __block NSString *alertTitle;
//                                         if (!error) {
//                                             // Success, the restaurant has been liked
//                                             NSLog(@"Posted OG action, id: %@", [result objectForKey:@"id"]);
//                                             alertText = [NSString stringWithFormat:@"Posted OG action, id: %@", [result objectForKey:@"id"]];
//                                             alertTitle = @"Success";
//                                             [[[UIAlertView alloc] initWithTitle:alertTitle
//                                                                         message:alertText
//                                                                        delegate:self
//                                                               cancelButtonTitle:@"OK!"
//                                                               otherButtonTitles:nil] show];
//                                         } else {
//                                             
//                                             NSLog(@"error : %@", error);
//                                             
//                                             [self handleAuthError:error];
//                                             
//                                             // An error occurred, we need to handle the error
//                                             // See: https://developers.facebook.com/docs/ios/errors
//                                         }
//                                     }];
    }
    else
    {
        NSLog(@"session inactive ");
        
        [FBSession openActiveSessionWithAllowLoginUI: YES];
    }
}



- (void)handleAuthError:(NSError *)error
{
    NSString *alertText;
    NSString *alertTitle;
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        // Error requires people using you app to make an action outside your app to recover
        alertTitle = @"Something went wrong";
        alertText = [FBErrorUtility userMessageForError:error];
        [self showMessage:alertText withTitle:alertTitle];
        
    } else {
        // You need to find more information to handle the error within your app
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //The user refused to log in into your app, either ignore or...
            alertTitle = @"Login cancelled";
            alertText = @"You need to login to access this part of the app";
            [self showMessage:alertText withTitle:alertTitle];
            
        } else {
            // All other errors that can happen need retries
            // Show the user a generic error message
            alertTitle = @"Something went wrong";
            alertText = @"Please retry";
            [self showMessage:alertText withTitle:alertTitle];
        }
    }
}


- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return [[NSMutableDictionary alloc] init];
}


- (void)sendRequest:(NSMutableArray *) targeted {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:@{
                                             @"social_karma": @"5",
                                             @"badge_of_awesomeness": @"1"}
                        options:0
                        error:&error];
    if (error) {
        NSLog(@"JSON error: %@", error);
        return;
    }
    
    NSString *giftStr = [[NSString alloc]
                         initWithData:jsonData
                         encoding:NSUTF8StringEncoding];
    NSMutableDictionary* params = [@{@"data" : giftStr} mutableCopy];
    
    // Filter and only show targeted friends
    if (targeted != nil && [targeted count] > 0) {
        NSString *selectIDsStr = [targeted componentsJoinedByString:@","];
        params[@"suggestions"] = selectIDsStr;
    }
    
    // Display the requests dialog
    [FBWebDialogs
     presentRequestsDialogModallyWithSession:nil
     message:@"Learn how to make your iOS apps social."
     title:nil
     parameters:params
     handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or sending request.
             NSLog(@"Error sending request.");
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 NSLog(@"User canceled request. User clicked the x icon");
             } else {
                 // Handle the send request callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"request"]) {
                     // User clicked the Cancel button
                     NSLog(@"User canceled request.User clicked the Cancel button");
                 } else {
                     // User clicked the Send button
                     NSString *requestID = [urlParams valueForKey:@"request"];
                     NSLog(@"Request ID: %@", requestID);
                 }
             }
         }
     }];
}

-(IBAction)checkFriendRequestPermission:(id)sender
{
   
    FBRequest *req = [[FBRequest alloc] initWithSession:[FBSession activeSession] graphPath:@"/me/permissions"];
    [req startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         NSDictionary *resultDic = (NSDictionary*) result;
         if (resultDic && !error){
             NSArray* fetchedPermissionData = [[NSArray alloc] initWithArray:[resultDic objectForKey:@"data"]];
             bool bFound = false;
             for (NSDictionary *currper in fetchedPermissionData) {
                 if( [[currper valueForKey:@"permission"] caseInsensitiveCompare:@"user_friends"] == NSOrderedSame ) {
                     if ([[currper valueForKey:@"status"] caseInsensitiveCompare:@"granted"] == NSOrderedSame) {
                         bFound = true;
                         NSLog(@"User Friend List Access permission granted");
                         break;
                     }
                 }
                 
             }
             
             //callback(bFound);
         }
         else {
             NSLog(@"Something went wrong...");
         }
     }];
    
}

- (IBAction)postStory:(id)sender {
    
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    
    // Create an object
    id<FBGraphObject> object =
    [FBGraphObject openGraphObjectForPostWithType:@"innofiedtestapp:install"
                                            title:@"Install A New App"
                                            image:@"http://a2.mzstatic.com/us/r30/Purple4/v4/5c/5a/c9/5c5ac908-85c2-c430-a226-13b3b7ff127d/mzl.hmjdnuwu.175x175-75.jpg"
                                              url:@" https://itunes.apple.com/us/app/docanddo/id836459438?ls=1&mt=8"
                                      description:@"Just Installed"];
    
    // Create an action
    id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
    
    // Set image on the action
    //[action setObject:image forKey:@"image"];
    
    // Link the object to the action
    [action setObject:object forKey:@"game"];
    
    // Tag one or multiple users using the users' ids
    [action setTags:@[@"686032654808679"]]; // going to tag manish
    
    // Tag a place using the place's id
    //id<FBGraphPlace> place = (id<FBGraphPlace>)[FBGraphObject graphObject];
    //[place setId:@"141887372509674"]; // Facebook Seattle
    //[action setPlace:place];
    
//    // Dismiss the image picker off the screen
//    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Check if the Facebook app is installed and we can present the share dialog
    FBOpenGraphActionParams *params = [[FBOpenGraphActionParams alloc] init];
    params.action = action;
    params.actionType = @"innofiedtestapp:install";
    
    // If the Facebook app is installed and we can present the share dialog
    if([FBDialogs canPresentShareDialogWithOpenGraphActionParams:params]) {
        // Show the share dialog
        [FBDialogs presentShareDialogWithOpenGraphAction:action
                                              actionType:@"innofiedtestapp:install"
                                     previewPropertyName:@"game"
                                                 handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                     if(error) {
                                                         // An error occurred, we need to handle the error
                                                         // See: https://developers.facebook.com/docs/ios/errors
                                                         NSLog(@"Error publishing story: %@", error.description);
                                                     } else {
                                                         // Success
                                                         NSLog(@"result %@", results);
                                                     }
                                                 }];
        
        // If the Facebook app is NOT installed and we can't present the share dialog
    } else {
        // FALLBACK: publish just a link using the Feed dialog
        
        // Put together the dialog parameters
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"Little Archer", @"name",
                                       @"Great Archery Game", @"caption",
                                       @"Save your kingdom from the menacing demons with your bow and arrow.", @"description",
                                       @"https://itunes.apple.com/app/little-indian-archer-free/id878189774?ls=1&mt=8", @"link",
                                       @"http://a2.mzstatic.com/us/r30/Purple4/v4/ff/f4/b8/fff4b87f-0183-f894-e8c9-e4976ab11b97/mzl.qhflnfdc.175x175-75.jpg", @"picture",
                                       nil];
        
        
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        // Show the feed dialog
        [FBWebDialogs presentFeedDialogModallyWithSession:appDelegate.session
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      
                                                      if (error) {
                                                          // An error occurred, we need to handle the error
                                                          // See: https://developers.facebook.com/docs/ios/errors
                                                          NSLog(@"Error publishing story: %@", error.description);
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // User cancelled.
                                                              NSLog(@"FBWebDialogResultDialogNotCompleted:User cancelled.");
                                                          } else {
                                                              
                                                              NSLog(@"Result URL = %@",resultURL);
                                                              
                                                              // Handle the publish feed callback
                                                              NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                              
                                                              if (![urlParams valueForKey:@"post_id"]) {
                                                                  // User cancelled.
                                                                  NSLog(@"User cancelled.");
                                                                  
                                                              } else {
                                                                  // User clicked the Share button
                                                                  NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                                  NSLog(@"result %@", result);
                                                              }
                                                          }
                                                      }
                                                  }];
        
    }

    
    
    
    
}
- (IBAction)postLevelObject:(id)sender {
    
    if ([[FBSession activeSession] isOpen])
    {
        // Create an object
        NSMutableDictionary<FBOpenGraphObject> *gameLevel = [FBGraphObject openGraphObjectForPost];
        
        // specify that this Open Graph object will be posted to Facebook
        gameLevel.provisionedForPost = YES;
        
        // Add the standard object properties
        gameLevel[@"og"] = @{ @"og:type":@"This is a type",
                              @"title":@"Level Name",
                              @"url": @"http://stackoverflow.com/questions/19351737/100-conflicting-ogtype-found-in-path-nnngame-and-properties-nnngame",
                              @"score":@"12024",
                              @"levelno":@"12",
                              @"duration":@"120"
                              };
        
        // Add the properties restaurant inherits from place
        //gameLevel[@"place"] = @{ @"location" : @{ @"longitude": @"-58.381667", @"latitude":@"-34.603333"} };
        
        // Add the properties particular to the type restaurant.restaurant
//        gameLevel[@"gamelevel"] = @{@"score":@"12024",
//                                    @"levelno":@"12",
//                                    @"duration":@"120"
//                                    };
        
        NSLog(@"going to post ");
        
        // Make the Graph API request to post the object
        FBRequest *request = [FBRequest requestForPostWithGraphPath:@"me/objects/innofiedtestapp:gamelevel"
                                                        graphObject:(FBGraphObject *)@{@"object":gameLevel}];
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // Sucess! Include your code to handle the results here
                NSLog(@"result: %@", result);
                
            } else {
                // An error occurred, we need to handle the error
                // See: https://developers.facebook.com/docs/ios/errors
                NSLog(@"error: %@", error);
                
            }
        }];
    }
    else
    {
        [FBSession openActiveSessionWithAllowLoginUI: YES];
        
    }
}


-(IBAction)fetchGraphObjectForMe:(id)sender
{
    [FBRequestConnection startWithGraphPath:@"me/objects/innofiedtestapp:gamelevel"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              // handle the result
                              
                              NSLog(@"Level info = %@",result);
                              if (error) {
                                  NSLog(@"%@",error);
                              }
                          }];
}


-(IBAction)postScore:(id)sender
{
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [NSString stringWithFormat:@"%@", @"4356"], @"score",
                                     nil];
    
    NSLog(@"Fetching current score");
    
    // Get the score, and only send the updated score if it's highter
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/scores", @"675938339154902"] parameters:params HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (result && !error) {
            
            int nCurrentScore = [[[[result objectForKey:@"data"] objectAtIndex:0] objectForKey:@"score"] intValue];
            
            NSLog(@"Current score is %d", nCurrentScore);
            
            if (4356 > nCurrentScore) {
                
                NSLog(@"Posting new score of %d", 4356);
                
                [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/scores", @"675938339154902"] parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    
                    NSLog(@"Score posted");
                }];
            }
            else {
                NSLog(@"Existing score is higher - not posting new score");
            }
        }
    }];
    
    
    
    
}

-(void)updateView
{
    _logInLogOutButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _logInLogOutButton.titleLabel.text = @"Logout";
    
}

- (IBAction)getFriendScore:(id)sender {
    

    
    [FBRequestConnection startWithGraphPath:@"686032654808679/scores"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (error) {
             NSLog(@"%@",error);
         }
         else
             NSLog(@"Result = %@",result);
     }];
}

@end
