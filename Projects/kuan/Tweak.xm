#import <UIKit/UIKit.h>
#import "Debug.h" // 👈 引入调试头文件

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
// 2. 原生 SDK 视图物理折叠 + 日志确认
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
    TweakLog(@"[Action] 成功物理隐形 ABUNativeAdView (GroMore 原生视图)");
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
    TweakLog(@"[Action] 成功物理隐形 GDTUnifiedNativeAdView (广点通原生视图)");
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
    TweakLog(@"[Action] 成功物理隐形 GDTNativeExpressAdView");
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
    TweakLog(@"[Action] 成功物理隐形 BUNativeAdView");
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
    TweakLog(@"[Action] 成功物理隐形 BUMNativeAdView");
}
%end


// ============================================================================
// 3. 第三方 SDK 底层数据拦截 + 异步安全日志
// ============================================================================

%hook ATNativeAD
- (void)loadADWithPlacementID:(id)placement extra:(id)extra delegate:(id<ATNativeADDelegate>)delegate {
    TweakLog(@"[Hook 触发] ATNativeAD 开始请求广告, PlacementID: %@", placement);
    if (delegate && [delegate respondsToSelector:@selector(didFailToLoadADWithPlacementID:error:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didFailToLoadADWithPlacementID:placement error:safeError];
            TweakLog(@"[Action] 已向 TopOn 抛出模拟失败回调");
        });
    }
}
%end

%hook BUMNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    TweakLog(@"[Hook 触发] BUMNativeAdsManager 请求广告 Count: %lld", count);
    if ([self respondsToSelector:@selector(delegate)]) {
        id<BUMNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:safeError];
                TweakLog(@"[Action] 已向 GroMore 抛出模拟失败回调");
            });
        }
    }
}
%end

%hook GDTNativeExpressAd
- (void)loadAd {
    TweakLog(@"[Hook 触发] GDTNativeExpressAd 请求广告");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<GDTNativeExpressAdDelegete> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeExpressAdFailToLoad:error:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeExpressAdFailToLoad:self error:safeError];
                TweakLog(@"[Action] 已向 广点通 抛出模拟失败回调");
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
    TweakLog(@"[Hook 触发] 拦截酷安热启动开屏请求");
    if (block) {
        block(nil);
    }
}
- (void)preGetSplashAdData {
    TweakLog(@"[Hook 触发] 拦截酷安切后台预加载广告");
    return;
}
- (id)renderSplashTemplateWithAdModel:(id)model config:(id)config {
    TweakLog(@"[Hook 触发] 拦截酷安开屏模板渲染");
    return nil;
}
%end

%hook GMSplashAd
- (void)loadAdData {
    TweakLog(@"[Hook 触发] 拦截 GroMore 开屏加载");
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate splashAd:(id)self didFailWithError:nil];
        });
    }
}
%end


// ============================================================================
// 5. 插件入口 (扫描内存类 + 加载日志)
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(@"🎉 酷安 Tweak 成功注入并启动！");
        
        // 自动扫描内存中带 Splash 和 Ad 关键字的类，帮助我们排查漏网之鱼
        ScanRuntimeClasses(@"Splash");
        ScanRuntimeClasses(@"Ad");
    }];
}
