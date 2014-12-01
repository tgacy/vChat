//
//  TCEditMyInfoViewController.m
//  vChat
//
//  Created by apple on 14-11-27.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCEditMyInfoViewController.h"

@interface TCEditMyInfoViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *contentText;

@end

@implementation TCEditMyInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1. 设置标题
    self.title = _contentTitle;
    // 2. 设置文本内容
    _contentText.text = _contentLable.text;
    
    // 3. 设置输入框的焦点
    [_contentText becomeFirstResponder];
}

#pragma mark - 文本框代理
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self save:nil];
    
    return YES;
}

#pragma mark - 保存操作
- (IBAction)save:(id)sender
{
    _contentLable.text = [_contentText.text trimString];;
    
    [_delegate editVCardViewControllerDidFinished];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
