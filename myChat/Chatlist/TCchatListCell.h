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
@property (nonatomic,weak) IBOutlet UILabel *body;

@end
