//
//  TCSign-inCtrl.m
//  vChat
//
//  Created by apple on 14/11/22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCSign-inCtrl.h"

#import "TCUser.h"
#import "TCServerManager.h"

#import "Common.h"

#import "SVProgressHUD.h"


@interface TCSign_inCtrl ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@end

@implementation TCSign_inCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [TCServerManager sharedTCServerManager].willStartRequest=^(TCServerState state)
    {
        if (state==kLoginServerState) {
            [SVProgressHUD showProgress:0];
        }
    };
    [TCServerManager sharedTCServerManager].didFinishedRequest=^(TCServerState state,TCRequestErrorCode code)
    {
        if (state==kLoginServerState&&kRequestOK==code) {
            [SVProgressHUD showProgress:1];
            UIStoryboard *storyboard=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.view.window.rootViewController=[storyboard instantiateInitialViewController];
        }
        else {
            [SVProgressHUD showErrorWithStatus:@"登录失败，请检查你的用户名和密码"];
        }
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)login:(UIButton *)sender {
    if (_username.text.length&&_password.text.length) {
        TCUser *user=[[TCUser alloc]init];
        user.username=[NSString stringWithFormat:@"%@@%@",_username.text,kHostName];
        user.password=_password.text;
        user.myJidResource = _username.text;
        [[TCServerManager sharedTCServerManager] login:user];
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
