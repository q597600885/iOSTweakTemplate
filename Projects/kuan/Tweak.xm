#import <UIKit/UIKit.h>

// ============================================================================
// 1. 前置接口声明
// ============================================================================

@protocol ATNativeADDelegate <NSObject>
@optional
- (void)didFailToLoadADWithPlacementID:(id)placement error:(NSError *)error;
@end

@protocol BUMNativeAdsManagerDelegate <NSObject>
@optional
- (void)nativeAdsManager:(id)manager didFailWithError:(NSError *)error;
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

@interface CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4 : UICollectionViewCell
@end


// ============================================================================
// 2. 信息流/评论区第三方 SDK 拦截 (纯 ObjC)
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
// 5. 漏网之鱼终结者：酷安广告卡片 UI 层安全隐形欺骗 (防官方自营广告)
// ============================================================================

%hook CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4

// 绝招 1：告诉 CollectionView 该卡片高度只有 0.01 (不会引发布局报错，且肉眼不可见)
- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.width, 0.01);
}

// 绝招 2：强制覆盖布局属性高度
- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    UICollectionViewLayoutAttributes *attributes = %orig(layoutAttributes);
    if (attributes.frame.size.height > 1.0) {
        CGRect frame = attributes.frame;
        frame.size.height = 0.01; 
        attributes.frame = frame;
    }
    return attributes;
}

// 绝招 3：彻底隐藏所有视图，杜绝白块现象
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
    self.clipsToBounds = YES;
    for (UIView *subview in self.subviews) {
        subview.hidden = YES;
    }
}

%end


// ============================================================================
// 6. 弹窗辅助
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
                                                                       message:@"酷安全局去广告（含漏网卡片）已生效！"
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
