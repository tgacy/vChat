//
//  TCchatListCtrl.m
//  vChat
//
//  Created by apple on 14/11/27.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCchatListCtrl.h"
#import "TCchatListCell.h"
#import "TCServerManager.h"

#import "TCUser.h"
#import "TCMessage.h"
#import "SVProgressHUD.h"

#import "NSDate+Utilities.h"

#import <AVFoundation/AVFoundation.h>


@interface TCchatListCtrl ()<UITableViewDelegate,UITableViewDataSource, NSFetchedResultsControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, AVAudioRecorderDelegate>
{
    NSFetchedResultsController *_fetchedResultController; //消息结果集
    NSFetchedResultsController *_userResultController;    //获取好友完整jid
    NSInteger _numberOfRows;                              //行数
    UIImage *_sendImage;                                  //存储发送的图片
    
    AVAudioRecorder *_audioRecoder;                       //录音对象
    BOOL _isInside;                                       //判断在哪释放录音
    NSDate *_recordDate;                                   //录制时间
}
@property (weak, nonatomic) IBOutlet UITableView *chatListTableview;
@property (weak, nonatomic) IBOutlet UITextField *messager;

@property (strong, nonatomic) XMPPOutgoingFileTransfer *outgoingFile;

@end

@implementation TCchatListCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.hidden=YES;
    
    if(_myImage == nil){
        _myImage = [UIImage imageNamed:kDefaultHeadImage];
    }
    
    //获取用户完整jid
    [self getUserCompleteJid:_jid];
    
    //获取消息结果集
    if (_fetchedResultController == nil)
    {
        NSManagedObjectContext *moc = [[TCServerManager sharedTCServerManager] messageContext];
        
        //数据存储实体（表）
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                                  inManagedObjectContext:moc];
        
        //设置结果的排序规则
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr=%@", [_jid bare]];
        
        //数据请求
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setFetchBatchSize:10];
        
        _fetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                       managedObjectContext:moc
                                                                         sectionNameKeyPath:nil
                                                                                  cacheName:nil];
        [_fetchedResultController setDelegate:self];
        
        
        NSError *error = nil;
        //开始请求数据
        if (![_fetchedResultController performFetch:&error])
        {
            MyLog(@"Error performing fetch: %@", error);
        }
    }
    [self controllerDidChangeContent:nil];
    
    _outgoingFile = [[XMPPOutgoingFileTransfer alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    [_outgoingFile activate:[TCServerManager sharedTCServerManager].xmppStream];
    [_outgoingFile addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)getUserCompleteJid:(XMPPJID *)jid
{
    // 1. 如果要针对CoreData做数据访问，无论怎么包装，都离不开NSManagedObjectContext
    // 实例化NSManagedObjectContext
    NSManagedObjectContext *context = [[TCServerManager sharedTCServerManager] rosterContext];
    
    // 2. 实例化NSFetchRequest
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    
    //3. 设置请求谓词 实例化一个排序
    NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sectionNum" ascending:YES];
    
    [request setSortDescriptors:@[sort1]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"jidStr=%@", [_jid bare]];
    
    //4. 数据请求
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:predicate];
    
    // 5. 实例化_fetchedResultsController
    _userResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"sectionNum" cacheName:nil];
    
    // 6. 设置代理
    _userResultController.delegate = self;
    
    // 7. 查询数据
    NSError *error = nil;
    if (![_userResultController performFetch:&error]) {
        MyLog(@"%@", error.localizedDescription);
    }else{
        XMPPUserCoreDataStorageObject *user = [_userResultController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        XMPPJID *jid = user.primaryResource.jid;
        if(jid.resource != nil)
            _jid = jid;
    }
}

#pragma mark - 数据集改变
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if(controller == _userResultController){
        XMPPUserCoreDataStorageObject *user = [_userResultController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        XMPPJID *jid = user.primaryResource.jid;
        if(jid.resource != nil)
            _jid = jid;
        else
            _jid = user.jid;
        return;
    }
    
    [_chatListTableview reloadData];
    //尝试滚动到最底下
    [self scrollToBottom];
}

#pragma - mark 滚动到底部
- (void)scrollToBottom
{
    if (_numberOfRows) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_numberOfRows - 1 inSection:0];
        [_chatListTableview scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (IBAction)sendeMessager:(UIButton *)sender
{
    TCMessage *message = [[TCMessage alloc] init];
    message.body = _messager.text;
    TCUser *user = [[TCUser alloc] init];
    user.username = [_jid bare];
    [[TCServerManager sharedTCServerManager] sendMessage:message toUser:user];
    
    _messager.text = nil;
}

#pragma mark - UITableviewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [_fetchedResultController sections];
    
    if (section < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        _numberOfRows = sectionInfo.numberOfObjects;
        return sectionInfo.numberOfObjects;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *message = [_fetchedResultController objectAtIndexPath:indexPath];
    
    TCchatListCell *cell = nil;
    if (message.isOutgoing) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"to" forIndexPath:indexPath];
        [cell.headView setBackgroundImage:_myImage forState:UIControlStateNormal];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"from" forIndexPath:indexPath];
        [cell.headView setBackgroundImage:_bareImage forState:UIControlStateNormal];
    }
    
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.time.text = message.timestamp.shortTimeString;
    
    if([message.body hasPrefix:kSendedImageStr]){
        [self drawImageAtCell:&cell withMessageBody:message.body];
        return cell;
    }
    
    [cell setMessage:message.body isOutgoing:message.isOutgoing];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *message = [_fetchedResultController objectAtIndexPath:indexPath];
    
    NSString *str = message.body;
    if([str hasPrefix:kSendedImageStr]){
        return [self drawImageAtCell:NULL withMessageBody:str];
    }else if ([str hasPrefix:kSendedRecordStr]){
        UIImage *image = [UIImage imageNamed:@"SenderVoiceNodePlaying"];
        return image.size.height + 20.0 + 50.0;
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentLeft;
    
    NSDictionary *dict = @{NSFontAttributeName:[UIFont systemFontOfSize:17], NSParagraphStyleAttributeName:style};
    CGSize size = [str sizeWithAttributes:dict];
    
    CGSize vSize = self.view.bounds.size;
    //只有一行
    if (vSize.width - 150 >= size.width) {
        return 50.0 + size.height + 20;
    }
    else {
        CGRect rect = [str boundingRectWithSize:CGSizeMake(vSize.width - 150, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:dict context:NULL];
        
        return 50.0 + rect.size.height + 20;
    }
}

#pragma mark - 求消息中图片的高度
//发送图片
- (CGFloat)drawImageAtCell:(TCchatListCell **)ListCell withMessageBody:(NSString *)body
{
    NSString *imageName = [[body componentsSeparatedByString:@"@"] lastObject];
    NSString *imagePath = [kDocumentDirectory stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if(image == nil){
        image = [UIImage imageNamed:@"Fav_nopic"];
    }
    image = [self compressImage:image];
    CGSize size = [image size];
    if(ListCell != NULL){
        TCchatListCell *cell = *ListCell;
        [cell.message setImage:nil forState:UIControlStateNormal];
        [cell.message setBackgroundImage:image forState:UIControlStateNormal];
        [cell.message setTitle:@"" forState:UIControlStateNormal];
        cell.messageWeightConstraint.constant = size.width;
        cell.messageHeightConstraint.constant = size.height;
    }
    return size.height + 35.0 + 20.0;
}
//发送录音
//- (CGFloat)drawRecordImageAtCell:(TCchatListCell **)ListCell withMessageBody:(NSString *)body
//{
//    NSString *recordName = [[body componentsSeparatedByString:@"@"] lastObject];
//    NSString *recordPath = [kDocumentDirectory stringByAppendingPathComponent:recordName];
//}

#pragma mark 点击添加按钮
- (IBAction)didAddButtonClicked:(id)sender
{
    if(!_jid.resource){
        [SVProgressHUD showErrorWithStatus:@"对方不在线或者jid缺少resource部分"];
        return ;
    }
    
    // 如何判断摄像头可用
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        
        [self presentViewController:picker animated:YES completion:nil];
        
    } else {
        NSLog(@"摄像头不可用");
    }
}

#pragma mark - UIImagePicker代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 1. 获取选择的图像
    _sendImage = info[UIImagePickerControllerEditedImage];
    
    // 2. 关闭照片选择器
    __weak typeof(self) mySelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"是否发送原图" delegate:mySelf cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        [alert show];
    }];
}

