#import <UIKit/UIKit.h>
#import "Includes/Debug.h" 

#define LOG_TAG @"WeifengAdBlock"

// ============================================================================
// 1. 接口与协议声明 (补全所有未声明的方法和选择器，彻底杜绝语法错误)
// ============================================================================

@protocol BUNativeAdsManagerDelegate <NSObject>
@optional
- (void)nativeAdsManager:(id)manager didFailWithError:(NSError *)error;
@end

@protocol CSJNativeAdsManagerDelegate <NSObject>
@optional
- (void)nativeAdsManager:(id)manager didFailWithError:(NSError *)error;
@end

@protocol ABUNativeAdsManagerDelegate <NSObject>
@optional
- (void)nativeAdsManager:(id)manager didFailWithError:(NSError *)error;
@end

@protocol ABUSplashAdDelegate <NSObject>
@optional
- (void)splashAd:(id)ad didFailWithError:(NSError *)error;
@end

@protocol GDTUnifiedNativeAdDelegate <NSObject>
@optional
- (void)gdt_unifiedNativeAd:(id)unifiedNativeAd didFailWithError:(NSError *)error;
@end

@protocol GDTNativeExpressAdDelegete <NSObject>
@optional
- (void)nativeExpressAdFailToLoad:(id)nativeExpressAd error:(NSError *)error;
@end

@protocol GDTSplashAdDelegate <NSObject>
@optional
- (void)splashAdFailToPresent:(id)splashAd withError:(NSError *)error;
@end

// 🌟 新增：补全百度联盟的代理声明，解决未声明选择器导致的语法错误
@protocol BaiduMobAdNativeDelegate <NSObject>
@optional
- (void)nativeAdObjectsFailLoad:(id)reason;
@end

@protocol BaiduMobAdSplashDelegate <NSObject>
@optional
- (void)splashDidFailToLoad:(id)splash;
@end

@interface BUNativeAdsManager : NSObject
@end
@interface CSJNativeAdsManager : NSObject
@end
@interface ABUNativeAdsManager : NSObject
@end
@interface ABUSplashAd : NSObject
@end
@interface GDTUnifiedNativeAd : NSObject
@end
@interface GDTNativeExpressAd : NSObject
@end
@interface GDTSplashAd : NSObject
@end
@interface BaiduMobAdNative : NSObject
@end
@interface BaiduMobAdSplash : NSObject
@end
@interface GADBannerView : UIView
@end
@interface GADInterstitialAd : NSObject
@end


// ============================================================================
// 2. 穿山甲 (Pangle) / 穿山甲聚合 (GroMore) 拦截
// ============================================================================

%hook BUNativeAdsManager
- (void)loadAdDataWithCount:(NSInteger)count {
    TweakLog(LOG_TAG, @"[Hook] 拦截 BUNativeAdsManager");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<BUNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ [delegate nativeAdsManager:self didFailWithError:error]; });
        }
    }
}
%end

%hook CSJNativeAdsManager
- (void)loadAdDataWithCount:(NSInteger)count {
    TweakLog(LOG_TAG, @"[Hook] 拦截 CSJNativeAdsManager");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<CSJNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ [delegate nativeAdsManager:self didFailWithError:error]; });
        }
    }
}
%end

%hook ABUNativeAdsManager
- (void)loadAdDataWithCount:(NSInteger)count {
    TweakLog(LOG_TAG, @"[Hook] 拦截 ABUNativeAdsManager");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<ABUNativeAdsManagerDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ [delegate nativeAdsManager:self didFailWithError:error]; });
        }
    }
}
%end

%hook ABUSplashAd
- (void)loadAdData {
    TweakLog(LOG_TAG, @"[Hook] 拦截 ABUSplashAd");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<ABUSplashAdDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ [delegate splashAd:self didFailWithError:error]; });
        }
    }
}
%end


// ============================================================================
// 3. 腾讯广点通 (GDT) 拦截
// ============================================================================

%hook GDTUnifiedNativeAd
- (void)loadAd {
    TweakLog(LOG_TAG, @"[Hook] 拦截 GDTUnifiedNativeAd");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<GDTUnifiedNativeAdDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(gdt_unifiedNativeAd:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ [delegate gdt_unifiedNativeAd:self didFailWithError:error]; });
        }
    }
}
%end

%hook GDTNativeExpressAd
- (void)loadAd {
    TweakLog(LOG_TAG, @"[Hook] 拦截 GDTNativeExpressAd");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<GDTNativeExpressAdDelegete> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeExpressAdFailToLoad:error:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ [delegate nativeExpressAdFailToLoad:self error:error]; });
        }
    }
}
%end

%hook GDTSplashAd
- (void)loadAd {
    TweakLog(LOG_TAG, @"[Hook] 拦截 GDTSplashAd");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<GDTSplashAdDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(splashAdFailToPresent:withError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ [delegate splashAdFailToPresent:self withError:error]; });
        }
    }
}
%end


// ============================================================================
// 4. 百度联盟 (BaiduMobAd) & 谷歌 (Google AdMob) 拦截
// ============================================================================

%hook BaiduMobAdNative
- (void)requestNativeAds {
    TweakLog(LOG_TAG, @"[Hook] 拦截 BaiduMobAdNative");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<BaiduMobAdNativeDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdObjectsFailLoad:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{ 
                [delegate nativeAdObjectsFailLoad:nil]; 
            });
        }
    }
}
%end

%hook BaiduMobAdSplash
- (void)loadAndDisplay {
    TweakLog(LOG_TAG, @"[Hook] 拦截 BaiduMobAdSplash");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<BaiduMobAdSplashDelegate> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(splashDidFailToLoad:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{ 
                [delegate splashDidFailToLoad:self]; 
            });
        }
    }
}
%end

%hook GADBannerView
- (void)loadRequest:(id)request {
    TweakLog(LOG_TAG, @"[Hook] 拦截 GADBannerView");
}
%end

%hook GADInterstitialAd
+ (void)loadWithAdUnitID:(id)adUnitID request:(id)request completionHandler:(id)completionHandler {
    TweakLog(LOG_TAG, @"[Hook] 拦截 GADInterstitialAd");
    if (completionHandler) {
        // 🌟 修复：安全强转 Block，杜绝类型不匹配错误
        void (^block)(id, NSError *) = (void (^)(id, NSError *))completionHandler;
        NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{ block(nil, error); });
    }
}
%end

// ============================================================================
// 5. 插件入口
// ============================================================================

%ctor {
    ResetDebugLog(LOG_TAG);
    
    // 调用一次，防止 unused-function 报错
    ScanRuntimeClasses(LOG_TAG, @"AdManager");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 威锋全平台去广告插件已启动！");
    }];
}
