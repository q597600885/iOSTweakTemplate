#import <UIKit/UIKit.h>

// 1. 声明必要的基类，解决编译属性找不到的问题
@interface CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4 : UIView
@end

@interface CoolMarketFeedModel : NSObject
@property (nonatomic, copy) NSString *entityTemplate;
@property (nonatomic, assign) NSInteger isAd;
@end


// ==========================================
// 1. 列表 & 评论区广告 Cell 彻底消除
// ==========================================

// Hook 广告 Cell 的基类，从视图层级直接拉隐和把高度缩为 0
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

// 阻止广告 Cell 再次展开布局
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.hidden = YES;
    view.frame = CGRectZero;
}

// 防空高度：如果 TableView/CollectionView 询问高度，直接返回 0
- (double)cellHeight {
    return 0.0;
}

%end


// ==========================================
// 2. 评论区 / feed 广告数据源拦截 (数据层去广告)
// ==========================================

%hook CoolMarketFeedModel

// 如果模型判断为广告，直接标记为非广告或模板置空
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

// 拦截酷安开屏 AdView
%hook CoolMarketSplashAdView

- (id)initWithFrame:(CGRect)frame {
    // 初始化直接隐藏并跳过
    id origSelf = %orig;
    if (origSelf) {
        UIView *view = (UIView *)origSelf;
        view.hidden = YES;
        [view removeFromSuperview];
    }
    return origSelf;
}

%end

// 拦截开屏广告控制器，强行触发“跳过/完成”回调
%hook CoolMarketSplashViewController

- (void)viewDidLoad {
    %orig;
    // 隐藏开屏 VC 的 view
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    
    // 尝试调用常见的跳过/结束方法
    if ([self respondsToSelector:@selector(skipAd)]) {
        [self performSelector:@selector(skipAd)];
    } else if ([self respondsToSelector:@selector(dismissSplash)]) {
        [self performSelector:@selector(dismissSplash)];
    }
}

%end
