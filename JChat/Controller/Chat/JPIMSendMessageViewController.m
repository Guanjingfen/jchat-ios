//
//  JPIMSendMessageViewController.m
//  JPush IM
//
//  Created by Apple on 14/12/26.
//  Copyright (c) 2014年 Apple. All rights reserved.
//

#import "JPIMSendMessageViewController.h"
#import "ChatModel.h"
#import "JPIMCommon.h"
#import "JPIMImgTableViewCell.h"
#import "MJPhoto.h"
#import "MJPhotoBrowser.h"
#import "JPIMVoiceTableViewCell.h"
#import "JPIMFileManager.h"
#import "JPIMShowTimeCell.h"
#import "JPIMFileManager.h"
#import "XHMacro.h"
#import "JPIMFileManager.h"
#import "JPIMFileManager.h"
#import "JPIMDetailsInfoViewController.h"
#import "JPIMTextTableViewCell.h"
#import "JPIMGroupSettingCtl.h"
#import "AppDelegate.h"
#import "NSObject+TimeConvert.h"
#import "MBProgressHUD+Add.h"
#import "UIImage+ResizeMagick.h"
#import "JPIMPersonViewController.h"
#import "JPIMFriendDetailViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "MobClick.h"
#import <JMessage/JMessage.h>
#define interval 60*2

@interface JPIMSendMessageViewController ()
{
    @private
    NSMutableArray *_messageDataArr;
    NSMutableArray *_imgDataArr;
   __block JMSGConversation *_conversation;
}
@end

@implementation JPIMSendMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    JPIMLog(@"Action");
    if (self.user) {
        self.targetName = self.user.username;
    }else if (_conversation){
        self.targetName = _conversation.targetName;
    }else {
        JPIMLog(@"聊天未知错误");
    }
    if (!_conversation) {
        if (self.user) {
             [JMSGConversationManager createConversation:self.user.username withType:kSingle completionHandler:^(id resultObject, NSError *error) {
                 _conversation = (JMSGConversation  *)resultObject ;
                 [_conversation resetUnreadMessageCountWithCompletionHandler:^(id resultObject, NSError *error) {
                     if (error == nil) {
                         JPIMLog(@"消息清零成功");
                     }else {
                         JPIMLog(@"消息清零失败");
                     }
                 }];
                 
            }];
        }
    }
    __weak __typeof(self)weakSelf = self;
    if (!self.user) {
        [JMSGUserManager getUserInfoWithUsername:_conversation.targetName completionHandler:^(id resultObject, NSError *error) {
            if (error == nil) {
                JPIMMAINTHEAD(^{
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    strongSelf.user = ((JMSGUser *) resultObject);
                    if (strongSelf.user.noteName != nil && ![strongSelf.user.noteName isEqualToString:KNull]) {
                        strongSelf.title = strongSelf.user.noteName;
                    } else if (strongSelf.user.nickname != nil && ![strongSelf.user.nickname isEqualToString:KNull]) {
                        strongSelf.title = strongSelf.user.nickname;
                    } else {
                        strongSelf.title = strongSelf.user.username;
                    }
                });
            } else {
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                JPIMMAINTHEAD(^{
                    strongSelf.title = _conversation.targetName;
                    JPIMLog(@"没有这个用户");
                });
            }
        }];
        
    } else {
      if (self.user.noteName != nil && ![self.user.noteName isEqualToString:KNull]) {
            self.title = self.user.noteName;
        }else if (self.user.nickname !=nil && ![self.user.nickname isEqualToString:KNull]) {
            self.title = self.user.nickname;
        }else {
            self.title = self.user.username;
        }
    }
    _messageDataArr =[[NSMutableArray alloc] init];
    _imgDataArr =[[NSMutableArray alloc] init];
    [self getAllMessage];
    self.messageTableView =[[UITableView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight+kStatusBarHeight, kApplicationWidth,kApplicationHeight-45-(kNavigationBarHeight)) style:UITableViewStylePlain];
    self.messageTableView.userInteractionEnabled = YES;
    self.messageTableView.showsVerticalScrollIndicator=NO;
    self.messageTableView.delegate = self;
    self.messageTableView.dataSource = self;
    self.messageTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.messageTableView.backgroundColor = [UIColor colorWithRed:236/255.0 green:237/255.0 blue:240/255.0 alpha:1];
    [self.view addSubview:self.messageTableView];
    
    NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"JPIMToolBar"owner:self options:nil];
    self.toolBar = [nib objectAtIndex:0];
    self.toolBar.contentMode = UIViewContentModeRedraw;
    [self.toolBar setFrame:CGRectMake(0, self.view.bounds.size.height-45, self.view.bounds.size.width, 45)];
    self.toolBar.delegate = self;
    [self.toolBar setUserInteractionEnabled:YES];
    [self.view addSubview:self.toolBar];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UIButton *rightBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setFrame:CGRectMake(0, 0, 46, 46)];
    [rightBtn setImage:[UIImage imageNamed:@"setting_55"] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(addFriends) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];//为导航栏添加右侧按钮

    UIButton *leftBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(0, 0, 30, 30)];
    [leftBtn setImage:[UIImage imageNamed:@"login_15"] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];//为导航栏添加左侧按钮
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    UITapGestureRecognizer *gesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self.view addGestureRecognizer:gesture];
    NSArray *temXib = [[NSBundle mainBundle]loadNibNamed:@"JPIMMoreView"owner:self options:nil];
    self.moreView = [temXib objectAtIndex:0];
    self.moreView.delegate=self;
    if ([self checkDevice:@"iPad"] || kApplicationHeight <= 480) {
        [self.moreView setFrame:CGRectMake(0, kScreenHeight, self.view.bounds.size.width, 300)];
    }else {
        [self.moreView setFrame:CGRectMake(0, kScreenHeight, self.view.bounds.size.width, 200)];
    }
    [self.view addSubview:self.moreView];
    [self addNotification];
}

