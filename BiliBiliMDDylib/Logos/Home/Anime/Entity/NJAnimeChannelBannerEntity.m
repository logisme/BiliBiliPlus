//
//  NJAnimeChannelBannerEntity.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2025/7/10.
//

#import "NJAnimeChannelBannerEntity.h"

@implementation NJAnimeChannelBannerEntity

- (NSString *)cardType {
    return @"BANNER";
}

- (NSDictionary *)handleData:(NSMutableDictionary *)data {
    if ([data[@"module_data"][@"items"] isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray *bannerItems = data[@"module_data"][@"items"];
        NSMutableArray *newBannerItems = [NSMutableArray array];
        for (NSMutableDictionary *itemDic in bannerItems) {
            NSDictionary *bannerData = [self handleBannerData:itemDic];
            if (bannerData) {
                [newBannerItems addObject:bannerData];
            }
        }
        [bannerItems removeAllObjects];
        [bannerItems addObjectsFromArray:newBannerItems];
        // 没有banner数据
        if (bannerItems.count == 0) {
            return nil;
        }
    }
    return data;
}

- (NSDictionary *_Nullable)handleBannerData:(NSMutableDictionary *)bannerDic {
    // 只移除广告位（活动页链接），保留频道页顶部的运营海报
    NSString *url = bannerDic[@"url"];
    if ([url isKindOfClass:[NSString class]] &&
        [url hasPrefix:@"https://www.bilibili.com/blackboard/era/"]) {
        return nil;
    }
    return bannerDic;
}

@end