#pragma mark - 发送文件代理
- (void)xmppOutgoingFileTransfer:(XMPPOutgoingFileTransfer *)sender didFailWithError:(NSError *)error
{
    MyLog(@"发送文件失败: %@", error);
    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
}

- (void)xmppOutgoingFileTransferDidSucceed:(XMPPOutgoingFileTransfer *)sender
{
    MyLog(@"发送文件成功");
    [SVProgressHUD showSuccessWithStatus:@"发送文件成功"];
    
    //发送消息
    NSString *filePath = sender.outgoingFileName;
    TCMessage *message = [[TCMessage alloc] init];
    if([sender.outgoingFileDescription isEqualToString:@"image"])
        message.body = [kSendedImageStr stringByAppendingString:filePath];
    else if([sender.outgoingFileDescription hasPrefix:@"record"]){
        NSString *timeStr = [[sender.outgoingFileDescription componentsSeparatedByString:@"@"] lastObject];
        message.body = [kSendedRecordStr stringByAppendingFormat:@"%@@%@", timeStr, filePath];
    }
    TCUser *user = [[TCUser alloc] init];
    user.username = [_jid bare];
    [[TCServerManager sharedTCServerManager] sendMessage:message toUser:user];
}

#pragma mark - UIAlertView代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //发送压缩图
    if (0 == buttonIndex) {
        _sendImage = [self compressImage:_sendImage];
    }
    
    //存储图片
    NSString *imageName = [[TCServerManager sharedTCServerManager].xmppStream generateUUID];
    NSString *imagePath = [kDocumentDirectory stringByAppendingPathComponent:imageName];
    
    NSData *imageData = UIImagePNGRepresentation(_sendImage);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [imageData writeToFile:imagePath atomically:YES];
    });
    
    NSError *error;
    if(![_outgoingFile sendData:imageData named:imageName toRecipient:_jid
                    description:@"image" error:&error]){
        MyLog(@"%@", error);
    };
}

