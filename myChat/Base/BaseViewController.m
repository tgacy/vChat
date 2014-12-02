//
//  BaseViewController.m
//  营内聊
//
//  Created by apple on 14-11-18.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "BaseViewController.h"
#import "UIView+firstResponder.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //监听键盘弹出事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    //监听键盘隐藏事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    [self.view addGestureRecognizer:tap];
}

#pragma mark - 键盘即将弹出事件处理
- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyBoardInfo = notification.userInfo;
    UIView *firstResponder = [self.view firstResponder];
    if(firstResponder){
        CGRect frame = firstResponder.frame;
        if(firstResponder.superview != self.view){
            frame = [firstResponder convertRect:frame toView:self.view];
        }
        CGFloat viewY = CGRectGetMaxY(frame);
        CGFloat keyBoardY = [keyBoardInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue].origin.y;
        CGFloat delta = keyBoardY - viewY;
        if(delta < 0){
            [UIView animateWithDuration:0.5 animations:^{
                self.view.transform = CGAffineTransformMakeTranslation(0, delta);
            } completion:nil];
        }
    }
}

#pragma mark - 键盘即将隐藏事件
- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.5 animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:nil];
}

#pragma mark - 点击屏幕关闭键盘
- (void)didTapView:(UITapGestureRecognizer *)tapGesture
{
    [self.view endEditing:YES];
}

#pragma mark - 在dealloc中移除所有关注的通知
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
