//
//  TCchatListCell.h
//  vChat
//
//  Created by apple on 14/11/27.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCchatListCell : UITableViewCell
@property (nonatomic,weak) IBOutlet UIButton *headView;
@property (nonatomic,weak) IBOutlet UILabel *time;

@property (nonatomic,weak) IBOutlet UIButton *message;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageWeightConstraint;

- (void)setMessage:(NSString *)message isOutgoing:(BOOL)isOutgoing;

@end