- (void)receiveNotificationSkipToChatPageView:(NSNotification *)no {
    NSDictionary *apnsDic = [no object];
    NSString *targetNameStr = [apnsDic[@"aps"] objectForKey:@"alert"];
    NSString *targetName = [[targetNameStr componentsSeparatedByString:@":"] objectAtIndex:0];
    if ([targetName isEqualToString:_conversation.targetName] || [targetName isEqualToString:_conversation.targetName]) {
        return;
    }
  if ([targetName isEqualToString:[JMSGUserManager getMyInfo].username]) {
    return;
  }
    [JMSGConversationManager getConversation:targetName completionHandler:^(id resultObject, NSError *error) {
        if (error == nil) {
            _conversation = resultObject;
            [_conversation resetUnreadMessageCountWithCompletionHandler:^(id resultObject, NSError *error) {
                if (error == nil) {
                    JPIMLog(@"清零成功");
                }else {
                    JPIMLog(@"清零失败");
                }
            }];
            [JMSGUserManager getUserInfoWithUsername:targetName completionHandler:^(id resultObject, NSError *error) {
                self.user = resultObject;
                [self getAllMessage];
                self.title = targetName;
            }];
        }else {
            
        }
    }];
}

#pragma mark --发送消息响应
- (void)sendMessageResponse:(NSNotification *)response {
    JPIMMAINTHEAD(^{
        NSDictionary *responseDic = [response userInfo];
        JMSGMessage *message = [responseDic objectForKey:JMSGSendMessageObject];
        NSError *error = [responseDic objectForKey:JMSGSendMessageError];
        if (error == nil) {
            JPIMLog(@"Sent message Response:%@",message);
        }else {
            JPIMLog(@"Sent message Response:%@",message);
            JPIMLog(@"Sent message Response error:%@",error);
            if (error.code == 800013) {
                JPIMLog(@"用户登出了");
            }
        }
        ChatModel *model ;
        for (NSInteger i=0; i < [_messageDataArr count]; i++) {
            model = [_messageDataArr objectAtIndex:i];
            if ([message.messageId isEqualToString:model.messageId]) {
                model.messageStatus = [message.status integerValue];
            }
        }
        [_messageTableView reloadData];
    });
}

- (void)changeMessageState:(JMSGMessage *)message {
    
    for (NSInteger i=0; i<[_messageDataArr count]; i++) {
        ChatModel *model = [_messageDataArr objectAtIndex:i];
        if ([message.messageId isEqualToString:model.messageId]) {
            model.messageStatus = [message.status integerValue];
            [self.messageTableView reloadData];
        }
    }
}

- (void)setbadge {
    NSInteger count = 0;
    for (NSInteger i=0; i< [self.conversationList count] ; i++) {
        JMSGConversation *conversation = [self.conversationList objectAtIndex:i];
        count = count + [conversation.unread_cnt integerValue];
    }
    [JPUSHService setBadge:count];
    JPIMLog(@"setBadge:%ld",count);
}

- (bool)checkDevice:(NSString*)name {
    NSString* deviceType = [UIDevice currentDevice].model;
    JPIMLog(@"deviceType = %@", deviceType);
    NSRange range = [deviceType rangeOfString:name];
    return range.location != NSNotFound;
}

