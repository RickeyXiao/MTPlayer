//
//  MTPlayerView.m
//  MTPlayer
//
//  Created by Metallic  on 17/3/17.
//  Copyright © 2017年 xiaowei. All rights reserved.
//

#import "MTPlayerView.h"
#import <AVFoundation/AVFoundation.h>

static const CGFloat kToolViewHeight = 40.0;
static const CGFloat kToolViewAlpha = 0.3;
static const CGFloat kTimeLabelFontSize = 15.0;

static void *MTPlayerViewKVOContext = &MTPlayerViewKVOContext;

@interface MTPlayerView ()

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIButton *playbackButton;
@property (nonatomic, strong) UIView *toolView;
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UILabel *endTimeLabel;
@property (nonatomic, strong) id timeObserverToken;

@end

@implementation MTPlayerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.toolView];
        [self.toolView addSubview:self.playbackButton];
        [self.toolView addSubview:self.currentTimeLabel];
        [self.toolView addSubview:self.progressSlider];
        [self.toolView addSubview:self.endTimeLabel];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self addSubview:self.toolView];
    [self.toolView addSubview:self.playbackButton];
    [self.toolView addSubview:self.currentTimeLabel];
    [self.toolView addSubview:self.progressSlider];
    [self.toolView addSubview:self.endTimeLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _toolView.frame = CGRectMake(0,
                                 self.bounds.size.height - kToolViewHeight,
                                 self.bounds.size.width,
                                 kToolViewHeight);
    
    _playbackButton.frame = CGRectMake(8, 0, kToolViewHeight, kToolViewHeight);
    
    _currentTimeLabel.frame = CGRectMake(CGRectGetMaxX(_playbackButton.frame) + 8,
                                         0,
                                         kToolViewHeight,
                                         kToolViewHeight);
    
    _endTimeLabel.frame = CGRectMake(self.bounds.size.width - kToolViewHeight - 8,
                                     0,
                                     kToolViewHeight,
                                     kToolViewHeight);
    
    _progressSlider.frame = CGRectMake(CGRectGetMaxX(_currentTimeLabel.frame) + 8,
                                       0,
                                       self.bounds.size.width - CGRectGetMaxX(_currentTimeLabel.frame) - 24 - kToolViewHeight,
                                       kToolViewHeight);
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == MTPlayerViewKVOContext) {
        if ([keyPath isEqualToString:@"rate"]) {
            float rate = [change[NSKeyValueChangeNewKey] floatValue];
            [self.playbackButton setTitle:rate == 0 ? @"播放" : @"暂停" forState:UIControlStateNormal];
        } else if ([keyPath isEqualToString:@"currentItem.duration"]) {
            NSValue *newDurationValue = change[NSKeyValueChangeNewKey];
            CMTime newDuration = [newDurationValue isKindOfClass:[NSValue class]] ? newDurationValue.CMTimeValue : kCMTimeZero;
            BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
            double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;
            
            self.progressSlider.maximumValue = newDurationSeconds;
            self.progressSlider.value = hasValidDuration ? CMTimeGetSeconds(self.currentTime) : 0.0;
            self.progressSlider.enabled = hasValidDuration;
            self.playbackButton.enabled = hasValidDuration;
            self.currentTimeLabel.enabled = hasValidDuration;
            self.endTimeLabel.enabled = hasValidDuration;
            
            int minutes = (int)(newDurationSeconds / 60);
            self.endTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", minutes, (int)(newDurationSeconds) - minutes * 60];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)addObserversForPlayer:(AVPlayer *)player
{
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:MTPlayerViewKVOContext];
    [player addObserver:self forKeyPath:@"currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:MTPlayerViewKVOContext];
    
    typeof(self) __weak weakSelf = self;
    self.timeObserverToken = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double currentTimeSeconds = CMTimeGetSeconds(time);
        
        [weakSelf.progressSlider setValue:currentTimeSeconds animated:YES];
        
        int minutes = (int)(currentTimeSeconds / 60);
        weakSelf.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, (int)(currentTimeSeconds) - minutes * 60];
    }];
}

- (void)removeObserversForPlayer:(AVPlayer *)player
{
    [player removeObserver:self forKeyPath:@"rate" context:MTPlayerViewKVOContext];
    [player removeObserver:self forKeyPath:@"currentItem.duration" context:MTPlayerViewKVOContext];
    
    if (_timeObserverToken) {
        [player removeTimeObserver:_timeObserverToken];
        self.timeObserverToken = nil;
    }
}

#pragma mark - Properties

- (UILabel *)currentTimeLabel
{
    if (!_currentTimeLabel) {
        _currentTimeLabel = [self createLabelWithText:@"00:00"
                                                 font:[UIFont systemFontOfSize:kTimeLabelFontSize]
                                            textColor:[UIColor whiteColor]];
    }
    return _currentTimeLabel;
}

- (UISlider *)progressSlider
{
    if (!_progressSlider) {
        _progressSlider = [[UISlider alloc] init];
        [_progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _progressSlider;
}

- (UILabel *)endTimeLabel
{
    if (!_endTimeLabel) {
        _endTimeLabel = [self createLabelWithText:@"00:00"
                                             font:[UIFont systemFontOfSize:kTimeLabelFontSize]
                                        textColor:[UIColor whiteColor]];
    }
    return _endTimeLabel;
}

- (UIView *)toolView
{
    if (!_toolView) {
        _toolView = [[UIView alloc] init];
        _toolView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kToolViewAlpha];
    }
    return _toolView;
}

- (UIButton *)playbackButton
{
    if (!_playbackButton) {
        _playbackButton = [self createButtonWithTitle:@"播放"
                                                image:nil
                                                  sel:@selector(playbackButtonClicked)];
    }
    return _playbackButton;
}

- (void)setPlayer:(AVPlayer *)player
{
    self.playerLayer.player = player;
    [self addObserversForPlayer:player];
}

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (CMTime)currentTime
{
    return self.player.currentTime;
}

- (void)setCurrentTime:(CMTime)newCurrentTime
{
    [self.player seekToTime:newCurrentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (CMTime)duration
{
    return self.player.currentItem ? self.player.currentItem.duration : kCMTimeZero;
}

#pragma mark - Events

- (void)playbackButtonClicked
{
    if (self.player.rate != 0) {
        [self.player pause];
    } else {
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            self.currentTime = kCMTimeZero;
        }
        [self.player play];
    }
}

- (void)progressSliderValueChanged:(UISlider *)slider
{
    self.currentTime = CMTimeMakeWithSeconds(slider.value, self.duration.timescale);
}

#pragma mark - Helper Methods

- (UIButton *)createButtonWithTitle:(NSString *)title
                              image:(UIImage *)image
                                sel:(SEL)sel
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UILabel *)createLabelWithText:(NSString *)text
                            font:(UIFont *)font
                       textColor:(UIColor *)textColor
{
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = textColor;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self removeObserversForPlayer:self.player];
}

@end
