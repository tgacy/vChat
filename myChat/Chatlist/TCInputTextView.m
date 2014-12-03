//
//  TCInputTextView.m
//  vChat
//
//  Created by apple on 14/11/26.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import "TCInputTextView.h"
#import "TCEmoteSelectorView.h"

@interface TCInputTextView() <TCEmoteSelectorViewDelegate>

// 表情选择视图
@property (strong, nonatomic) TCEmoteSelectorView *emoteView;

// 输入文本
@property (weak, nonatomic) IBOutlet UITextField *inputText;
// 录音按钮
@property (weak, nonatomic) IBOutlet UIButton *recorderButton;
// 切换录音模式按钮
@property (weak, nonatomic) IBOutlet UIButton *voiceButton;
// 表情按钮
@property (weak, nonatomic) IBOutlet UIButton *emoteButton;
// 添加按钮
@property (weak, nonatomic) IBOutlet UIButton *addButton;
//发送按钮
@property (weak, nonatomic) IBOutlet UIButton *sendMessage;

// 点击声音切换按钮
- (IBAction)clickVoice:(UIButton *)button;
// 点击表情切换按钮
- (IBAction)clickEmote:(UIButton *)button;

@end

@implementation TCInputTextView

- (void)awakeFromNib
{
    // 设置录音按钮的背景图片拉伸效果
    UIImage *image = [UIImage imageNamed:@"VoiceBtn_Black"];
    image = [image stretchableImageWithLeftCapWidth:image.size.width * 0.5 topCapHeight:image.size.height * 0.5];
    UIImage *imageHL = [UIImage imageNamed:@"VoiceBtn_BlackHL"];
    imageHL = [imageHL stretchableImageWithLeftCapWidth:imageHL.size.width * 0.5 topCapHeight:imageHL.size.height * 0.5];
    
    [_recorderButton setBackgroundImage:image forState:UIControlStateNormal];
    [_recorderButton setBackgroundImage:imageHL forState:UIControlStateHighlighted];
    
    // 实例化表情选择视图
    _emoteView = [[TCEmoteSelectorView alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
    // 设置代理
    _emoteView.delegate = self;
}

#pragma mark 设置按钮的图像
- (void)setButton:(UIButton *)button imgName:(NSString *)imgName imgHLName:(NSString *)imgHLName
{
    UIImage *image = [UIImage imageNamed:imgName];
    UIImage *imageHL = [UIImage imageNamed:imgHLName];
    
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:imageHL forState:UIControlStateHighlighted];
}

#pragma mark - Actions
#pragma mark 点击声音切换按钮
- (void)clickVoice:(UIButton *)button
{
    // 1 设置按钮的tag
    button.tag = !button.tag;
    
    // 2 显示录音按钮
    _recorderButton.hidden = !button.tag;
    // 3 隐藏输入文本框
    _inputText.hidden = button.tag;
    
    // 4. 判断当前输入状态，如果是文本输入，显示录音按钮，同时关闭键盘
    if (button.tag) {
        // 1) 关闭键盘
        [_inputText resignFirstResponder];
        
        // 2) 切换按钮图标，显示键盘图标
        [self setButton:button imgName:@"ToolViewInputText" imgHLName:@"ToolViewInputTextHL"];
        [self setButton:_emoteButton imgName:@"ToolViewEmotion" imgHLName:@"ToolViewEmotionHL"];
    } else {
        // 打开文本录入
        // 1) 切换按钮图标，显示录音图标
        [self setButton:button imgName:@"ToolViewInputVoice" imgHLName:@"ToolViewInputVoiceHL"];
        
        // 2) 打开键盘
        [_inputText becomeFirstResponder];
        // 显示系统默认键盘
        [_inputText setInputView:nil];
        _emoteButton.tag = !_emoteButton.tag;
        [_inputText reloadInputViews];
    }
}

#pragma mark 点击表情切换按钮
- (void)clickEmote:(UIButton *)button
{
    // 1. 如果当前正在录音，需要切换到文本状态
    if (!_recorderButton.hidden) {
        [self clickVoice:_voiceButton];
    }
    
    // 2. 判断当前按钮的状态，如果是输入文本，替换输入视图(选择表情)
    // 1) 设置按钮的tag
    button.tag = !button.tag;
    
    // 2) 激活键盘
    [_inputText becomeFirstResponder];
    
    if (button.tag) {
        // 显示表情选择视图
        [_inputText setInputView:_emoteView];
        
        // 切换按钮图标，显示键盘选择图像
        [self setButton:button imgName:@"ToolViewInputText" imgHLName:@"ToolViewInputTextHL"];
    } else {
        // 显示系统默认键盘
        [_inputText setInputView:nil];
        
        // 切换按钮图标，显示表情选择图像
        [self setButton:button imgName:@"ToolViewEmotion" imgHLName:@"ToolViewEmotionHL"];
    }
    
    // 3. 刷新键盘的输入视图
    [_inputText reloadInputViews];
}

#pragma mark - 表情选择视图代理方法
// 拼接表情字符串
- (void)emoteSelectorViewSelectEmoteString:(NSString *)emote
{
    // 拼接现有文本
    // 1. 取出文本
    NSMutableString *strM = [NSMutableString stringWithString:_inputText.text];
    
    // 2. 拼接字符串
    [strM appendString:emote];
    
    // 3. 设置文本
    _inputText.text = strM;
    
    [self inputTextDidChanged:_inputText];
}

// 删除字符串
- (void)emoteSelectorViewRemoveChar
{
    // 1. 取出文本
    NSString *str = _inputText.text;
    
    // 2. 删除最末尾的字符，并设置文本
    if(str.length == 0){
        return ;
    }
    _inputText.text =  [str substringToIndex:(str.length - 1)];
    
    [self inputTextDidChanged:_inputText];
}

#pragma mark - 文本框内容改变事件
- (IBAction)inputTextDidChanged:(id)sender {
    UITextField *inputText = (UITextField *)sender;
    if([inputText isFirstResponder]){
        if([inputText.text trimString].length == 0){
            _sendMessage.hidden = YES;
            _addButton.hidden = NO;
        }else{
            _addButton.hidden = YES;
            _sendMessage.hidden = NO;
        }
    }else{
        _sendMessage.hidden = YES;
        _addButton.hidden = NO;
    }
}

@end