- (void)getAllMessage {
    __block NSMutableArray * arrList;
    [_messageDataArr removeAllObjects];
    [_conversation getAllMessageWithCompletionHandler:^(id resultObject, NSError *error) {
        JPIMMAINTHEAD((^{
        arrList = resultObject;
        for (NSInteger i=0; i< [arrList count]; i++) {
            JMSGMessage *message =[arrList objectAtIndex:i];
            ChatModel *model =[[ChatModel alloc]init];
            model.messageId = message.messageId;
            model.conversation = _conversation;
            model.messageStatus = [message.status integerValue];
            model.displayName = message.display_name;
            model.readState = YES;
            JMSGUser *user = [JMSGUserManager getMyInfo];
            if ([message.target_name isEqualToString :user.username]) {
                model.who=NO;
                model.avatar = _conversation.avatarThumb;
                model.targetName = _conversation.targetName;
            }else{
                model.who=YES;
                model.avatar = user.avatarThumbPath;
                model.targetName = user.username;
            }
            if (message.messageType == kTextMessage) {
                model.type=kTextMessage;
                JMSGContentMessage *contentMessage = (JMSGContentMessage *)message;
                model.chatContent = contentMessage.contentText;
            }else if (message.messageType == kImageMessage)
            {
                model.type= kImageMessage;
                JMSGImageMessage *imageMessage = (JMSGImageMessage *)message;
                if (imageMessage.resourcePath != nil) {
                    model.pictureImgPath = imageMessage.resourcePath;
                    if (imageMessage.thumbPath != nil) {
                        model.pictureThumbImgPath = imageMessage.thumbPath;
                    }
                    [_imgDataArr addObject:model];
                }else {
                    model.pictureThumbImgPath = imageMessage.thumbPath;
                    [_imgDataArr addObject:model];
                }
                model.photoIndex = [_imgDataArr count] -1;
            }else if (message.messageType == kVoiceMessage)
            {
                model.type = kVoiceMessage;
                JMSGVoiceMessage *voiceMessage = (JMSGVoiceMessage *)message;
                model.voicePath = voiceMessage.resourcePath;
                model.voiceTime = [NSString stringWithFormat:@"%@",voiceMessage.duration];
                model.chatContent =@"";
            }
            model.messageTime = message.timestamp;
            [self compareReceiveMessageTimeInterVal:[model.messageTime doubleValue]];
            [_messageDataArr addObject:model];
        }
            [_messageTableView reloadData];
        if ([_messageDataArr count] != 0) {
            [self.messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[_messageDataArr count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }        }));
    }];
}

#pragma mark --收到消息
-(void)receiveMessageNotifi:(NSNotification *)notifi
{
    JPIMMAINTHEAD(^{
        JMSGUser *user = [JMSGUserManager getMyInfo];
        [_conversation resetUnreadMessageCountWithCompletionHandler:^(id resultObject, NSError *error) {
            if (error == nil) {
            }else {
                JPIMLog(@"消息未读数清空失败");
            }
        }];
        JMSGMessage *message = (JMSGMessage *)[notifi object];
        if (![message.target_name isEqualToString:self.user.username]) {
            return ;
        }
        ChatModel *model =[[ChatModel alloc ] init];
        model.messageId = message.messageId;
        model.conversation = _conversation;
        model.targetName = message.target_name;
        model.messageStatus = [message.status integerValue];
        if (message.messageType == kTextMessage) {
            model.type=kTextMessage;
            JMSGContentMessage *contentMessage =  (JMSGContentMessage *)message;
            model.chatContent = contentMessage.contentText;
        } else if (message.messageType == kImageMessage) {
            model.type=kImageMessage;
            model.pictureThumbImgPath = ((JMSGImageMessage *)message).thumbPath;
            [_imgDataArr addObject:model];
            model.photoIndex = [_imgDataArr count] -1;
        } else if (message.messageType == kVoiceMessage){
            model.type = kVoiceMessage;
            model.voicePath =((JMSGVoiceMessage *)message).resourcePath;
            model.voiceTime = [((JMSGVoiceMessage *)message).duration stringByAppendingString:@"''"];
            model.readState = NO;
        }
        if ([user.username isEqualToString:message.target_name]) {
             model.who = YES;
            model.avatar = user.avatarThumbPath;
            model.targetName = [JMSGUserManager getMyInfo].username;
        }else {
            model.who=NO;
            model.avatar = _conversation.avatarThumb;
            model.targetName = _conversation.targetName;
        }
        model.messageTime = message.timestamp;
        JPIMLog(@"Received message:%@",message);
        [self getTimeDate:[model.messageTime doubleValue]];
        [self compareReceiveMessageTimeInterVal:[model.messageTime doubleValue]];
        [_messageDataArr addObject:model];
        [self addCellToTabel];
        [self scrollToEnd];
    });
}

#pragma mark --jsonStringTo字典
- (NSDictionary *)jsonStringToDictionary:(NSString *)jsonString {
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *content = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    return content;
}

- (XHVoiceRecordHelper *)voiceRecordHelper {
    if (!_voiceRecordHelper) {
        WEAKSELF
        _voiceRecordHelper = [[XHVoiceRecordHelper alloc] init];
        _voiceRecordHelper.maxTimeStopRecorderCompletion = ^{
            JPIMLog(@"已经达到最大限制时间了，进入下一步的提示");
            [weakSelf finishRecorded];
        };
        _voiceRecordHelper.peakPowerForChannel = ^(float peakPowerForChannel) {
            weakSelf.voiceRecordHUD.peakPower = peakPowerForChannel;
        };
        _voiceRecordHelper.maxRecordTime = kVoiceRecorderTotalTime;
    }
    return _voiceRecordHelper;
}

- (XHVoiceRecordHUD *)voiceRecordHUD {
    if (!_voiceRecordHUD) {
        _voiceRecordHUD = [[XHVoiceRecordHUD alloc] initWithFrame:CGRectMake(0, 0, 140, 140)];
    }
    return _voiceRecordHUD;
}

-(void)backClick {
    [self.navigationController popViewControllerAnimated:YES];
//    if (self.conversationType == kSingle) {
//        [self.navigationController popViewControllerAnimated:YES];
//    }else {
//        AppDelegate *appdelegate=(AppDelegate *)[UIApplication sharedApplication].delegate;
//        [self.navigationController popToViewController:appdelegate.tabBarCtl animated:YES];
//    }
}

- (void)pressVoiceBtnToHideKeyBoard
{
    [self.toolBar.textView resignFirstResponder];
    [self dropToolBar];
}

#pragma mark --增加朋友
-(void)addFriends
{
    if (self.conversationType == kSingle) {
        JPIMDetailsInfoViewController *detailsInfoCtl = [[JPIMDetailsInfoViewController alloc] initWithNibName:@"JPIMDetailsInfoViewController" bundle:nil];
        detailsInfoCtl.chatUser = self.user;
        [self.navigationController pushViewController:detailsInfoCtl animated:YES];
    }else{
        JPIMGroupSettingCtl *groupSettingCtl = [[JPIMGroupSettingCtl alloc] init];
        [self.navigationController pushViewController:groupSettingCtl animated:YES];
    }
}

#pragma mark -调用相册
-(void)photoClick {    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    NSArray *temp_MediaTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
    picker.mediaTypes = temp_MediaTypes;
    picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark --调用相机
-(void)cameraClick {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSString *requiredMediaType = ( NSString *)kUTTypeImage;
        NSArray *arrMediaTypes=[NSArray arrayWithObjects:requiredMediaType,nil];
        [picker setMediaTypes:arrMediaTypes];
        picker.showsCameraControls = YES;
        picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        picker.editing = YES;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerController Delegate
//相机,相册Finish的代理
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image;
    image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self sendPhotoImg:image];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self dropToolBar];
}

#pragma mark --发送图片
-(void)sendPhotoImg :(UIImage *)img
{
    img = [img resizedImageByWidth:upLoadImgWidth];
    UIImage *smallpImg = [UIImage imageWithImageSimple:img scaled:0.5];
    NSString *bigPath = [JPIMFileManager saveImageWithConversationID:_conversation.targetName andData:UIImageJPEGRepresentation(img, 1)];
    NSString *smallImgPath = [JPIMFileManager saveImageWithConversationID:_conversation.targetName andData:UIImageJPEGRepresentation(smallpImg, 1)];
    ChatModel *model =[[ChatModel alloc] init];
    model.who = YES;
    model.sendFlag = NO;
    model.conversation = _conversation;
    model.targetName = self.targetName;
    model.avatar = [JMSGUserManager getMyInfo].avatarThumbPath;
    model.messageStatus = kSending;
    model.type = kImageMessage;
    model.pictureImgPath = bigPath;
    model.pictureThumbImgPath = smallImgPath;
    NSTimeInterval timeInterVal = [self getCurrentTimeInterval];
    model.messageTime = @(timeInterVal);
    [_imgDataArr addObject:model];
    model.photoIndex=[_imgDataArr count]-1;
    [_messageDataArr addObject:model];
    [self.messageTableView reloadData];
    [self dropToolBar];
    [self scrollToEnd];
}

#pragma mark --
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark --加载通知
-(void)addNotification{
    //给键盘注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputKeyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessageResponse:) name:JMSGSendMessageResult object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessageNotifi:) name:KJMSG_ReceiveMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotificationSkipToChatPageView:) name:KApnsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeMessageState:)
                                                 name:kMessageChangeState
                                               object:nil];
//    [self.toolBar.textView addObserver:self
//                            forKeyPath:@"contentSize"
//                               options:NSKeyValueObservingOptionNew
//                               context:nil];
}

