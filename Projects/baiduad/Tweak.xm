#import <UIKit/UIKit.h>

// ============================================================================
// 前置接口声明：告知编译器属性与方法，解决 Forward Declaration 编译报错
// ============================================================================

@interface GdtSplashAdLoader : NSObject
@property (nonatomic, retain) id splashAd;
- (void)splashAdFailToPresent:(id)a0 withError:(id)a1;
@end

@interface CsjSplashAdLoader : NSObject
@property (nonatomic, retain) id splashAd;
- (void)splashAdLoadFail:(id)a0 error:(id)a1;
@end

@interface BDSplashAdLoader : NSObject
@property (nonatomic, retain) id splash;
- (void)splashAdLoadFailCode:(id)a0 message:(id)a1 splashAd:(id)a2;
@end


// ============================================================================
// 1. ABUSplashAdLoader (GroMore 聚合调度层)
// ============================================================================
%hook ABUSplashAdLoader

- (BOOL)isValidAdapter:(id)a0 mediaSlotConfig:(id)a1 {
    return NO;
}

- (void)loadMediaAdWithAdapter:(id)a0 mediaSlotConfig:(id)a1 params:(id)a2 {
    // 阻断加载
}

%end


// ============================================================================
// 2. KsSplashAdLoader (快手开屏广告 Loader)
// ============================================================================
%hook KsSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    if (a2 && [a2 respondsToSelector:@selector(onAdLoadFailed:)]) {
        NSError *error = [NSError errorWithDomain:@"com.adblock.ks" code:-1001 userInfo:nil];
        [(id)a2 performSelector:@selector(onAdLoadFailed:) withObject:error];
    } else if (a2 && [a2 respondsToSelector:@selector(splashAdDidLoadFail:error:)]) {
        NSError *error = [NSError errorWithDomain:@"com.adblock.ks" code:-1001 userInfo:nil];
        [(id)a2 performSelector:@selector(splashAdDidLoadFail:error:) withObject:self withObject:error];
    }
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {}
- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {}

%end


// ============================================================================
// 3. GdtSplashAdLoader (腾讯/广点通开屏广告 Loader)
// ============================================================================
%hook GdtSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    NSError *error = [NSError errorWithDomain:@"com.adblock.gdt" code:-1001 userInfo:nil];
    [self splashAdFailToPresent:self.splashAd withError:error];
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {}
- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {}
- (void)splashAdDidLoad:(id)a0 {}

%end


// ============================================================================
// 4. CsjSplashAdLoader (字节/穿山甲开屏广告 Loader)
// ============================================================================
%hook CsjSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    NSError *error = [NSError errorWithDomain:@"com.adblock.csj" code:-1001 userInfo:nil];
    [self splashAdLoadFail:self.splashAd error:error];
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {}
- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {}
- (void)splashAdLoadSuccess:(id)a0 {}

%end


// ============================================================================
// 5. BDSplashAdLoader (百度开屏广告 Loader)
// ============================================================================
%hook BDSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    [self splashAdLoadFailCode:@"-1001" message:@"Ad Blocked" splashAd:self.splash];
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {}
- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {}
- (void)splashAdLoadSuccess:(id)a0 {}

%end


// ============================================================================
// 6. CSJSplashAdLoader (底层/混淆开屏请求器 - 修复 Block 强转)
// ============================================================================
%hook CSJSplashAdLoader

- (void)In_LogoSdk:(id)a0 slot:(id)a1 progress:(id)a2 success:(id)a3 failure:(id)a4 {
    if (a4) {
        void (^failureBlock)(NSError *) = (void (^)(NSError *))a4;
        NSError *error = [NSError errorWithDomain:@"com.adblock.csj.core" code:-1001 userInfo:nil];
        failureBlock(error);
    }
}

- (void)Res_AsLazy:(id)a0 slot:(id)a1 loadState:(id)a2 success:(id)a3 failure:(id)a4 {
    if (a4) {
        void (^failureBlock)(NSError *) = (void (^)(NSError *))a4;
        NSError *error = [NSError errorWithDomain:@"com.adblock.csj.core" code:-1001 userInfo:nil];
        failureBlock(error);
    }
}

%end
