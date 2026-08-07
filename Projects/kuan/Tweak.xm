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

@interface ABUSplashAd : NSObject
- (void)loadAdData;
- (BOOL)isAdValid;
@end

// 声明广告 Loader 类 (Swift 类映射)
@interface CoolMarket_GeneralEntityListFeedAdvertisementLoader_Topon : NSObject
- (void)didFailToLoadADWithPlacementID:(id)a0 error:(id)a1;
@end

@interface CoolMarket_GeneralEntityListFeedAdvertisementLoader_GMSelfDraw : NSObject
- (void)nativeAdsManager:(id)a0 didFailWithError:(id)a1;
@end


// ============================================================================
// 2. 酷安信息流/评论区广告 Loader 源头切断 (数据层点杀，绝对不闪退)
// ============================================================================

// 1. 切断 GroMore 原生自渲染广告 (穿山甲)
%hook CoolMarket_GeneralEntityListFeedAdvertisementLoader_GMSelfDraw

- (void)nativeAdsManagerSuccessToLoad:(id)a0 nativeAds:(id)a1 {
    // 当穿山甲广告加载成功时，故意欺骗酷安，给它抛出一个失败回调，不把广告加进列表数据源
    if ([self respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
        [self nativeAdsManager:a0 didFailWithError:nil];
    }
}

%end

// 2. 切断 Topon 聚合原生广告
%hook CoolMarket_GeneralEntityListFeedAdvertisementLoader_Topon

- (void)didFinishLoadingADWithPlacementID:(id)a0 {
    // 收到加载成功通知时，直接转化为失败回调
    if ([self respondsToSelector:@selector(didFailToLoadADWithPlacementID:error:)]) {
        [self didFailToLoadADWithPlacementID:a0 error:nil];
    }
}

%end


// ============================================================================
// 3. 酷安热启动/定时开屏广告拦截 (TXAd 引擎)
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


// ============================================================================
// 4. 酷安冷启动开屏广告拦截 (GroMore / AnyThink 聚合 SDK)
// ============================================================================

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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"酷安开屏及评论区信息流去广告已生效！"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" 
                                                           style:UIAlertActionStyleDefault 
                                                         handler:^(UIAlertAction * _Nonnull action) {
            [defaults setBool:YES forKey:kHasShownKey];
            [defaults synchronize];
        }];

        [alert addAction:okAction];
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}


// ============================================================================
// 6. Tweak 入口
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        showInjectAlertIfNeeded();
    }];
}