-(void)inputKeyboardWillShow:(NSNotification *)notification{
    self.barBottomFlag=NO;
    CGRect keyBoardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationTime = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [self.messageTableView setFrame:CGRectMake(0, kNavigationBarHeight+kStatusBarHeight, kApplicationWidth,kApplicationHeight-45-(kNavigationBarHeight)-keyBoardFrame.size.height)];
    [self scrollToEnd];
    [UIView animateWithDuration:animationTime animations:^{
        [self.toolBar setFrame:CGRectMake(0, kApplicationHeight+kStatusBarHeight-45-keyBoardFrame.size.height, self.view.bounds.size.width, 45)];
    }];
    [self.moreView setFrame:CGRectMake(0, kScreenHeight, self.view.bounds.size.width, self.moreView.bounds.size.height)];
}

- (void)inputKeyboardWillHide:(NSNotification *)notification{
    CGFloat animationTime = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [self.messageTableView setFrame:CGRectMake(0, kNavigationBarHeight+kStatusBarHeight, kApplicationWidth,kApplicationHeight-45-(kNavigationBarHeight))];
        [UIView animateWithDuration:animationTime animations:^{
            [self.toolBar setFrame:CGRectMake(0, kApplicationHeight+kStatusBarHeight-45, self.view.bounds.size.width, 45)];
        }];
}

