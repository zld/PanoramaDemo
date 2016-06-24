//
//  ViewController.m
//  VRDemo
//
//  Created by zld on 6/24/16.
//  Copyright © 2016 zld. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController () {
    CMMotionManager *motionManager;
}

@property (nonatomic, strong) UIImageView *imageView; // image test
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, assign) CGFloat scaledImageWidth;
@property (nonatomic, assign) CGFloat scaledWidth;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, assign) CGFloat axis;

@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *videoButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    [self handleMotion];
}

#pragma mark - Private Methods

- (void)initUI {
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    _scaledWidth = kScreenHeight * 16.0 / 9.0;
    self.playerLayer.frame = CGRectMake(0, 0, _scaledWidth, kScreenHeight);
    self.videoView.frame = self.playerLayer.frame;
    [self.videoView.layer addSublayer:self.playerLayer];
    
    [self.view addSubview:self.imageButton];
    [self.view addSubview:self.videoButton];
}

- (void)handleMotion {
    motionManager = [[CMMotionManager alloc] init];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    CGFloat total = 0.4;
    self.axis = total * 0.5;
    [motionManager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
//        [self logWithMotion:motion];
        
        if (!([self.view.subviews containsObject:self.imageView] ||
            [self.view.subviews containsObject:self.videoView])) {
            return;
        }
        
        CGFloat relativeShift = motion.attitude.quaternion.y;
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect frame = self.view.bounds;
            CGFloat shift = self.axis - relativeShift;
            if (shift < 0) {
                shift = 0;
                self.axis = relativeShift;
            } else if (shift > total) {
                shift = total;
                self.axis = relativeShift + total;
            }
            NSLog(@"axis: %f, relativeShift:%f shift: %f", self.axis, relativeShift, shift);
            frame.origin.x = shift / total * (_scaledWidth - kScreenWidth);
            self.view.bounds = frame;
            self.imageButton.frame = CGRectMake(frame.origin.x, kScreenHeight - 50, kScreenWidth * 0.5, 50);
            self.videoButton.frame = CGRectMake(frame.origin.x + kScreenWidth * 0.5, kScreenHeight - 50, kScreenWidth * 0.5, 50);
        });
    } ];
}

- (void)logWithMotion:(CMDeviceMotion *)motion {
//    NSLog(@"pitch: %f", motion.attitude.pitch);
//    NSLog(@"roll: %f", motion.attitude.roll);
//    NSLog(@"yaw: %f", motion.attitude.yaw);
//    NSLog(@"quaternion.x: %f, y: %f, z: %f, w: %f",
//          motion.attitude.quaternion.x,
//          motion.attitude.quaternion.y,
//          motion.attitude.quaternion.z,
//          motion.attitude.quaternion.w);
}

#pragma mark - Actions

- (void)changeToImage {
    _scaledWidth = _scaledImageWidth;
    [self.player pause];
    [self.videoView removeFromSuperview];
    [self.view addSubview:self.imageView];
    [self.view bringSubviewToFront:self.imageButton];
    [self.view bringSubviewToFront:self.videoButton];
}

- (void)changeToVideo {
    _scaledWidth = kScreenHeight * 16.0 / 9.0;
    [self.imageView removeFromSuperview];
    [self.view addSubview:self.videoView];
    [self.view bringSubviewToFront:self.imageButton];
    [self.view bringSubviewToFront:self.videoButton];
    [self.player play];
}

#pragma mark - Player

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    // loop video
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

#pragma mark - Getters

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
//        NSString *urlString = @"http://image.tianjimedia.com/uploadImages/2011/353/PEPS6VMUMC0Z.jpg";
        NSString *urlString = @"http://7xodef.com1.z0.glb.clouddn.com/park_2048.jpg";
        [_imageView sd_setImageWithURL:[NSURL URLWithString:urlString] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (image) {
                CGFloat scale = kScreenHeight / image.size.height;
                _scaledImageWidth = image.size.width * scale;
                CGRect frame = CGRectMake(0, 0, image.size.width * scale, kScreenHeight);
                _imageView.frame = frame;
            }
        }];
    }
    return _imageView;
}

- (UIView *)videoView {
    if (!_videoView) {
        _videoView = [[UIView alloc] initWithFrame:self.view.bounds];
    }
    return _videoView;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithURL:[NSURL URLWithString:@"http://wvideo.spriteapp.cn/video/2016/0619/5766b6c8a1320cut_wpd.mp4"]];
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[_player currentItem]];
    }
    return _player;
}

- (UIButton *)imageButton {
    if (!_imageButton) {
        _imageButton = [[UIButton alloc] init];
        [_imageButton setTitle:@"Image" forState:UIControlStateNormal];
        _imageButton.frame = CGRectMake(0, kScreenHeight - 50, kScreenWidth * 0.5, 50);
        [_imageButton addTarget:self action:@selector(changeToImage) forControlEvents:UIControlEventTouchUpInside];
        [_imageButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [_imageButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _imageButton;
}

- (UIButton *)videoButton {
    if (!_videoButton) {
        _videoButton = [[UIButton alloc] init];
        [_videoButton setTitle:@"Video" forState:UIControlStateNormal];
        _videoButton.frame = CGRectMake(kScreenWidth * 0.5, kScreenHeight - 50, kScreenWidth * 0.5, 50);
       [_videoButton addTarget:self action:@selector(changeToVideo) forControlEvents:UIControlEventTouchUpInside];
        [_videoButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
        [_videoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _videoButton;
}

@end