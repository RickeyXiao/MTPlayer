//
//  MTPlayerView.h
//  MTPlayer
//
//  Created by Metallic  on 17/3/17.
//  Copyright © 2017年 xiaowei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface MTPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;//需要对player进行设置

@end