#pragma mark --发送文本
- (void)sendText:(NSString *)text {
    [self sendContentToFriends:text];
}

- (void)perform {
    [self.moreView setFrame:CGRectMake(0, kScreenHeight, self.view.bounds.size.width, self.moreView.bounds.size.height)];
    [self.toolBar setFrame:CGRectMake(0, kApplicationHeight+kStatusBarHeight-45, self.view.bounds.size.width, 45)];
}

#pragma mark --返回下面的位置
- (void)dropToolBar {
    self.barBottomFlag=YES;
    self.previousTextViewContentHeight=31;
    self.toolBar.addButton.selected=NO;
    [self.messageTableView reloadData];
    [UIView animateWithDuration:0.3 animations:^{
        [self.moreView setFrame:CGRectMake(0, kScreenHeight, self.view.bounds.size.width, self.moreView.bounds.size.height)];
        [self.toolBar setFrame:CGRectMake(0, kApplicationHeight+kStatusBarHeight-45, self.view.bounds.size.width, 45)];
    }];
}

#pragma mark --按下功能响应
- (void)pressMoreBtnClick:(UIButton *)btn {
    self.barBottomFlag=NO;
    [self.toolBar.textView resignFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        [self.toolBar setFrame:CGRectMake(0, kScreenHeight-45-self.moreView.bounds.size.height, self.view.bounds.size.width, 45)];
        [self.moreView setFrame:CGRectMake(0, kScreenHeight-self.moreView.bounds.size.height, self.view.bounds.size.width, self.moreView.bounds.size.height)];
    }];
}

-(void)noPressmoreBtnClick:(UIButton *)btn {
    [self.toolBar.textView becomeFirstResponder];
}

#pragma mark ----发送消息
- (void)sendContentToFriends:(NSString *)text {
    if ([text isEqualToString:@""]|| text==nil) {
        return;
    }
    [self addmessageShowTimeData];
    ChatModel *model = [[ChatModel alloc ] init];
    model.who = YES;
    model.conversation = _conversation;
    model.targetName = self.targetName;
    JMSGUser *user = [JMSGUserManager getMyInfo];
    model.avatar = user.avatarThumbPath;
    model.targetName = _conversation.targetName;
    model.messageStatus = kSending;
    NSTimeInterval timeInterVal = [self getCurrentTimeInterval];
    model.messageTime = @(timeInterVal);
    model.sendFlag = NO;
    model.type = kTextMessage;
    model.chatContent = text;
    [_messageDataArr addObject:model];
    [self addCellToTabel];
    [self scrollToEnd];
}

- (void)addCellToTabel {
  [_messageTableView reloadData];
//    NSIndexPath *path = [NSIndexPath indexPathForRow:[_messageDataArr count]-1 inSection:0];
//    [self.messageTableView beginUpdates];
//    [self.messageTableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
//    [self.messageTableView endUpdates];
}

#pragma mark ---比较和上一条消息时间超过5分钟之内增加时间model
- (void)addmessageShowTimeData {
    ChatModel *lastModel =[_messageDataArr lastObject];
    NSTimeInterval timeInterVal = [self getCurrentTimeInterval];
    if ([_messageDataArr count]>0 && lastModel.type != kTimeMessage) {
        NSDate* lastdate = [NSDate dateWithTimeIntervalSince1970:[lastModel.messageTime doubleValue]];
        NSDate* currentDate = [NSDate dateWithTimeIntervalSince1970:timeInterVal];
        NSTimeInterval timeBetween = [currentDate timeIntervalSinceDate:lastdate];
        if (fabs(timeBetween) > interval) {
            ChatModel *timeModel =[[ChatModel alloc ] init];
            timeModel.type = kTimeMessage;
            timeModel.messageTime = @(timeInterVal);
            [_messageDataArr addObject:timeModel];
            [self addCellToTabel];
        }
    }
}

- (void)compareReceiveMessageTimeInterVal :(NSTimeInterval )timeInterVal {
    ChatModel *lastModel =[_messageDataArr lastObject];
    if ([_messageDataArr count]>0 && lastModel.type != kTimeMessage) {
        NSDate* lastdate = [NSDate dateWithTimeIntervalSince1970:[lastModel.messageTime doubleValue]];
        NSDate* currentDate = [NSDate dateWithTimeIntervalSince1970:timeInterVal];
        NSTimeInterval timeBetween = [currentDate timeIntervalSinceDate:lastdate];
        if (fabs(timeBetween) > interval) {
            ChatModel *timeModel = [[ChatModel alloc ] init];
            timeModel.type = kTimeMessage;
            timeModel.messageTime = @(timeInterVal);
//            [self getTimeDate:timeInterVal];
            [_messageDataArr addObject:timeModel];
            [self addCellToTabel];
        }
    }
}

