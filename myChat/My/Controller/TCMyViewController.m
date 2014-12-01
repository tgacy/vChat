//
//  TCMyViewController.m
//  vChat
//
//  Created by apple on 14-11-22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCMyViewController.h"
#import "TCServerManager.h"
#import "BaseHeadInfoView.h"
#import "BaseFooterView.h"

@interface TCMyViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@end

@implementation TCMyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //设置头部视图
    [self setHeaderView];
    
    //设置底部视图
    [self setFooterView];
}

- (void)viewWillAppear:(BOOL)animated
{
    BaseHeadInfoView *headView = (BaseHeadInfoView *)_myTableView.tableHeaderView;
    XMPPJID *jid = [XMPPJID jidWithString:[TCUserManager sharedTCUserManager].user.username];
    
    NSData *photoData = [[[TCServerManager sharedTCServerManager] avatarModule] photoDataForJID:jid];
    UIImage *headImg;
    if (photoData) {
        headImg = [UIImage imageWithData:photoData];
    }else{
        headImg = [UIImage imageNamed:kDefaultHeadImage];
    }
    headView.headImg.image = headImg;
    headView.nameLabel.text = jid.user;
    headView.jidStrLabel.text = [@"JID: " stringByAppendingString:[jid full]];
}

#pragma mark - 设置头部, 底部视图
- (void)setHeaderView
{
    BaseHeadInfoView *headView = [[BaseHeadInfoView alloc] initWithFrame:CGRectMake(0, 0, _myTableView.frame.size.width, kDefaultHeadHeight + 2 * kHeadCellMagin)];
    headView.backgroundColor = UIColor(236, 236, 236, 0.5);
    _myTableView.tableHeaderView = headView;
    
    //添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didHeadViewTaped:)];
    [headView addGestureRecognizer:tap];
}

- (void)setFooterView
{
    BaseFooterView *logout = [BaseFooterView footerViewWithImage:@"common_button_big_red.png" highlightImage:@"common_button_big_red_highlighted.png" title:@"退出登录" target:self action:@selector(didLogoutClicked:) height:44];
    _myTableView.tableFooterView = logout;
}

#pragma mark - 点击头部视图
- (void)didHeadViewTaped:(UITapGestureRecognizer *)tap
{
    [self performSegueWithIdentifier:@"MyInfoSegue" sender:self];
}

#pragma mark - 退出登录
- (void)didLogoutClicked:(UIButton *)sender
{
    MyLog(@"~~~退出登录~~~");
    //调到登录页面
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewCtrl = [storyboard instantiateViewControllerWithIdentifier:@"TCWelcomeCtrl"];
    [UIApplication sharedApplication].keyWindow.rootViewController = viewCtrl;
    //退出登录
    [[TCServerManager sharedTCServerManager] logout];
}

#pragma mark - UITableView代理方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    return cell;
}

@end
