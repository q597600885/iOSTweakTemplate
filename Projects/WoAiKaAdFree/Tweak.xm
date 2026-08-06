#import <Foundation/Foundation.h>

%hook GlobalUserInfo

- (BOOL)ad_free {
    NSLog(@"[WoAiKaAdFree] 我爱卡去广告已成功注入生效！");
    // 强制返回 YES (1)，直接让 App 认为你是高级免广告用户
    return YES;
}

%end
