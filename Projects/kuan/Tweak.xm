#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明 (补充 SDK 原生视图类)
// ============================================================================

// --- 代理协议 ---
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

// --- 数据层类 ---
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

// --- SDK 渲染视图类 ---
@interface ABUNativeAdView : UIView
@end
@interface GDTUnifiedNativeAdView : UIView
@end
@interface GDTNativeExpressAdView : UIView
@end
@interface BUNativeAdView : UIView
@end
@interface BUMNativeAdView : UIView
@end


// ============================================================================
// 2. 漏网之鱼终结：原生 SDK 视图物理折叠 (绝不闪退)
// ============================================================================

%hook ABUNativeAdView
- (CGSize)intrinsicContentSize { 
    return CGSizeZero; 
}
- (CGSize)sizeThatFits:(CGSize)size { 
    return CGSizeZero; 
}
- (void)layoutSubviews { 
    %orig; 
    self.hidden = YES; 
}
%end

%hook GDTUnifiedNativeAdView
- (CGSize)intrinsicContentSize { 
    return CGSizeZero; 
}
- (CGSize)sizeThatFits:(CGSize)size { 
    return CGSizeZero; 
}
- (void)layoutSubviews { 
    %orig; 
    self.hidden = YES; 
}
%end

%hook GDTNativeExpressAdView
- (CGSize)intrinsicContentSize { 
    return CGSizeZero; 
}
- (CGSize)sizeThatFits:(CGSize)size { 
    return CGSizeZero; 
}
- (void)layoutSubviews { 
    %orig; 
    self.hidden = YES; 
}
%end

%hook BUNativeAdView
- (CGSize)intrinsicContentSize { 
    return CGSizeZero; 
}
- (CGSize)sizeThatFits:(CGSize)size { 
    return CGSizeZero; 
}
- (void)layoutSubviews { 
    %orig; 
    self.hidden = YES; 
}
%end

%hook BUMNativeAdView
- (CGSize)intrinsicContentSize { 
    return CGSizeZero; 
}
- (CGSize)sizeThatFits:(CGSize)size { 
    return CGSizeZero; 
}
- (void)layoutSubviews { 
    %orig; 
    self.hidden = YES; 
}
%end


// ============================================================================
// 3. 第三方 SDK 底层数据拦截 (异步安全策略)
// ============================================================================

%hook ATNativeAD
- (void)loadADWithPlacementID:(id)placement extra:(id)extra delegate:(id<ATNativeADDelegate>)delegate {
    if (delegate && [delegate respondsToSelector:@selector(didFailToLoadADWithPlacementID:error:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didFailToLoadADWithPlacementID:placement error:safeError];
        });
    }
}
%end

%hook BUMNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    if ([self respondsToSelector:@selector(delegate)]) {
        id<BUMNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:safeError];
            });
        }
    }
}
%end

%hook BUNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    if ([self respondsToSelector:@selector(delegate)]) {
        id<BUMNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:safeError];
            });
        }
    }
}
%end

%hook GDTNativeExpressAd
- (void)loadAd {
    if ([self respondsToSelector:@selector(delegate)]) {
        id<GDTNativeExpressAdDelegete> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeExpressAdFailToLoad:error:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeExpressAdFailToLoad:self error:safeError];
            });
        }
    }
}
%end

%hook GDTUnifiedNativeAd
- (void)loadAd {
    if ([self respondsToSelector:@selector(delegate)]) {
        id<GDTUnifiedNativeAdDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(gdt_unifiedNativeAd:didFailWithError:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate gdt_unifiedNativeAd:self didFailWithError:safeError];
            });
        }
    }
}
%end


// ============================================================================
// 4. 酷安开屏拦截 (TXAd / GroMore / AnyThink)
// ============================================================================

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

%hook GMSplashAd
- (void)loadAdData {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate splashAd:(id)self didFailWithError:nil];
        });
    }
}
- (void)loadAdDataWithMediaSlotConfigIDs:(id)a0 sign:(long long)a1 {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate splashAd:(id)self didFailWithError:nil];
        });
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
    if ([defaults boolForKey:kHasShownKey]) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"底层视图物理折叠已生效，彻底告别漏网广告！"
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
