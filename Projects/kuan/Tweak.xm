#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明 (纯 ObjC SDK + Swift UI 类声明)
// ============================================================================

@protocol ATNativeADDelegate <NSObject>
@optional
- (void)didFailToLoadADWithPlacementID:(id)placement error:(NSError *)error;
@end

@protocol BUMNativeAdsManagerDelegate <NSObject>
@optional
- (void)nativeAdsManager:(id)manager didFailWithError:(NSError *)error;
@end

@protocol GDTNativeExpressAdDelegete <NSObject>
@optional
- (void)nativeExpressAdFailToLoad:(id)nativeExpressAd error:(NSError *)error;
@end

@protocol GDTUnifiedNativeAdDelegate <NSObject>
@optional
- (void)gdt_unifiedNativeAd:(id)unifiedNativeAd didFailWithError:(NSError *)error;
@end

@protocol BUMSplashAdDelegate <NSObject>
@optional
- (void)splashAd:(id)splashAd didFailWithError:(NSError *)error;
- (void)splashAdDidClose:(id)splashAd withType:(NSInteger)type;
@end

@interface ATNativeAD : NSObject
@end
@interface BUMNativeAdsManager : NSObject
@end
@interface BUNativeAdsManager : NSObject
@end
@interface GDTNativeExpressAd : NSObject
@end
@interface GDTUnifiedNativeAd : NSObject
@end
@interface GMSplashAd : NSObject
@property (nonatomic, weak) id<BUMSplashAdDelegate> delegate;
- (void)removeSplashView;
@end
@interface TXAdSplashManager : NSObject
@property (nonatomic, weak) id delegate;
@end
@interface ABUSplashAd : NSObject
- (void)loadAdData;
- (BOOL)isAdValid;
@end

// 💡 声明酷安广告 Cell (Swift 类名替换点号)
@interface CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4 : UICollectionViewCell
@end


// ============================================================================
// 2. 漏网之鱼终结：基于 FLEX 分析的安全 UI 隐藏
// ============================================================================

%hook CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4

// 方案1改良：修改返回size，高度置为 0.01 避免 0 导致的布局引擎闪退
- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.width, 0.01);
}

// 方案1兜底：仅做最基础的隐藏和透明，绝不触碰 subviews，规避野指针崩溃
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
}

// 方案2：如果布局复用导致卡片意外出现，拦截它的关闭逻辑
- (void)didTapCloseButton {
    %orig;
}

%end


// ============================================================================
// 3. 第三方 SDK 底层数据拦截 (保障大盘广告彻底剔除)
// ============================================================================

%hook ATNativeAD
- (void)loadADWithPlacementID:(id)placement extra:(id)extra delegate:(id<ATNativeADDelegate>)delegate {
    if (delegate && [delegate respondsToSelector:@selector(didFailToLoadADWithPlacementID:error:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        [delegate didFailToLoadADWithPlacementID:placement error:safeError];
    }
}
%end

%hook BUMNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    id<BUMNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
    if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        [delegate nativeAdsManager:self didFailWithError:safeError];
    }
}
%end

%hook BUNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    id<BUMNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
    if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        [delegate nativeAdsManager:self didFailWithError:safeError];
    }
}
%end

%hook GDTNativeExpressAd
- (void)loadAd {
    id<GDTNativeExpressAdDelegete> delegate = [self valueForKey:@"delegate"];
    if (delegate && [delegate respondsToSelector:@selector(nativeExpressAdFailToLoad:error:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        [delegate nativeExpressAdFailToLoad:self error:safeError];
    }
}
%end

%hook GDTUnifiedNativeAd
- (void)loadAd {
    id<GDTUnifiedNativeAdDelegate> delegate = [self valueForKey:@"delegate"];
    if (delegate && [delegate respondsToSelector:@selector(gdt_unifiedNativeAd:didFailWithError:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        [delegate gdt_unifiedNativeAd:self didFailWithError:safeError];
    }
}
%end


// ============================================================================
// 4. 酷安开屏拦截 (TXAd / GroMore / AnyThink)
// ============================================================================

%hook TXAdSplashManager
- (void)getSplashAdsWithAdsDataBlock:(void (^)(id adsData))block {
    if (block) block(nil);
}
- (void)getSplashAdsWithAdsDataBlock:(void (^)(id adsData))block renderMode:(unsigned long long)mode {
    if (block) block(nil);
}
- (void)preGetSplashAdData {
    return;
}
- (id)renderSplashTemplateWithAdModel:(id)model config:(id)config {
    return nil;
}
%end

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
// 5. 首次注入提示框
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
    if (!keyWindow) keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    UIViewController *topViewController = keyWindow.rootViewController;
    while (topViewController.presentedViewController) topViewController = topViewController.presentedViewController;
    if ([topViewController isKindOfClass:[UINavigationController class]]) topViewController = [(UINavigationController *)topViewController visibleViewController];
    else if ([topViewController isKindOfClass:[UITabBarController class]]) topViewController = [(UITabBarController *)topViewController selectedViewController];
    return topViewController;
}

static void showInjectAlertIfNeeded(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *const kHasShownKey = @"HasShownCoolapkAdBlockAlert_Key";
    if ([defaults boolForKey:kHasShownKey]) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"结合 FLEX 优化的全效去广告已生效！"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [defaults setBool:YES forKey:kHasShownKey];
            [defaults synchronize];
        }];
        [alert addAction:okAction];
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        showInjectAlertIfNeeded();
    }];
}
