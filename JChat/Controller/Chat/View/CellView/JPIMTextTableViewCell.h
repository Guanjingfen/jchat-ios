//
//  JPIMTextTableViewCell.h
//  JPush IM
//
//  Created by Apple on 15/1/5.
//  Copyright (c) 2015年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatModel.h"
#import <JMessage/JMessage.h>

@protocol selectHeadViewDelegate <NSObject>
-(void)selectHeadView:(ChatModel *)model;
@end

@interface JPIMTextTableViewCell : UITableViewCell<UIAlertViewDelegate>
@property (strong, nonatomic) ChatModel *model;
@property (nonatomic,strong)  UIActivityIndicatorView *stateView;
@property (strong, nonatomic)  UIImageView *sendFailView;
@property (nonatomic,strong)   UIImageView *chatView;
@property (nonatomic,strong)   UIImageView *chatbgView;
@property (nonatomic,strong)   UIImageView *headImgView;
@property (nonatomic,strong)   UILabel *contentLabel;
@property (assign, nonatomic)  id<selectHeadViewDelegate> delegate;
@property (nonatomic,strong)   JMSGContentMessage *sendFailMessage;
@property (nonatomic,strong)   JMSGConversation *conversation;
@property (nonatomic,strong)   JMSGContentMessage *message;

- (void)setCellData:(ChatModel *)model delegate:(id )delegate;

@end
