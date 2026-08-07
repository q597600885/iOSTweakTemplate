#import <UIKit/UIKit.h>

// ==========================================
// 1. 拦截 TopOn 广告加载器 (源头拦截)[span_3](start_span)[span_3](end_span)
// ==========================================
%hook "CoolMarket.GeneralEntityListFeedAdvertisementLoader_Topon"

- (void)didFinishLoadingADWithPlacementID:(id)placementID {
    // 拦截成功加载，转为触发失败回调
    id slf = self;
    if ([slf respondsToSelector:@selector(didFailToLoadADWithPlacementID:error:)]) {
        [slf didFailToLoadADWithPlacementID:placementID error:nil];
    }
}

%end


// ==========================================
// 2. 拦截穿山甲 / 自渲染广告加载器 (源头拦截)[span_4](start_span)[span_4](end_span)
// ==========================================
%hook "CoolMarket.GeneralEntityListFeedAdvertisementLoader_GMSelfDraw"

- (void)nativeAdsManagerSuccessToLoad:(id)adsManager nativeAds:(id)nativeAds {
    // 拦截成功加载，转为触发失败回调
    id slf = self;
    if ([slf respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
        [slf nativeAdsManager:adsManager didFailWithError:nil];
    }
}

%end


// ==========================================
// 3. 拦截信息流广告 Cell (UI 视图强行折叠与隐藏)[span_5](start_span)[span_5](end_span)
// ==========================================
%hook "CoolMarket.GeneralEntityListFeedAdvertisementCellBaseV4"

- (id)initWithFrame:(CGRect)frame {
    id origSelf = %orig;
    if (origSelf) {
        UIView *view = (UIView *)origSelf;
        view.hidden = YES;
        view.alpha = 0.0;
    }
    return origSelf;
}

// 核心：强行返回 0 尺寸，防止 CollectionView 留下空白占位[span_6](start_span)[span_6](end_span)
- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeZero;
}

- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.hidden = YES;
    view.frame = CGRectZero;
}

%end


// ==========================================
// 4. 拦截 AdminInfo 广告 Cell[span_7](start_span)[span_7](end_span)
// ==========================================
%hook "CoolMarket.GeneralEntityListFeedAdvertisementAdminInfoCell"

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeZero;
}

- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    view.hidden = YES;
    view.frame = CGRectZero;
}

%end


// ==========================================
// 5. 保留开屏跳过逻辑
// ==========================================
%hook CoolMarketSplashViewController

- (void)viewDidLoad {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    
    id slf = self;
    if ([slf respondsToSelector:@selector(skipAd)]) {
        [slf performSelector:@selector(skipAd)];
    } else if ([slf respondsToSelector:@selector(dismissSplash)]) {
        [slf performSelector:@selector(dismissSplash)];
    }
}

%end
