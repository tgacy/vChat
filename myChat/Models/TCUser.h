//
//  TCUser.h
//  vChat
//
//  Created by apple on 14-11-21.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCUser : NSObject

@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *password;

@property (copy, nonatomic) NSString *email;
@property (copy, nonatomic) NSString *phone;

@property (strong, nonatomic) UIImage *photo;

@property (copy, nonatomic) NSString *myJidResource;
@end
