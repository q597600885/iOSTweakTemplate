#import <UIKit/UIKit.h>

// ----------------------------------------------------------------------------
// 1. ABUSplashAdLoader (GroMore 聚合调度层)
// ----------------------------------------------------------------------------
%hook ABUSplashAdLoader

// 声明所有适配器无效
- (BOOL)isValidAdapter:(id)a0 mediaSlotConfig:(id)a1 {
    return NO;
}

// 阻止发起媒体广告加载
- (void)loadMediaAdWithAdapter:(id)a0 mediaSlotConfig:(id)a1 params:(id)a2 {
    // 拦截不执行原方法
}

%end


// ----------------------------------------------------------------------------
// 2. KsSplashAdLoader (快手开屏广告 Loader)
// ----------------------------------------------------------------------------
%hook KsSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    // 如果存在 Listener 且响应失败回调，主动发送失败通知
    if (a2 && [a2 respondsToSelector:@selector(onAdLoadFailed:)]) {
        NSError *error = [NSError errorWithDomain:@"com.adblock.ks" code:-1001 userInfo:@{NSLocalizedDescriptionKey: @"Ad Blocked"}];
        [(id)a2 performSelector:@selector(onAdLoadFailed:) withObject:error];
    } else if (a2 && [a2 respondsToSelector:@selector(splashAdDidLoadFail:error:)]) {
        NSError *error = [NSError errorWithDomain:@"com.adblock.ks" code:-1001 userInfo:@{NSLocalizedDescriptionKey: @"Ad Blocked"}];
        [(id)a2 performSelector:@selector(splashAdDidLoadFail:error:) withObject:self withObject:error];
    }
    // 不执行原 %orig;
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {
    // 拦截展示
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {
    // 拦截展示
}

%end


// ----------------------------------------------------------------------------
// 3. GdtSplashAdLoader (腾讯/广点通开屏广告 Loader)
// ----------------------------------------------------------------------------
%hook GdtSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    // 主动回调失败
    NSError *error = [NSError errorWithDomain:@"com.adblock.gdt" code:-1001 userInfo:nil];
    [self splashAdFailToPresent:self.splashAd withError:error];
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {
    // 拦截展示
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {
    // 拦截展示
}

- (void)splashAdDidLoad:(id)a0 {
    // 拦截成功回调
}

%end


// ----------------------------------------------------------------------------
// 4. CsjSplashAdLoader (字节/穿山甲开屏广告 Loader)
// ----------------------------------------------------------------------------
%hook CsjSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    NSError *error = [NSError errorWithDomain:@"com.adblock.csj" code:-1001 userInfo:nil];
    [self splashAdLoadFail:self.splashAd error:error];
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {
    // 拦截展示
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {
    // 拦截展示
}

- (void)splashAdLoadSuccess:(id)a0 {
    // 拦截成功回调
}

%end


// ----------------------------------------------------------------------------
// 5. BDSplashAdLoader (百度开屏广告 Loader)
// ----------------------------------------------------------------------------
%hook BDSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    [self splashAdLoadFailCode:@"-1001" message:@"Ad Blocked" splashAd:self.splash];
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 AdInteractionListener:(id)a2 {
    // 拦截展示
}

- (void)showWithViewController:(id)a0 AdView:(id)a1 Extra:(id)a2 AdInteractionListener:(id)a3 {
    // 拦截展示
}

- (void)splashAdLoadSuccess:(id)a0 {
    // 拦截成功回调
}

%end


// ----------------------------------------------------------------------------
// 6. CSJSplashAdLoader (底层/混淆开屏请求器)
// ----------------------------------------------------------------------------
%hook CSJSplashAdLoader

- (void)In_LogoSdk:(id)a0 slot:(id)a1 progress:(id /* block */)a2 success:(id /* block */)a3 failure:(id /* block */)a4 {
    if (a4) {
        NSError *error = [NSError errorWithDomain:@"com.adblock.csj.core" code:-1001 userInfo:nil];
        a4(error);
    }
}

- (void)Res_AsLazy:(id)a0 slot:(id)a1 loadState:(id)a2 success:(id /* block */)a3 failure:(id /* block */)a4 {
    if (a4) {
        NSError *error = [NSError errorWithDomain:@"com.adblock.csj.core" code:-1001 userInfo:nil];
        a4(error);
    }
}

%end
