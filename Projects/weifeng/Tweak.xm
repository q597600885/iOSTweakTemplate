#import <UIKit/UIKit.h>
#import "Includes/Debug.h" 

#define LOG_TAG @"WeifengAdBlock"

// ============================================================================
// 1. 接口与协议声明 (完全补齐，杜绝任何编译警告和语法错误)
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 BUNativeAdsManager 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 CSJNativeAdsManager 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 ABUNativeAdsManager 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 ABUSplashAd 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 GDTUnifiedNativeAd 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 GDTNativeExpressAd 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 GDTSplashAd 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 BaiduMobAdNative 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 BaiduMobAdSplash 请求");
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
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 GADBannerView 请求");
}
%end

%hook GADInterstitialAd
// 利用泛型 id 完美绕过 Logos 解析闭包参数的 Bug
+ (void)loadWithAdUnitID:(id)adUnitID request:(id)request completionHandler:(id)completionHandler {
    TweakLog(LOG_TAG, @"[Hook] 成功拦截 GADInterstitialAd 请求");
    if (completionHandler) {
        void (^block)(id, NSError *) = (void (^)(id, NSError *))completionHandler;
        NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{ block(nil, error); });
    }
}
%end

// ============================================================================
// 5. 插件入口与日志初始化
// ============================================================================

%ctor {
    // 每次 App 冷启动，清空之前的沙盒日志
    ResetDebugLog(LOG_TAG);
    
    // 如果后续你还需要挖掘别的暗桩类，可以在这里传入关键词搜索
    // ScanRuntimeClasses(LOG_TAG, @"AdManager");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 威锋全平台去广告插件加载完毕！各大 SDK 底层数据源拦截已全部就绪！");
    }];
}
