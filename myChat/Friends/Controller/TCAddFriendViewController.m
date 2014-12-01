//
//  TCAddFriendViewController.m
//  vChat
//
//  Created by apple on 14-11-22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCAddFriendViewController.h"
#import "TCFriendsListViewController.h"
#import "TCServerManager.h"
#import "SVProgressHUD.h"

@interface TCAddFriendViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *findNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *myJIDLabel;

@end

@implementation TCAddFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _myJIDLabel.text = [TCUserManager sharedTCUserManager].user.username;
}

#pragma mark - UITextField代理
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self didConfirmClicked:nil];
    return YES;
}

- (IBAction)didConfirmClicked:(id)sender
{
    NSString *findStr = [_findNameLabel.text trimString];
    if([findStr isEmptyString]){
        [SVProgressHUD showErrorWithStatus:@"输入JID不能为空!"];
        _findNameLabel.text = @"";
        return;
    }
    
    TCUser *user = [[TCUser alloc] init];
    user.username = findStr;
    _findNameLabel.text = @"";
    
    //验证查找字符串
    if(![self validateString:user.username])
        return ;
    
    //开始请求
    [SVProgressHUD showProgress:0.0 status:@"" maskType:SVProgressHUDMaskTypeClear];
    
    //设置block回调对象
    NSArray *array = self.navigationController.viewControllers;
    NSUInteger count = array.count;
    TCFriendsListViewController *friendListCtrl = array[count - 2];
    friendListCtrl.didConfirmAddFriend = ^(NSFetchedResultsController *controller){
        for(id <NSFetchedResultsSectionInfo> info in controller.sections){
            if([[info name] integerValue] == 2){
                for(XMPPUserCoreDataStorageObject *user in [info objects]){
                    if(user.jid.user.length)
                        continue;
                    else{
                        //不存在请求时
                        [[[TCServerManager sharedTCServerManager] xmppRoster] removeUser:user.jid];
                        [SVProgressHUD showErrorWithStatus:@"找不到该好友"];
                        return;
                    }
                }
                break;
            }
        }
        //请求成功
        [SVProgressHUD showSuccessWithStatus:@"请求发送成功, 等待对方验证"];
    };
    
    //发送请求
    [[TCServerManager sharedTCServerManager] addFriend:user];
}

#pragma mark - 验证查找字符串
- (BOOL)validateString:(NSString *)findStr
{
    // 1. 判断是否与当前用户相同
    if ([findStr isEqualToString:[TCUserManager sharedTCUserManager].user.username]) {
        [SVProgressHUD showErrorWithStatus:@"自己不能添加自己"];
        
        return NO;
    }
    
    // 2. 判断是否已经是自己的好友
    // 注释：userExistsWithJID方法仅用于检测指定的JID是否是用户的好友，而不是检测是否是合法的JID账户
    if ([[[TCServerManager sharedTCServerManager] xmppRosterStorage] userExistsWithJID:[XMPPJID jidWithString:findStr] xmppStream:[[TCServerManager sharedTCServerManager] xmppStream]]) {
        [SVProgressHUD showErrorWithStatus:@"该用户已经是好友，无需添加！"];
        return NO;
    }
    
    return YES;
}

@end