#pragma mark --滑动至尾端
- (void)scrollToEnd {
    if ([_messageDataArr count] != 0) {
        [self.messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[_messageDataArr count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatModel *model =[_messageDataArr objectAtIndex:indexPath.row];
    if (model.type==kTextMessage) {
        return model.getTextSize.height+8;
    }else if(model.type == kImageMessage){
        if (model.messageStatus == kReceiveDownloadFailed) {
            return 150;
        }else {
            UIImage *img = [UIImage imageWithContentsOfFile:model.pictureThumbImgPath];
            if (kScreenWidth > 320) {
                return img.size.height/3;
            }else {
                return img.size.height/2;
            }
        }
    }else if(model.type==kVoiceMessage)
    {
        return 60;
    }else{
        return 40;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    [self.toolBar drawRect:self.toolBar.frame];
    [self.navigationController setNavigationBarHidden:NO];
    [_conversation resetUnreadMessageCountWithCompletionHandler:^(id resultObject, NSError *error) {
        if (error == nil) {
            JPIMLog(@"清零成功");
        }else {
            JPIMLog(@"清零失败");
        }
    }];
//    // 禁用 iOS7 返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    [self.messageTableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[XHAudioPlayerHelper shareInstance] stopAudio];
    [[XHAudioPlayerHelper shareInstance] setDelegate:nil];
}


#pragma mark --释放内存
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tapClick:(UIGestureRecognizer *)gesture {
    [self.toolBar.textView resignFirstResponder];
    [self dropToolBar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_messageDataArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatModel *model =[_messageDataArr objectAtIndex:indexPath.row];
    if (model.type == kTextMessage) {
        static NSString *cellIdentifier = @"textCell";
        JPIMTextTableViewCell *cell = (JPIMTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[JPIMTextTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        if (!model.sendFlag) {
            model.sendFlag = YES;
            [self sendMessage:model];
        }
        [cell setCellData:model delegate:self];
        return cell;
    }else if(model.type == kImageMessage)
    {
        static NSString *cellIdentifier = @"imgCell";
        JPIMImgTableViewCell *cell = (JPIMImgTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[JPIMImgTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [cell setCellData:self chatModel:model indexPath:indexPath];
        return cell;
    }else if (model.type == kVoiceMessage)
    {
        static NSString *cellIdentifier = @"voiceCell";
        JPIMVoiceTableViewCell *cell = (JPIMVoiceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[JPIMVoiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [cell setCellData:model delegate:self indexPath:indexPath];
        return cell;
    }else if (model.type == kTimeMessage) {
        static NSString *cellIdentifier = @"timeCell";
        JPIMShowTimeCell *cell = (JPIMShowTimeCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"JPIMShowTimeCell" owner:self options:nil] lastObject];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.messageTimeLabel.text = [self getTimeDate:[model.messageTime doubleValue]];
        return cell;
    }
    else{
        return nil;
    }
}

#pragma mark --发送消息
- (void)sendMessage :(ChatModel *)model {
    model.messageStatus = kSending;
    JMSGContentMessage *  message = [[JMSGContentMessage alloc] init];
    message.target_name = model.targetName;
    model.messageId = message.messageId;
    message.timestamp = model.messageTime;
    message.contentText = model.chatContent;
    [JMSGMessageManager sendMessage:message];
    JPIMLog(@"Sent message:%@",message.contentText);
}

- (void)selectHeadView:(ChatModel *)model {
    if (model.who) {
        JPIMPersonViewController *personCtl =[[JPIMPersonViewController alloc] init];
        personCtl.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:personCtl animated:YES];
    }else {
        JPIMFriendDetailViewController *friendCtl = [[JPIMFriendDetailViewController alloc]initWithNibName:@"JPIMFriendDetailViewController" bundle:nil];
        friendCtl.userInfo = self.user;
        [self.navigationController pushViewController:friendCtl animated:YES];
    }
}

#pragma mark --预览图片
- (void)tapPicture:(NSIndexPath *)index tapView:(UIImageView *)tapView tableViewCell:(UITableViewCell *)tableViewCell {
    JPIMImgTableViewCell *cell =(JPIMImgTableViewCell *)tableViewCell;
    NSInteger count = _imgDataArr.count;
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i<count; i++) {
        ChatModel *messageObject = [_imgDataArr objectAtIndex:i];
        NSString *url;
        MJPhoto *photo = [[MJPhoto alloc] init];
        photo.message = messageObject;
        url = messageObject.pictureImgPath;
        if (url) {
            photo.url = [NSURL fileURLWithPath:url]; // 图片路径
        }else {
            url = messageObject.pictureThumbImgPath;
            photo.url = [NSURL fileURLWithPath:url]; // 图片路径
        }
        photo.srcImageView = tapView; // 来源于哪个UIImageView
        [photos addObject:photo];
    }
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
    browser.currentPhotoIndex = cell.model.photoIndex; // 弹出相册时显示的第一张图片是？
    browser.photos = photos; // 设置所有的图片
    browser.conversation =_conversation;
    [browser show];
    [self.messageTableView reloadData];
}

#pragma mark --获取所有发送消息图片
- (NSArray *)getAllMessagePhotoImg {
    NSMutableArray *urlArr =[NSMutableArray array];
    for (NSInteger i=0; i<[_messageDataArr count]; i++) {
        ChatModel *model = [_messageDataArr objectAtIndex:i];
        if (model.type == kImageMessage) {
            [urlArr addObject:model.pictureImgPath];
        }
    }
    return urlArr;
}

- (void)didStartRecordingVoiceAction {
    JPIMLog(@"didStartRecordingVoice");
    [self startRecord];
}

- (void)didCancelRecordingVoiceAction {
    JPIMLog(@"didCancelRecordingVoice");
    [self cancelRecord];
}

- (void)didFinishRecoingVoiceAction {
    JPIMLog(@"didFinishRecoingVoice");
    [self finishRecorded];
}

- (void)didDragOutsideAction {
    JPIMLog(@"didDragOutsideAction");
    [self resumeRecord];
}

- (void)didDragInsideAction {
    JPIMLog(@"didDragInsideAction");
    [self pauseRecord];
}

- (void)pauseRecord {
    [self.voiceRecordHUD pauseRecord];
}

- (void)resumeRecord {
    [self.voiceRecordHUD resaueRecord];
}

- (void)cancelRecord {
    WEAKSELF
    [self.voiceRecordHUD cancelRecordCompled:^(BOOL fnished) {
        weakSelf.voiceRecordHUD = nil;
    }];
    [self.voiceRecordHelper cancelledDeleteWithCompletion:^{
        
    }];
}

#pragma mark - Voice Recording Helper Method
- (void)startRecord {
    [self.voiceRecordHUD startRecordingHUDAtView:self.view];
    [self.voiceRecordHelper startRecordingWithPath:[self getRecorderPath] StartRecorderCompletion:^{
    }];
}

#pragma mark --录音完毕
- (void)finishRecorded {
    WEAKSELF
    [self.voiceRecordHUD stopRecordCompled:^(BOOL fnished) {
        weakSelf.voiceRecordHUD = nil;
    }];
    [self.voiceRecordHelper stopRecordingWithStopRecorderCompletion:^{
        [weakSelf didSendMessageWithVoice:weakSelf.voiceRecordHelper.recordPath voiceDuration:weakSelf.voiceRecordHelper.recordDuration];
    }];
}

#pragma mark - Message Send helper Method
#pragma mark --发送语音
- (void)didSendMessageWithVoice:(NSString *)voicePath voiceDuration:(NSString*)voiceDuration {
    if ([voiceDuration integerValue]<0.5 || [voiceDuration integerValue]>60) {
        if ([voiceDuration integerValue]<0.5) {
            JPIMLog(@"录音时长小于 0.5s");
        }else {
            JPIMLog(@"录音时长大于 60s");
        }
        [JPIMFileManager deleteFile:voicePath];
        return;
    }
    NSString *savePath = [JPIMFileManager copyFile:voicePath withType:FILE_AUDIO From:@"" to:@"guanjingfen"];
    [JPIMFileManager deleteFile:voicePath];
    ChatModel *model =[[ChatModel alloc ] init];
    if ([voiceDuration integerValue] >= 60) {
        model.voiceTime = @"60''";
    }else{
        model.voiceTime = [NSString stringWithFormat:@"%d''",(int)[voiceDuration integerValue]];
    }
    model.avatar = [JMSGUserManager getMyInfo].avatarThumbPath;
    model.type=kVoiceMessage;
    model.conversation = _conversation;
    NSTimeInterval timeInterVal = [self getCurrentTimeInterval];
    model.messageTime = @(timeInterVal);
    model.targetName = self.targetName;
    model.readState=YES;
    model.who=YES;
    model.sendFlag = NO;
    model.voicePath=savePath;
    [_messageDataArr addObject:model];
    [self.messageTableView reloadData];
    [self scrollToEnd];
}

#pragma mark - RecorderPath Helper Method
- (NSString *)getRecorderPath {
    NSString *recorderPath = nil;
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yy-MMMM-dd";
    recorderPath = [[NSString alloc] initWithFormat:@"%@/Documents/", NSHomeDirectory()];
    //    dateFormatter.dateFormat = @"hh-mm-ss";
    dateFormatter.dateFormat = @"yyyy-MM-dd-hh-mm-ss";
    recorderPath = [recorderPath stringByAppendingFormat:@"%@-MySound.ilbc", [dateFormatter stringFromDate:now]];
    return recorderPath;
}

#pragma mark - Key-value Observing
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (self.barBottomFlag) {
        return;
    }
    if (object == self.toolBar.textView && [keyPath isEqualToString:@"contentSize"]) {
        [self layoutAndAnimateMessageInputTextView:object];
    }
}


#pragma mark ---
- (void)getContinuePlay:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    JPIMVoiceTableViewCell *tempCell =(JPIMVoiceTableViewCell *)cell;
    if ([_messageDataArr count]-1>indexPath.row) {
        ChatModel *model =[_messageDataArr objectAtIndex:indexPath.row+1];
        if (model.type==kVoiceMessage && !model.readState) {
            tempCell.continuePlayer=YES;
        }
    }
}

#pragma mark --连续播放语音
- (void)successionalPlayVoice:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if ([_messageDataArr count]-1>indexPath.row) {
        ChatModel *model =[_messageDataArr objectAtIndex:indexPath.row+1];
        if (model.type==kVoiceMessage&& !model.readState) {
             JPIMVoiceTableViewCell *voiceCell =(JPIMVoiceTableViewCell *)[self.messageTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]];
            [voiceCell playerVoice];
        }
    }
}

#pragma mark - UITextView Helper Method
- (CGFloat)getTextViewContentH:(UITextView *)textView {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        return ceilf([textView sizeThatFits:textView.frame.size].height);
    } else {
        return textView.contentSize.height;
    }
}

#pragma mark - Layout Message Input View Helper Method

- (void)layoutAndAnimateMessageInputTextView:(UITextView *)textView {
    CGFloat maxHeight = [JPIMToolBar maxHeight];
    
    CGFloat contentH = [self getTextViewContentH:textView];
    
    BOOL isShrinking = contentH < self.previousTextViewContentHeight;
    CGFloat changeInHeight = contentH - _previousTextViewContentHeight;
    
    if (!isShrinking && (self.previousTextViewContentHeight == maxHeight || textView.text.length == 0)) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }
    
    if (changeInHeight != 0.0f) {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             [self setTableViewInsetsWithBottomValue:self.messageTableView.contentInset.bottom + changeInHeight];
                             
                             [self scrollToBottomAnimated:NO];
                             
                             if (isShrinking) {
                                 if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
                                     self.previousTextViewContentHeight = MIN(contentH, maxHeight);
                                 }
                                 // if shrinking the view, animate text view frame BEFORE input view frame
                                 [self.toolBar adjustTextViewHeightBy:changeInHeight];
                             }
                             
                             CGRect inputViewFrame = self.toolBar.frame;
                             self.toolBar.frame = CGRectMake(0.0f,
                                                                      inputViewFrame.origin.y - changeInHeight,
                                                                      inputViewFrame.size.width,
                                                                      inputViewFrame.size.height + changeInHeight);
                             if (!isShrinking) {
                                 if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
                                     self.previousTextViewContentHeight = MIN(contentH, maxHeight);
                                 }
                                 // growing the view, animate the text view frame AFTER input view frame
                                 [self.toolBar adjustTextViewHeightBy:changeInHeight];
                             }
                         }
                         completion:^(BOOL finished) {
                         }];
        
        self.previousTextViewContentHeight = MIN(contentH, maxHeight);
    }
    
    // Once we reached the max height, we have to consider the bottom offset for the text view.
    // To make visible the last line, again we have to set the content offset.
    if (self.previousTextViewContentHeight == maxHeight) {
        double delayInSeconds = 0.01;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime,
                       dispatch_get_main_queue(),
                       ^(void) {
                           CGPoint bottomOffset = CGPointMake(0.0f, contentH - textView.bounds.size.height);
                           [textView setContentOffset:bottomOffset animated:YES];
                       });
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if (![self shouldAllowScroll])
        return;
    
    NSInteger rows = [self.messageTableView numberOfRowsInSection:0];
    
    if (rows > 0) {
        [self.messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                                     atScrollPosition:UITableViewScrollPositionBottom
                                             animated:animated];
    }
}

