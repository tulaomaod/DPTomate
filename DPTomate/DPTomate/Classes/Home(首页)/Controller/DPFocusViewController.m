//
//  DPFocusViewController.m
//  DPTomate
//
//  Created by 土老帽 on 16/4/11.
//  Copyright © 2016年 DPRuin. All rights reserved.
//

#import "DPFocusViewController.h"
#import "DPTimerView.h"
#import "DPButton.h"
#import <AudioToolbox/AudioToolbox.h>

#define DPOrangeColor DPRGBColor(212, 167, 42)
#define DPBackgroundColor DPRGBColor(41, 42, 55)

@interface DPFocusViewController ()

/** 定时器 */
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) UILocalNotification *localNotification;
/** 倒计时类型 */
@property (nonatomic, assign) TimerType currentType;

@property (nonatomic, assign) int totalMinutes;

/** 倒计时钟 */
@property (weak, nonatomic) IBOutlet DPTimerView *timerView;
/** 工作按钮 */
@property (weak, nonatomic) IBOutlet DPButton *workButton;
/** 休息按钮 */
@property (weak, nonatomic) IBOutlet DPButton *breakButton;
/** 拖延按钮 */
@property (weak, nonatomic) IBOutlet DPButton *procrastinateButton;


@end

@implementation DPFocusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentType = TimerTypeIdle;
    self.view.backgroundColor = DPBackgroundColor;
    
}

/**
 *  修改电量条样式
 */
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/**
 *  开始工作
 */
- (IBAction)startWork:(DPButton *)sender {
    if (self.currentType == TimerTypeWork) {
        // 提示
        [self showAlert];
        [self startTimerWithType:TimerTypeWork];
        return;
    }
}

/**
 *  开始休息
 */
- (IBAction)startBreak:(DPButton *)sender {
    if (self.currentType == TimerTypeBreak) {
        // 提示
        [self showAlert];
        [self startTimerWithType:TimerTypeBreak];
        return;
    }
}

/**
 *  开始拖延
 */
- (IBAction)startProcrastination:(DPButton *)sender {
    if (self.currentType == TimerTypeProcrastination) {
        // 提示
        [self showAlert];
        [self startTimerWithType:TimerTypeProcrastination];
        return;
    }
}

/**
 *  倒计时
 */
- (void)startTimerWithType:(TimerType)type
{
    self.timerView.durationInSeconds = 0;
    self.timerView.maxValue = 1;
    [self.timerView setNeedsDisplay];
    
    
    // 倒计多少秒
    NSInteger seconds;
    switch (type) {
        case TimerTypeWork: {
            self.currentType = TimerTypeWork;
            seconds = [[NSUserDefaults standardUserDefaults] integerForKey:TimerTypeWorkKey];
            break;
        }
            
        case TimerTypeBreak: {
            self.currentType = TimerTypeBreak;
            seconds = [[NSUserDefaults standardUserDefaults] integerForKey:TimerTypeBreakKey];
            break;
        }
            
        case TimerTypeProcrastination: {
            self.currentType = TimerTypeProcrastination;
            
            break;
        }
            
        default: {
            self.currentType = TimerTypeIdle;
            [self resetTimer];
            break;
        }
    }
    
    // 结束时间
    self.endDate = [[NSDate alloc] initWithTimeIntervalSinceNow:seconds];
    
    // 按钮状态设置
    [self setUIModeForTimerType:type];
    
    
    // 手表？？
    
    // 定时器
    [self.timer invalidate];
    NSNumber *secondsNumber = [NSNumber numberWithInteger:seconds];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimeLabel:) userInfo:@{@"timerType" : secondsNumber} repeats:YES];
}

/**
 *
 */
- (void)updateTimeLabel:(NSTimer *)timer
{
    CGFloat totalNumberOfSeconds;
    CGFloat seconds = [timer.userInfo[@"timerType"] floatValue];
    if (seconds) {
        totalNumberOfSeconds = seconds;
    } else {
        NSAssert(NO, @"错误：不应该来到这里");
        totalNumberOfSeconds = -1.0;
    }
    
    CGFloat timeInterval = [self.endDate timeIntervalSinceNow];
    if (timeInterval < 0) {
        [self resetTimer];
        if (timeInterval > -1) {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        }
        self.timerView.durationInSeconds = 0;
        self.timerView.maxValue = 1;
        return;
    }
    
    self.timerView.durationInSeconds = timeInterval;
    self.timerView.maxValue = totalNumberOfSeconds;
    
}

/**
 *  重置定时器
 */
- (void)resetTimer
{
    // 定时器无效
    [self.timer invalidate];
    self.timer = nil;
    
    self.currentType = TimerTypeIdle;
    [self setUIModeForTimerType:TimerTypeIdle];
    
    // 未写手表！！！
    
}

/**
 *  点击按钮后按钮状态改变
 */
- (void)setUIModeForTimerType:(TimerType)type
{
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        switch (type) {
            case TimerTypeWork: { // 工作
                [self setButton:self.workButton enabled:YES];
                [self setButton:self.breakButton enabled:NO];
                [self setButton:self.procrastinateButton enabled:NO];
                
                break;
            }
                
            case TimerTypeBreak: { // 休息
                [self setButton:self.workButton enabled:NO];
                [self setButton:self.breakButton enabled:YES];
                [self setButton:self.procrastinateButton enabled:NO];
                break;
            }
                
            case TimerTypeProcrastination: { // 拖延
                [self setButton:self.workButton enabled:NO];
                [self setButton:self.breakButton enabled:NO];
                [self setButton:self.procrastinateButton enabled:YES];
                break;
            }
                
            default: {
                [self setButton:self.workButton enabled:YES];
                [self setButton:self.breakButton enabled:YES];
                [self setButton:self.procrastinateButton enabled:YES];
                break;
            }
        }
        
    } completion:nil];
}

/**
 *  设置按钮enabled
 */
- (void)setButton:(DPButton *)button enabled:(BOOL)enabled
{
    if (enabled) {
        button.enabled = YES;
        button.alpha = 1.0;
    } else {
        button.enabled = NO;
        button.alpha = 0.3;
    }
}


/**
 *  提示
 */
- (void)showAlert {
    
    NSMutableString *alertMessage = [NSMutableString stringWithString:NSLocalizedString(@"Do you want to stop this ", nil)];
    switch (self.currentType) {
        case TimerTypeWork: // 工作
            [alertMessage appendString:NSLocalizedString(@"work timer?", nil)];
            break;
            
        case TimerTypeBreak: // 休息
            [alertMessage appendString:NSLocalizedString(@"break timer?", nil)];
            break;
            
        case TimerTypeProcrastination: // 拖延
            [alertMessage appendString:NSLocalizedString(@"procrastination?", nil)];
            break;
        default:
            break;
    }
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Stop?", nil) message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *stopAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Stop", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 停止倒计时
        
    }];
    
    [alertVC addAction:cancelAction];
    [alertVC addAction:stopAction];
    
    [self presentViewController:alertVC animated:YES completion:nil];
    
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
