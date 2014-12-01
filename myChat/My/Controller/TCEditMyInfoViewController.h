//
//  TCEditMyInfoViewController.h
//  vChat
//
//  Created by apple on 14-11-27.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCEditMyInfoViewController;

@protocol TCEditVCardViewControllerDelegate <NSObject>

- (void)editVCardViewControllerDidFinished;

@end

@interface TCEditMyInfoViewController : UIViewController

@property (weak, nonatomic) id<TCEditVCardViewControllerDelegate> delegate;

// 内容标题
@property (strong, nonatomic) NSString *contentTitle;
// 内容标签
@property (weak, nonatomic) UILabel *contentLable;

@end
