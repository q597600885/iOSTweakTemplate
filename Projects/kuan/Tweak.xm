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


// ============================================================================
// 2. 酷安 TXAd 广告引擎拦截 (解决 5分钟热启动开屏)
// ============================================================================

%hook TXAdSplashManager

// 阻断热启动广告数据请求
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

// 彻底屏蔽后台预加载逻辑
- (void)preGetSplashAdData {
    return;
}

// 阻断开屏视图渲染
- (id)renderSplashTemplateWithAdModel:(id)model config:(id)config {
    return nil;
}

%end


// ============================================================================
// 3. 酷安 GroMore (GMSplashAd) & AnyThink (ATSplashManager) 聚合开屏拦截
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
// 4. 酷安帖子/评论区广告 Cell 折叠
// ============================================================================

%hook CoolMarket_GeneralEntityListFeedAdvertisementCellBaseV4

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeZero;
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    UICollectionViewLayoutAttributes *attributes = %orig(layoutAttributes);
    CGRect frame = attributes.frame;
    frame.size.height = 0;
    attributes.frame = frame;
    return attributes;
}

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hook 成功 🎉"
                                                                       message:@"酷安冷/热启动及评论区广告去处已全效生效！"
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
