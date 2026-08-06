#import <Foundation/Foundation.h>

%hook GlobalUserInfo

- (BOOL)ad_free {
    // 强制返回 YES（真），直接解锁免广告
    return YES;
}

%end
