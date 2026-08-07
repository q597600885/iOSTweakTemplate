#import <UIKit/UIKit.h>

// 核心原则：保留 %orig 让广告内部逻辑正常走完（避免 App 线程卡死或报错），但在视图或展示环节将其拦截/隐藏。

%hook KsSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    NSLog(@"[AdBlocker] KsSplashAdLoader loadWithViewController called, let it load safely.");
    %orig; // 走正常加载流程，防止主 App 发生广告超时等待
}

- (void)showWithViewController:(id)a0 AdView:(UIView *)adView AdInteractionListener:(id)a2 {
    NSLog(@"[AdBlocker] Intercepted KsSplashAdLoader show, hiding ad view.");
    // 如果有广告视图，直接将其从父视图移除并隐藏，不让它显示出来
    if ([adView isKindOfClass:[UIView class]]) {
        [adView removeFromSuperview];
        adView.hidden = YES;
    }
    // 注意：根据实际需要，这里也可以选择不调用 %orig，或者让其静默展示一个空的隐藏 View
}

%end


%hook GdtSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    %orig;
}

- (void)showWithViewController:(id)a0 AdView:(UIView *)adView AdInteractionListener:(id)a2 {
    NSLog(@"[AdBlocker] Intercepted GdtSplashAdLoader show, hiding ad view.");
    if ([adView isKindOfClass:[UIView class]]) {
        [adView removeFromSuperview];
        adView.hidden = YES;
    }
}

%end


%hook CsjSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    %orig;
}

- (void)showWithViewController:(id)a0 AdView:(UIView *)adView AdInteractionListener:(id)a2 {
    NSLog(@"[AdBlocker] Intercepted CsjSplashAdLoader show, hiding ad view.");
    if ([adView isKindOfClass:[UIView class]]) {
        [adView removeFromSuperview];
        adView.hidden = YES;
    }
}

%end


%hook BDSplashAdLoader

- (void)loadWithViewController:(id)a0 AdSlot:(id)a1 AdLoadListener:(id)a2 {
    %orig;
}

- (void)showWithViewController:(id)a0 AdView:(UIView *)adView AdInteractionListener:(id)a2 {
    NSLog(@"[AdBlocker] Intercepted BDSplashAdLoader (Baidu) show, hiding ad view.");
    if ([adView isKindOfClass:[UIView class]]) {
        [adView removeFromSuperview];
        adView.hidden = YES;
    }
}

%end


%ctor {
    NSLog(@"[AdBlocker] Safe Ad-blocking tweak loaded successfully!");
}