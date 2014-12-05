//
//  TCFriendInfoViewController.m
//  vChat
//
//  Created by apple on 14-11-22.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCFriendInfoViewController.h"
#import "TCFriendHeadView.h"
#import "BaseFooterView.h"
#import "TCFrinedInfoCell.h"
#import "TCchatListCtrl.h"

#import "UIImage+TC.h"

@interface TCFriendInfoViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *_titleArray;
    NSArray *_valueArray;
    
    XMPPvCardTemp *_vCard;
}

@property (weak, nonatomic) IBOutlet UITableView *infoTableView;

@end

@implementation TCFriendInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //标题数组
    _titleArray = @[@"地区", @"公司", @"部门"];
    
    //获取好友信息
    [self setupvCard];
    
    //设置头部视图
    [self setHeadView];
    
    //设置底部视图
    [self setFooterView];
}

#pragma mark - 获取好友数据
- (void)setupvCard
{
    // 1. 获取当前账号的电子名片
    _vCard = [[[TCServerManager sharedTCServerManager]vCardModule] vCardTempForJID:_jid shouldFetch:YES];
    
    // 2. 判断当前账号是否有电子名片
    if (_vCard == nil) {
        // 1. 新建电子名片
        _vCard = [XMPPvCardTemp vCardTemp];
    }
    if (_vCard.jid == nil) {
        _vCard.jid = _jid;
    }
    
    NSString *address = @"";
    if(_vCard.addresses){
        address = _vCard.addresses[0];
    }
    NSString *company = @"";
    if(_vCard.orgName){
        company = _vCard.orgName;
    }
    NSString *dept = @"";
    if(_vCard.orgUnits){
        dept = _vCard.orgUnits[0];
    }
    
    if(_valueArray == nil){
        _valueArray = @[address, company, dept];
    }
}

#pragma mark - 设置头部视图
- (void)setHeadView
{
    // 使用头部视图显示
    // 1) 照片
    NSData *photoData = [[[TCServerManager sharedTCServerManager] avatarModule] photoDataForJID:_jid];
    UIImage *headImg;
    if (photoData) {
        headImg = [UIImage imageWithData:photoData];
    }else{
        headImg = [UIImage imageNamed:kDefaultHeadImage];
    }
    
    TCFriendHeadView *headView = [[TCFriendHeadView alloc] initWithFrame:CGRectMake(0, 0, _infoTableView.frame.size.width, headImg.size.height + 2 * kHeadCellMagin)];
    headView.headImg.image = headImg;
    headView.nameLabel.text = _jid.user;
    headView.jidStrLabel.text = [@"JID: " stringByAppendingString:[_jid full]];
    if(_vCard.nickname){
        headView.nickNameLabel.text = [@"昵称: " stringByAppendingString: _vCard.nickname];
    }else{
        headView.nickNameLabel.text = @"昵称: 暂未设置";
    }
    headView.backgroundColor = UIColor(236, 236, 236, 0.5);
    _infoTableView.tableHeaderView = headView;
}

#pragma mark - 设置底部视图
- (void)setFooterView
{
    // 要在tableView底部添加一个按钮
    BaseFooterView *sendMsg = [BaseFooterView footerViewWithImage:@"seng_Message.png" highlightImage:@"bg.png" title:@"发送消息" target:self action:@selector(didSendMsgClicked:) height:44];
    
    _infoTableView.tableFooterView = sendMsg;
}

#pragma mark - 点击发送消息按钮
- (void)didSendMsgClicked:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"sendMsg" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    TCchatListCtrl *controller = (TCchatListCtrl *)segue.destinationViewController;
    
    controller.jid = _jid;
    // 取出对话方的头像数据
    TCFriendHeadView *head = (TCFriendHeadView *)_infoTableView.tableHeaderView;
    controller.bareImage = head.headImg.image;
    
    //取出我的照片
    NSString *myStr = [TCUserManager sharedTCUserManager].user.username;
    XMPPJID *myJID = [XMPPJID jidWithString:myStr];
    NSData *myPhoto = [[[TCServerManager sharedTCServerManager] avatarModule] photoDataForJID:myJID];
    controller.myImage = [UIImage imageWithData:myPhoto];
}

#pragma mark - UITableView代理方法
//分组数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //只有一组
    return 1;
}
//分组行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
        return _titleArray.count;
    return 0;
}
//每行长什么样
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCFrinedInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendInfoCell" forIndexPath:indexPath];
    
    cell.titleLabel.text = _titleArray[indexPath.row];
    cell.valueLabel.text = _valueArray[indexPath.row];
    
    return cell;
}
//选中某行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(section == 0){
        return 30;
    }
    return 0;
}

@end
