#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// 0. 自包含调试日志与内存扫描模块
// ============================================================================

static void TweakLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"[TweakDebug] %@", msg);

    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"TweakDebug.log"];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timeStr, msg];

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        [logLine writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
}


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
// 2. 原生 SDK 视图物理折叠 (解决评论区/信息流漏网卡片)
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
// 3. 第三方 SDK 底层数据拦截 (构造安全 NSError，绝不传 nil)
// ============================================================================

%hook ATNativeAD
- (void)loadADWithPlacementID:(id)placement extra:(id)extra delegate:(id<ATNativeADDelegate>)delegate {
    TweakLog(@"[Hook 触发] ATNativeAD 开始请求广告");
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
    TweakLog(@"[Hook 触发] BUMNativeAdsManager 请求广告");
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
    TweakLog(@"[Hook 触发] GDTNativeExpressAd 请求广告");
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


// ============================================================================
// 4. 酷安冷/热开屏拦截 (修复传 nil 导致的解包闪退)
// ============================================================================

%hook TXAdSplashManager
- (void)getSplashAdsWithAdsDataBlock:(void (^)(id adsData))block {
    TweakLog(@"[Hook 触发] 拦截酷安 TXAd 热启动开屏");
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
    TweakLog(@"[Hook 触发] 拦截 GroMore 开屏加载 (安全 NSError 回调)");
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate splashAd:(id)self didFailWithError:safeError]; // 👈 传递真实 NSError 避免 Swift 强解包崩溃
        });
    }
}
- (void)loadAdDataWithMediaSlotConfigIDs:(id)a0 sign:(long long)a1 {
    TweakLog(@"[Hook 触发] 拦截 GroMore 扩展开屏加载");
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAd:didFailWithError:)]) {
        NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate splashAd:(id)self didFailWithError:safeError];
        });
    }
}
- (void)showSplashViewInRootViewController:(id)a0 {
    TweakLog(@"[Hook 触发] 阻断 GroMore 开屏展示");
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidClose:withType:)]) {
        [self.delegate splashAdDidClose:(id)self withType:0];
    } else if ([self respondsToSelector:@selector(removeSplashView)]) {
        [self removeSplashView];
    }
}
%end


// ============================================================================
// 5. 插件入口
// ============================================================================

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        TweakLog(@"🎉 酷安安全版去广告 Tweak 成功启动！");
    }];
}
