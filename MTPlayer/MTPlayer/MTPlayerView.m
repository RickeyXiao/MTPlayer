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

static void *MTPlayerViewKVOContext = &MTPlayerViewKVOContext;

@interface MTPlayerView ()

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIButton *playbackButton;
@property (nonatomic, strong) UIView *toolView;
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic, assign) CMTime duration;

@end

@implementation MTPlayerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.toolView];
        [self.toolView addSubview:self.playbackButton];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self addSubview:self.toolView];
    [self.toolView addSubview:self.playbackButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _toolView.frame = CGRectMake(0,
                                 self.bounds.size.height - kToolViewHeight,
                                 self.bounds.size.width,
                                 kToolViewHeight);
    
    _playbackButton.frame = CGRectMake(8, 0, kToolViewHeight, kToolViewHeight);
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
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Properties

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
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:MTPlayerViewKVOContext];
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

#pragma mark - Dealloc

- (void)dealloc
{
    [self.player removeObserver:self forKeyPath:@"rate" context:MTPlayerViewKVOContext];
}

@end
