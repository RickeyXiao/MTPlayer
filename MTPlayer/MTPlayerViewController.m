//
//  MTPlayerViewController.m
//  MTPlayer
//
//  Created by Metallic  on 17/3/16.
//  Copyright © 2017年 xiaowei. All rights reserved.
//

#import "MTPlayerViewController.h"
#import "MTPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface MTPlayerViewController ()

@property (strong, nonatomic) MTPlayerView *playerView;

@end

@implementation MTPlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *playURL = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVPlayer *player = [AVPlayer playerWithURL:playURL];
    self.playerView = [[MTPlayerView alloc] init];
    self.playerView.player = player;
    self.playerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_playerView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.playerView.frame = CGRectMake(0, 20, self.view.bounds.size.width, 300);
}

@end
