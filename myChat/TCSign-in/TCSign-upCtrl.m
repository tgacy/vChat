//
//  TCSign-upCtrl.m
//  vChat
//
//  Created by apple on 14/11/22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCSign-upCtrl.h"

#import "TCServerManager.h"
#import "TCUser.h"

#import "SVProgressHUD.h"
#import "Common.h"

@interface TCSign_upCtrl ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *phone;

@end

@implementation TCSign_upCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [TCServerManager sharedTCServerManager].willStartRequest=^(TCServerState state)
    {
        if (state==kRegisterServerState) {
            [SVProgressHUD showProgress:0];
        }
    };
    [TCServerManager sharedTCServerManager].didFinishedRequest=^(TCServerState state,TCRequestErrorCode code)
    {
        if (kRegisterServerState == state && kRequestOK == code) {
            [SVProgressHUD showProgress:1];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.view.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"TCWelcomeCtrl"];
        }
        else {
            [SVProgressHUD showErrorWithStatus:@"注册失败，请检查网络"];
        }
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)creatAccount:(UIButton *)sender {
    if (_username.text.length&&_password.text.length) {
        TCUser *user=[[TCUser alloc]init];
        user.username=[NSString stringWithFormat:@"%@@%@",_username.text,kHostName];
        user.password=_password.text;
        user.email=_email.text;
        user.phone=_phone.text;
        [[TCServerManager sharedTCServerManager] registerUser:user];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:@"请输入用户名或密码！"];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
