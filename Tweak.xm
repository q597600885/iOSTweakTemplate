#import <Foundation/Foundation.h>

%hook GlobalUserInfo

- (BOOL)ad_free
{
    NSLog(@"[WoAiKaAdFree] ad_free enabled");

    return YES;
}

%end
