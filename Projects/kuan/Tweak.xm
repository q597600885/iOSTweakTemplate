#import <UIKit/UIKit.h>
#import "../../Includes/Debug.h" // 👈 引用根目录下的公共头文件

#define LOG_TAG @"Coolapk" // 👈 当前插件日志标识


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
    TweakLog(LOG_TAG, @"[Action] 成功折叠 GDTUnifiedNativeAdView 广告卡片");
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
    TweakLog(LOG_TAG, @"[Hook 触发] ATNativeAD 开始请求广告");
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

%hook GDTNativeExpressAd
- (void)loadAd {
    TweakLog(LOG_TAG, @"[Hook 触发] GDTNativeExpressAd 请求广告");
    if ([self respondsToSelector:@selector(delegate)]) {
        id<GDTNativeExpressAdDelegete> delegate = [self valueForKey:@"delegate"];
        if (delegate && [delegate respondsToSelector:@selector(nativeExpressAdFailToLoad:error:)]) {
            NSError *safeError = [NSError errorWithDomain:@"CoolapkAdBlock" code:404 userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate nativeExpressAdFailToLoa