#pragma mark - Previte Method

- (BOOL)shouldAllowScroll {
//    if (self.isUserScrolling) {
//        if ([self.delegate respondsToSelector:@selector(shouldPreventScrollToBottomWhileUserScrolling)]
//            && [self.delegate shouldPreventScrollToBottomWhileUserScrolling]) {
//            return NO;
//        }
//    }
    return YES;
}

#pragma mark - Scroll Message TableView Helper Method

- (void)setTableViewInsetsWithBottomValue:(CGFloat)bottom {
//    UIEdgeInsets insets = [self tableViewInsetsWithBottomValue:bottom];
//    self.messageTableView.contentInset = insets;
//    self.messageTableView.scrollIndicatorInsets = insets;
}

- (UIEdgeInsets)tableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        insets.top = 64;
    }
    insets.bottom = bottom;
    return insets;
}

#pragma mark - XHMessageInputView Delegate

- (void)inputTextViewWillBeginEditing:(JPIMMessageTextView *)messageInputTextView {
    self.textViewInputViewType = JPIMInputViewTypeText;
}

- (void)inputTextViewDidBeginEditing:(JPIMMessageTextView *)messageInputTextView {
    if (!self.previousTextViewContentHeight)
        self.previousTextViewContentHeight = [self getTextViewContentH:messageInputTextView];
}

- (void)inputTextViewDidEndEditing:(JPIMMessageTextView *)messageInputTextView;
{
    if (!self.previousTextViewContentHeight)
        self.previousTextViewContentHeight = [self getTextViewContentH:messageInputTextView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
