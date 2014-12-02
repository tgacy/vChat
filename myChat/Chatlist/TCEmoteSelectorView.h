//
//  TCEmoteSelectorView.h
//  myChat
//
//  Created by apple on 14-12-2.
//  Copyright (c) 2014年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TCEmoteSelectorViewDelegate <NSObject>

// 选择表情字符串
- (void)emoteSelectorViewSelectEmoteString:(NSString *)emote;
// 删除字符
- (void)emoteSelectorViewRemoveChar;

@end

@interface TCEmoteSelectorView : UIView

@property (weak, nonatomic) id <TCEmoteSelectorViewDelegate> delegate;

@end
