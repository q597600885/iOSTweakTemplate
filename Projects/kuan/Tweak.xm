#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明
// ============================================================================

@protocol BUMSplashAdDelegate <NSObject>
@optional
- (void)splashAd:(id)splashAd didFailWithError:(NSError *)error;
- (void)splashAdDidClose:(id)splashAd withType:(NSInteger)type;
@end

@interface GMSplashAd : NSObject
@property (nonatomic, weak) id<BUMSplashAdDelegate> delegate;
- (void)removeSplashView;
@end

@interface TXAdSplashManager : NSObject
@property (nonatomic, weak) id delegate;
@end

@interface ABUNativeAdView : UIView
- (void)removeFromSuperview;
@end

@interface CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4 : UICollectionViewCell
@end


// ============================================================================
// 2. 酷安冷/热启动开屏广告拦截 (100% 稳定防闪退)
// ============================================================================

// 拦截 TXAd 引擎 (热启动/5分钟定时开屏)
%hook TXAdSplashManager

- (void)getSplashAdsWithAdsDataBlock:(void (^)(id adsData))block {
    if (block) {
        block(nil);
    }
}

- (void)getSplashAdsWithAdsDataBlock:(void (^)(id adsData))block renderMode:(unsigned long long)mode {
    if (block) {
        block(nil);
    }
}

- (void)preGetSplashAdData {
    return;
}

- (id)renderSplashTemplateWithAdModel:(id)model config:(id)config {
    return nil;
}

%end

// 拦截 GroMore 聚合 SDK (冷启动开屏)
%hook GMSplashAd

- (void)loadAdData {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        [self.delegate splashAd:(id)self didFailWithError:nil];
    }
}

- (void)loadAdDataWithMediaSlotConfigIDs:(id)a0 sign:(long long)a1 {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        [self.delegate splashAd:(id)self didFailWithError:nil];
    }
}

- (void)showSplashViewInRootViewController:(id)a0 {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidClose:withType:)]) {
        [self.delegate splashAdDidClose:(id)self withType:0];
    } else if ([self respondsToSelector:@selector(removeSplashView)]) {
        [self removeSplashView];
    }
}

- (void)showCardViewInRootViewController:(id)a0 {
    return;
}

%end

%hook ABUSplashAd

- (void)loadAdData {
    return;
}

- (BOOL)isAdValid {
    return NO;
}

%end


// ============================================================================
// 3. 酷安原生信息流广告卡片拦截 (ABUNativeAdView 精准消除)
// ============================================================================

%hook ABUNativeAdView

// 1. 告诉 SDK 广告尚未准备好
- (BOOL)isReady {
    return NO;
}

// 2. 阻断广告卡片 UI 渲染
- (void)render {
    return;
}

// 3. 阻止挂载到父视图，若挂载直接从界面移除并隐藏
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview) {
        self.hidden = YES;
        [self removeFromSuperview];
    } else {
        %orig;
    }
}

%end


// ============================================================================
// 4. 酷安评论区/信息流广告 Cell 容器隐形 (安全层)
// ============================================================================

%hook CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.contentView.hidden = YES;
    for (UIView *subview in self.subviews) {
        subview.hidden = YES;
    }
}

%end


// ============================================================================
// 5. UI 弹窗辅助函数 (仅首次提示一次)
// ============================================================================

static UIViewController *getTopViewController(void) {
    __block UIWindow *keyWindow = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
            if (keyWindow) break;
        }
    }
    
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
#pragma clang diagnostic pop

    UIViewController *topViewController = keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        topViewController = [(UINavigationController *)topViewController visibleViewController];
    } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
        topViewController = [(UITabBarController *)topViewController selectedViewController];
    }
    
    return topViewController;
}

static void showInjectAlertIfNeeded(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *const kHasShownKey = @"HasShownCoolapkAdBlockAlert_Key";

    if ([defaults boolForKey:kHasShownKey]) {
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        UIAlertController *alert
