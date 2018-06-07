//
//  ProductDetailView.m
//  ProductDetail
//
//  Created by 意一yiyi on 2018/6/6.
//  Copyright © 2018年 意一yiyi. All rights reserved.
//

#import "ProductDetailView.h"
#import "ZFPlayer.h"
#import "ZFAVPlayerManager.h"
#import "ZFPlayerControlView.h"
#import "KTVHTTPCache.h"
#import "UIImageView+WebCache.h"

@interface ProductDetailView ()<UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;

@property (strong, nonatomic) UIImageView *videoCoverImageView;// 视频封面
@property (strong, nonatomic) UIButton *playButton;// 播放按钮
@property (strong, nonatomic) ZFPlayerController *player;
@property (strong, nonatomic) ZFPlayerControlView *controlView;

@property (copy,   nonatomic) NSArray *dataArray;// 视频和图片url数组

@end

@implementation ProductDetailView

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        
        [self initialize];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        [self initialize];
    }
    
    return self;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    CGFloat x = self.scrollView.contentOffset.x;
    self.pageControl.currentPage = x / self.bounds.size.width;
    
    if (self.pageControl.currentPage >= 1) {
        
        self.pageControl.hidden = NO;
    }else {
    
        if (self.player == nil || self.player.currentPlayerManager.playState == ZFPlayerPlayStatePlayStopped) {
            
            self.pageControl.hidden = NO;
        }else {
            
            self.pageControl.hidden = YES;
        }
    }
}


#pragma mark - public methods

- (void)reloadUIWithDataArray:(NSArray *)imageAndVideoArray {
    
    self.dataArray = [imageAndVideoArray copy];
    
    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];
    
    if ([self.dataArray[0] hasSuffix:@".jpg"]) {// 全是图片的情况
        
        for (int i = 0; i < self.dataArray.count; i ++) {
        
            UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.size.width * i, 0, self.frame.size.width, self.frame.size.height)];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [imageView sd_setImageWithURL:self.dataArray[i]];
            imageView.layer.masksToBounds = YES;
            [self.scrollView addSubview:imageView];
        }
    }else {// 有视频有图片的情况
        
        for (int i = 0; i < self.dataArray.count; i ++) {
            
            if (i == 0) {
                
                [self.videoCoverImageView sd_setImageWithURL:self.dataArray[1]];// 取第一张图作为视频配图
                [self.videoCoverImageView addSubview:self.playButton];
                [self.scrollView addSubview:self.videoCoverImageView];
            }else {
                
                UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.frame.size.width * i, 0, self.frame.size.width, self.frame.size.height)];
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                [imageView sd_setImageWithURL:self.dataArray[i]];
                imageView.layer.masksToBounds = YES;
                [self.scrollView addSubview:imageView];
            }
        }
    }
}


#pragma mark - private methods

- (void)playClick:(UIButton *)button {
    
    self.pageControl.hidden = YES;
    [self.controlView resetControlView];
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    /// 播放器相关
    self.player = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.videoCoverImageView];
    self.player.controlView = self.controlView;
    @weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self endEditing:YES];
//        [self setNeedsStatusBarAppearanceUpdate];
    };
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        [self.player enterFullScreen:NO animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.player.orientationObserver.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.player stop];
            self.pageControl.hidden = NO;
        });
    };
    NSString *URLString = [self.dataArray[0] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *proxyURLString = [KTVHTTPCache proxyURLStringWithOriginalURLString:URLString];
    playerManager.assetURL = [NSURL URLWithString:proxyURLString];
}


#pragma mark - setter，getter

- (UIScrollView *)scrollView {
    
    if (_scrollView == nil) {
        
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor = [UIColor clearColor];
        
        _scrollView.delegate = self;
        
        _scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _scrollView.contentSize = CGSizeMake(self.dataArray.count * self.frame.size.width, self.frame.size.height);
        _scrollView.contentOffset = CGPointMake(0, 0);
        
        _scrollView.pagingEnabled  = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    
    return _scrollView;
}

- (UIPageControl *)pageControl {
    
    if (_pageControl == nil) {
        
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.backgroundColor = [UIColor clearColor];
        _pageControl.frame = CGRectMake((self.frame.size.width - 100) / 2.0, self.frame.size.width - 40, 100, 30);
        
        _pageControl.numberOfPages = self.dataArray.count;
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.hidesForSinglePage = YES;
        _pageControl.currentPage = 0;
        _pageControl.userInteractionEnabled = NO;
    }
    
    return _pageControl;
}

- (UIImageView *)videoCoverImageView {
    
    if (_videoCoverImageView == nil) {
        
        _videoCoverImageView = [[UIImageView alloc] init];
        _videoCoverImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _videoCoverImageView.backgroundColor = [UIColor clearColor];
        
        _videoCoverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _videoCoverImageView.layer.masksToBounds = YES;
        _videoCoverImageView.userInteractionEnabled = YES;
    }
    
    return _videoCoverImageView;
}

- (UIButton *)playButton {
    
    if (_playButton == nil) {
        
        _playButton = [[UIButton alloc] init];
        _playButton.frame = CGRectMake(0, 0, 60, 60);
        _playButton.center = self.videoCoverImageView.center;
        _playButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_playButton setImage:[UIImage imageNamed:@"playVideo"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (ZFPlayerControlView *)controlView {
    
    if (_controlView == nil) {
        
        _controlView = [ZFPlayerControlView new];
        [_controlView showTitle:@"商品详情" coverURLString:self.dataArray[1] fullScreenMode:ZFFullScreenModePortrait];
    }
    
    return _controlView;
}

#pragma mark - initialize

- (void)initialize {
    
    self.dataArray = [NSArray array];
}


#pragma mark - some configurations

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    if (self.player.isFullScreen) {
        
        return UIStatusBarStyleLightContent;
    }
    
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    
    return self.player.isStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    
    return UIStatusBarAnimationSlide;
}

- (BOOL)shouldAutorotate {
    
    return NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self endEditing:YES];
}

@end
