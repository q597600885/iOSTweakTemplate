#import <UIKit/UIKit.h>

// 1. 完整声明所有 Hook 到的类接口，彻底解决前向声明 (forward declaration) 报错
@interface CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4 : UIView
@end

@interface CoolMarketFeedModel : NSObject
@property (nonatomic, copy) NSString *entityTemplate;
@property (nonatomic, assign) NSInteger isAd;
@end

@interface CoolMarketSplashAdView : UIView
@end

@interface CoolMarketSplashViewController : UIViewController
- (void)skipAd;
- (void)dismissSplash;
@end


// ==========================================
// 1. 列表 & 评论区广告 Cell 彻底消除
// ==========================================

%hook CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4

- (id)initWithFrame:(CGRect)frame {
    id origSelf = %orig;
    if (origSelf) {
        UIView *view = (UIView *)origSelf;
        view.hidden = YES;
        view.alpha = 0.0;
        view.frame = CGRectZero;
    }
    return origSelf;
}

- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.hidden = YES;
    view.frame = CGRectZero;
}

- (double)cellHeight {
    return 0.0;
}

%end


// ==========================================
// 2. 评论区 / feed 广告数据源拦截
// ==========================================

%hook CoolMarketFeedModel

- (BOOL)isFeedAd {
    return NO;
}

- (BOOL)isAd {
    return NO;
}

%end


// ==========================================
// 3. 酷安开屏广告全路径强行跳过
// ==========================================

%hook CoolMarketSplashAdView

- (id)initWithFrame:(CGRect)frame {
    id origSelf = %orig;
    if (origSelf) {
        UIView *view = (UIView *)origSelf;
        view.hidden = YES;
        [view removeFromSuperview];
    }
    return origSelf;
}

%end

%hook CoolMarketSplashViewController

- (void)viewDidLoad {
    %orig;
    
    // 隐藏视图
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    
    // 转换类型避开编译器检查
    id slf = self;
    if ([slf respondsToSelector:@selector(skipAd)]) {
        [slf performSelector:@selector(skipAd)];
    } else if ([slf respondsToSelector:@selector(dismissSplash)]) {
        [slf performSelector:@selector(dismissSplash)];
    }
}

%end
