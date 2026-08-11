#import <UIKit/UIKit.h>
#import "../../Includes/Debug.h" 

#define LOG_TAG @"Coolapk"

// ============================================================================
// 1. 前置接口声明 (补全所有新老协议)
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
@interface GMNativeAdsManager : NSObject
@end
@interface CSJNativeAdsManager : NSObject
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


// ============================================================================
// 2. 第三方 SDK 底层数据拦截 (全网段覆盖，杜绝白块)
// ============================================================================

%hook ATNativeAD
- (void)loadADWithPlacementID:(id)placement extra:(id)extra delegate:(id<ATNativeADDelegate>)delegate {
    TweakLog(LOG_TAG, @"[Hook 触发] ATNativeAD 开始请求");
    if (delegate && [delegate respondsToSelector:@selector(didFailToLoadADWithPlacementID:error:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didFailToLoadADWithPlacementID:placement error:safeError];
        });
    }
}
%end

// 拦截所有穿山甲/GroMore的老版本请求
%hook BUMNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    TweakLog(LOG_TAG, @"[Hook 触发] BUMNativeAdsManager 请求广告");
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

// 拦截所有穿山甲/GroMore的新版本请求 (GM / CSJ / BU)
%hook GMNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    TweakLog(LOG_TAG, @"[Hook 触发] GMNativeAdsManager 请求广告");
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:safeError];
            });
        }
    }
}
%end

%hook CSJNativeAdsManager
- (void)loadAdDataWithCount:(long long)count {
    TweakLog(LOG_TAG, @"[Hook 触发] CSJNativeAdsManager 请求广告");
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
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
    TweakLog(LOG_TAG, @"[Hook 触发] BUNativeAdsManager 请求广告");
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeAdsManager:didFailWithError:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeAdsManager:self didFailWithError:safeError];
            });
        }
    }
}
%end

// 拦截广点通老版请求
%hook GDTNativeExpressAd
- (void)loadAd {
    TweakLog(LOG_TAG, @"[Hook 触发] GDTNativeExpressAd 请求广告");
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

// 拦截广点通新版请求 (解决当前截图中留白块的罪魁祸首)
%hook GDTUnifiedNativeAd
- (void)loadAd {
    TweakLog(LOG_TAG, @"[Hook 触发] GDTUnifiedNativeAd 请求广告");
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
// 3. 酷安冷/热开屏拦截
// ============================================================================

%hook TXAdSplashManager
- (void)getSplashAdsWithAdsDataBlock:(void (^)(id adsData))block {
    TweakLog(LOG_TAG, @"[Hook 触发] 拦截酷安 TXAd 热启动开屏");
    if (block) {
        block(nil);
    }
}
- (void)preGetSplashAdData {
    TweakLog(LOG_TAG, @"[Hook 触发] 拦截酷安切后台预加载广告");
    return;
}
- (id)renderSplashTemplateWithAdModel:(id)model config:(id)config {
    TweakLog(LOG_TAG, @"[Hook 触发] 拦截酷安开屏模板渲染");
    return nil;
}
%end

%hook GMSplashAd
- (void)loadAdData {
    TweakLog(LOG_TAG, @"[Hook 触发] 拦截 GroMore 开屏加载");
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate splashAd:(id)self didFailWithError:safeError];
        });
    }
}
- (void)loadAdDataWithMediaSlotConfigIDs:(id)a0 sign:(long long)a1 {
    TweakLog(LOG_TAG, @"[Hook 触发] 拦截 GroMore 扩展开屏加载");
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate splashAd:(id)self didFailWithError:safeError];
        });
    }
}
- (void)showSplashViewInRootViewController:(id)a0 {
    TweakLog(LOG_TAG, @"[Hook 触发] 阻断 GroMore 开屏展示");
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidClose:withType:)]) {
        [self.delegate splashAdDidClose:(id)self withType:0];
    } else if ([self respondsToSelector:@selector(removeSplashView)]) {
        [self removeSplashView];
    }
}
%end


// ============================================================================
// 4. 插件入口
// ============================================================================

%ctor {
    ResetDebugLog(LOG_TAG);
    
    ScanRuntimeClasses(LOG_TAG, @"Splash");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(LOG_TAG, @"🎉 酷安去广告插件已启动，已修复白块问题！");
    }];
}
