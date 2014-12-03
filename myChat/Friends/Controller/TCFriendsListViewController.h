//
//  TCFriendsListViewController.h
//  vChat
//
//  Created by apple on 14-11-22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BaseViewController.h"

@class NSFetchedResultsController;

@interface TCFriendsListViewController : UIViewController

@property (strong, nonatomic) void (^didConfirmAddFriend)(NSFetchedResultsController *controller);

@end
