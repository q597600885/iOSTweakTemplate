#import <UIKit/UIKit.h>
// 如果你有我们之前配置好的 Debug.h，可以取消下面这行的注释
// #import "../../Includes/Debug.h"

#define LOG_TAG @"FengAppAdBlock"

// ============================================================================
// 1. 穿山甲 (Pangle) / 穿山甲聚合 (GroMore) 拦截
// 涉及类：BUNativeAdsManager, CSJNativeAdsManager, ABUNativeAdsManager, ABUSplashAd 等
// ============================================================================

%hook BUNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    // NSLog(@"[%@] 拦截 BU 穿山甲原生广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:error];
            });
        }
    }
}
%end

%hook CSJNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    // NSLog(@"[%@] 拦截 CSJ 穿山甲原生广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:error];
            });
        }
    }
}
%end

%hook ABUNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    // NSLog(@"[%@] 拦截 ABU 穿山甲聚合原生广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:error];
            });
        }
    }
}
%end

%hook ABUSplashAd
- (void)loadAdData {
    // NSLog(@"[%@] 拦截 ABU 穿山甲聚合开屏广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate performSelector:@selector(splashAd:didFailWithError:) withObject:self withObject:error];
            });
        }
    }
}
%end


// ============================================================================
// 2. 腾讯广点通 (GDT) 拦截
// 涉及类：GDTUnifiedNativeAd, GDTNativeExpressAd, GDTSplashAd
// ============================================================================

%hook GDTUnifiedNativeAd
- (void)loadAd {
    // NSLog(@"[%@] 拦截广点通原生广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(gdt_unifiedNativeAd:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate performSelector:@selector(gdt_unifiedNativeAd:didFailWithError:) withObject:self withObject:error];
            });
        }
    }
}
%end

%hook GDTNativeExpressAd
- (void)loadAd {
    // NSLog(@"[%@] 拦截广点通模板广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeExpressAdFailToLoad:error:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate performSelector:@selector(nativeExpressAdFailToLoad:error:) withObject:self withObject:error];
            });
        }
    }
}
%end

%hook GDTSplashAd
- (void)loadAd {
    // NSLog(@"[%@] 拦截广点通开屏广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(splashAdFailToPresent:withError:)]) {
            NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate performSelector:@selector(splashAdFailToPresent:withError:) withObject:self withObject:error];
            });
        }
    }
}
%end


// ============================================================================
// 3. 百度联盟 (BaiduMobAd) 拦截
// 涉及类：BaiduMobAdNative, BaiduMobAdSplash
// ============================================================================

%hook BaiduMobAdNative
- (void)requestNativeAds {
    // NSLog(@"[%@] 拦截百度联盟原生广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdObjectsFailLoad:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 百度失败回调通常只需通知错误码或直接调用
                [delegate performSelector:@selector(nativeAdObjectsFailLoad:) withObject:@"404"];
            });
        }
    }
}
%end

%hook BaiduMobAdSplash
- (void)loadAndDisplay {
    // NSLog(@"[%@] 拦截百度联盟开屏广告请求", LOG_TAG);
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(splashDidFailToLoad:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate performSelector:@selector(splashDidFailToLoad:) withObject:self];
            });
        }
    }
}
%end


// ============================================================================
// 4. 谷歌广告 (Google AdMob) 拦截
// 涉及类：GADBannerView, GADInterstitialAd
// ============================================================================

%hook GADBannerView
- (void)loadRequest:(id)request {
    // NSLog(@"[%@] 拦截 AdMob 横幅广告请求", LOG_TAG);
    // 直接 return 阻断请求，不让它发出网络包
}
%end

%hook GADInterstitialAd
+ (void)loadWithAdUnitID:(id)adUnitID request:(id)request completionHandler:(void (^)(id ad, NSError *error))completionHandler {
    // NSLog(@"[%@] 拦截 AdMob 插屏广告请求", LOG_TAG);
    if (completionHandler) {
        NSError *error = [NSError errorWithDomain:@"AdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(nil, error);
        });
    }
}
%end


// ============================================================================
// 5. 内部广告包装类拦截 (针对 fengapp 自身的控制器)
// 涉及类：FengAdManager, AdvertisingViewModel 等
// ============================================================================

// 注意：由于 fengapp 是 Swift 编写的，类名在运行时会被重整 (Mangle)
// 这里使用任意字符串匹配进行 Hook，需确保 Theos 支持 Swift 混编，或者转而隐藏 UI

%hook _TtC7fengapp13FengAdManager
- (void)loadAd {
    // NSLog(@"[%@] 阻断内部广告管理器加载", LOG_TAG);
}
%end

%hook _TtC7fengapp13FengAdLoader
- (void)requestAd {
    // NSLog(@"[%@] 阻断内部广告加载器", LOG_TAG);
}
%end

%hook _TtC7fengapp19AdvertisingViewModel
- (void)fetchAds {
    // NSLog(@"[%@] 阻断广告视图模型拉取数据", LOG_TAG);
}
%end