#pragma mark - 压缩图片
- (UIImage *)compressImage:(UIImage *)image
{
    CGSize imageSize = image.size;
    if(imageSize.width > kSendImgWidth){
        imageSize.height = kSendImgWidth * imageSize.height / imageSize.width;
        imageSize.width = kSendImgWidth;
        UIGraphicsBeginImageContext(imageSize);
        [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

#pragma mark - 销毁
- (void)dealloc
{
    [_outgoingFile deactivate];
    [_outgoingFile removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    _outgoingFile = nil;
}

#pragma mark - 按住说话按钮的action方法
- (IBAction)didRecordBtnTouchDown:(id)sender {
    MyLog(@"Touch Down");
    _isInside = NO;
    if(!_jid.resource){
        [SVProgressHUD showErrorWithStatus:@"对方不在线或者jid缺少resource部分"];
        return ;
    }
    [sender setTitle:@"松开结束" forState:UIControlStateHighlighted];
    NSDictionary *settings = [self audioRecordingSettings];
    NSString *recordName = [[[TCServerManager sharedTCServerManager].xmppStream generateUUID] stringByAppendingString:@".m4a"];
    NSURL *recordUrl = [NSURL fileURLWithPath:[kDocumentDirectory stringByAppendingPathComponent:recordName]];
    NSError *error = nil;
    _audioRecoder = [[AVAudioRecorder alloc] initWithURL:recordUrl settings:settings error:&error];
    if(error != nil){
        MyLog(@"%@", error);
    }
    if(_audioRecoder != nil){
        _audioRecoder.delegate = self;
        [_audioRecoder recordForDuration:60.0];
        [_audioRecoder prepareToRecord];
        [_audioRecoder record];
        _recordDate = [NSDate date];
    }
}

- (IBAction)didRecordBtnTouchDragEnter:(id)sender {
    MyLog(@"Drag Enter");
    [sender setTitle:@"松开结束" forState:UIControlStateHighlighted];
}

- (IBAction)didRecordBtnTouchDragExit:(id)sender {
    MyLog(@"Drag Exit");
    [sender setTitle:@"松开手指, 取消发送" forState:UIControlStateHighlighted];
}

- (IBAction)didRecordBtnTouchDragInside:(id)sender {
    MyLog(@"Drag Inside");
}

- (IBAction)didRecordBtnTouchDragOutside:(id)sender {
    MyLog(@"Drag Outside");
}

- (IBAction)didRecordBtnTouchUpInside:(id)sender {
    MyLog(@"Touch Up Inside");
    //停止录音
    _isInside = YES;
    [_audioRecoder stop];
}

- (IBAction)didRecordBtnTouchUpOutside:(id)sender {
    MyLog(@"Touch Up Outside");
    //停止并删除录音
    _isInside = NO;
    [_audioRecoder stop];
}

#pragma mark - 录音对象相关方法
- (NSDictionary *)audioRecordingSettings{
    NSDictionary *result = nil;
    NSMutableDictionary *settings = [[NSMutableDictionary
                                      alloc] init];
    [settings setValue:[NSNumber
                        numberWithInteger:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
    [settings setValue:[NSNumber numberWithFloat: 44100.0f] forKey:AVSampleRateKey];
    [settings setValue:[NSNumber numberWithInteger:1] forKey:AVNumberOfChannelsKey];
    [settings setValue:[NSNumber numberWithInteger:AVAudioQualityLow] forKey:AVEncoderAudioQualityKey];
    result = [NSDictionary dictionaryWithDictionary:settings];
    return result;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if(flag){
        if(_isInside){
            //发送录音消息
            NSDate *date = [NSDate date];
            NSTimeInterval timeinterval = [date timeIntervalSinceDate:_recordDate];
            if(timeinterval < 0.5)
                return;
            NSInteger timeDuration = round(timeinterval);
            NSString *recordFileName = [[[_audioRecoder.url absoluteString] componentsSeparatedByString:@"/"] lastObject];
            
            NSData *recordData = [NSData dataWithContentsOfFile:[_audioRecoder.url resourceSpecifier]];
            
            if(recordData != nil && recordData.length != 0){
                [_outgoingFile sendData:recordData named:recordFileName toRecipient:_jid description:[@"record@" stringByAppendingString:[NSString stringWithFormat:@"%ld", timeDuration]] error:nil];
            }else{
                MyLog(@"发送录音不成功");
            }
        }else{
            //删除录音文件
            [_audioRecoder deleteRecording];
        }
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    MyLog(@"录音错误: %@", error);
}
@end
