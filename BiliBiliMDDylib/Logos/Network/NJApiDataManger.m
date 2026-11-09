//
//  NJApiDataManger.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2025/7/3.
//

#import "NJApiDataManger.h"
#import "NJApiDataItem.h"
#import "NSURL+NJPath.h"
#import "NJApiDataItem.h"
#import "NJRcmdCardDataItem.h"
#import "NJLiveIndexFeedDataItem.h"
#import "NJLiveSecondGetListDataItem.h"
#import "NJAnimeChannelDataItem.h"
#import "NJSearchSquareDataItem.h"
#import "NJTabDataItem.h"
#import "NJUpperRcmdDataItem.h"
#import "NJShareChannelsDataItem.h"
#import "NJMineDataItem.h"
#import "NJStoryDataItem.h"
#import "NJSkinDataItem.h"

@interface NJApiDataManger ()

/// 需要注册的类
@property (nonatomic, strong, readonly) NSArray<Class> *itemClasses;
/// 数据处理项
@property (nonatomic, strong) NSMutableDictionary<NSString *, NJApiDataItem*> *itemDic;


@end

/// 判断 JSON 值是否表示「开启 / 非空」
static BOOL NJJSONValueIsTruthy(id value) {
    if (!value || value == [NSNull null]) {
        return NO;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value boolValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *string = [(NSString *)value stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return string.length > 0 && ![string isEqualToString:@"0"];
    }
    if ([value isKindOfClass:[NSArray class]]) {
        return [(NSArray *)value count] > 0;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)value count] > 0;
    }
    return YES;
}

/// 判断字符串是否指向广告 / 电商推广落地页
static BOOL NJJSONStringIsAdLink(NSString *value) {
    if (![value isKindOfClass:[NSString class]] || value.length == 0) {
        return NO;
    }
    NSString *lower = value.lowercaseString;
    NSArray<NSString *> *markers = @[
        @"mall.bilibili.com", @"bilibili://mall", @"cm.bilibili.com",
        @"taobao.com", @"tmall.com", @"tmall.hk", @"jd.com", @"3.cn",
        @"pinduoduo.com", @"yangkeduo.com", @"klook.com", @"klook.cn",
        @"apple.com/app", @"apps.apple.com"
    ];
    for (NSString *marker in markers) {
        if ([lower containsString:marker]) {
            return YES;
        }
    }
    return NO;
}

/// 判断字典是否是广告卡片 / 广告配置
static BOOL NJJSONDictionaryIsAd(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]] || dict.count == 0) {
        return NO;
    }
    // 广告标识字段：非空即视为广告
    NSArray<NSString *> *flagKeys = @[
        @"is_ad", @"isAd", @"is_ad_loc", @"isAdLoc", @"has_ad_info", @"hasAdInfo",
        @"ad_info", @"adInfo", @"cm_info", @"cmInfo", @"ad_cb", @"adCb",
        @"cm_mark", @"cmMark", @"splash_id", @"splashId", @"nature_ad", @"natureAd",
        @"small_cover_v5_ad", @"smallCoverV5Ad", @"ad_banner", @"adBanner",
        @"ad_banners", @"adBanners", @"creative_content", @"creativeContent"
    ];
    for (NSString *key in flagKeys) {
        if (NJJSONValueIsTruthy(dict[key])) {
            return YES;
        }
    }

    // 卡片类型：所有商业推广卡片
    id cardType = dict[@"card_type"] ?: dict[@"cardType"];
    if ([cardType isKindOfClass:[NSString class]]) {
        NSString *lower = [(NSString *)cardType lowercaseString];
        if ([lower hasPrefix:@"cm_"] ||
            [lower hasPrefix:@"banner"] ||
            [lower hasPrefix:@"topview"] ||
            [lower hasPrefix:@"top_view"] ||
            [lower containsString:@"cm_single"] ||
            [lower containsString:@"cm_v2"] ||
            [lower containsString:@"cm_double"] ||
            [lower isEqualToString:@"small_cover_v5_ad"]) {
            return YES;
        }
    }

    // 跳转类型
    for (NSString *key in @[@"card_goto", @"cardGoto", @"goto"]) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *lower = [(NSString *)value lowercaseString];
            if ([lower isEqualToString:@"ad"] ||
                [lower isEqualToString:@"cm"] ||
                [lower isEqualToString:@"mall"] ||
                [lower isEqualToString:@"operation"]) {
                return YES;
            }
        }
    }

    // 推广标签（创作推广 / 商业推广等）
    NSArray<NSString *> *labelKeys = @[@"title", @"subtitle", @"desc", @"reason",
                                       @"badge", @"rcmd_reason", @"rcmd_reason_style",
                                       @"cover_left_text_1", @"cover_right_text",
                                       @"cover_left_text_2", @"right_desc_1"];
    for (NSString *key in labelKeys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *string = (NSString *)value;
            if ([string containsString:@"创作推广"] ||
                [string containsString:@"商业推广"] ||
                [string containsString:@"品牌推广"] ||
                [string isEqualToString:@"广告"]) {
                return YES;
            }
        }
    }

    // 落地页
    for (NSString *key in @[@"uri", @"jump_url", @"jumpUrl", @"click_url", @"clickUrl", @"url", @"link"]) {
        if (NJJSONStringIsAdLink(dict[key])) {
            return YES;
        }
    }
    return NO;
}

/// 递归清洗 JSON：移除任意层级的广告卡片与广告配置
static id NJJSONSanitizedObject(id object, NSInteger depth) {
    if (!object || depth > 12) {
        return object;
    }
    if ([object isKindOfClass:[NSDictionary class]]) {
        if (NJJSONDictionaryIsAd(object)) {
            return nil;
        }
        NSMutableDictionary *dict = [object mutableCopy];
        NSArray *allKeys = [dict allKeys];
        for (id key in allKeys) {
            NSString *keyName = [key isKindOfClass:[NSString class]] ? (NSString *)key : @"";
            NSString *lowerKey = keyName.lowercaseString;
            // 顶部焦点图 / Banner / 广告信息容器，整块移除
            if ([lowerKey containsString:@"topview"] ||
                [lowerKey containsString:@"top_view"] ||
                [lowerKey isEqualToString:@"banner_item"] ||
                [lowerKey isEqualToString:@"banner_items"] ||
                [lowerKey isEqualToString:@"banneritem"] ||
                [lowerKey isEqualToString:@"banneritems"] ||
                [lowerKey isEqualToString:@"ad_info"] ||
                [lowerKey isEqualToString:@"adinfo"] ||
                [lowerKey isEqualToString:@"cm_info"] ||
                [lowerKey isEqualToString:@"cminfo"]) {
                [dict removeObjectForKey:key];
                continue;
            }
            id filteredValue = NJJSONSanitizedObject(dict[key], depth + 1);
            if (filteredValue) {
                dict[key] = filteredValue;
            } else {
                [dict removeObjectForKey:key];
            }
        }
        return dict;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)object count]];
        for (id value in (NSArray *)object) {
            id filteredValue = NJJSONSanitizedObject(value, depth + 1);
            if (filteredValue) {
                [array addObject:filteredValue];
            }
        }
        return array;
    }
    return object;
}

/// 清空开屏接口的下发列表（开屏位基本只有广告）
static NSData *NJClearSplashListData(NSData *data) {
    if (![data isKindOfClass:[NSData class]]) {
        return data;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingMutableContainers
                                               error:nil];
    if (![json isKindOfClass:[NSMutableDictionary class]]) {
        return data;
    }
    NSMutableDictionary *root = (NSMutableDictionary *)json;
    id dataObject = root[@"data"];
    if ([dataObject isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dataDic = (NSMutableDictionary *)dataObject;
        NSArray<NSString *> *listKeys = @[@"list", @"items", @"splash_list", @"event_list",
                                          @"top_view_list", @"topview_list"];
        for (NSString *key in listKeys) {
            if ([dataDic[key] isKindOfClass:[NSArray class]]) {
                dataDic[key] = @[];
            }
        }
    } else if ([dataObject isKindOfClass:[NSArray class]]) {
        root[@"data"] = @[];
    }
    NSData *filteredData = [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];
    return filteredData ?: data;
}

/// 过滤首页 / 开屏响应中的广告数据
static NSData *NJFilterAdResponseData(NSData *data) {
    if (![data isKindOfClass:[NSData class]]) {
        return data;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingMutableContainers
                                               error:nil];
    if (![json isKindOfClass:[NSDictionary class]]) {
        return data;
    }
    id sanitized = NJJSONSanitizedObject(json, 0);
    if (![sanitized isKindOfClass:[NSDictionary class]]) {
        return data;
    }
    NSData *filteredData = [NSJSONSerialization dataWithJSONObject:sanitized options:0 error:nil];
    return filteredData ?: data;
}

@implementation NJApiDataManger

@synthesize itemClasses = _itemClasses;

#pragma mark - Life Cycle Methods

+ (instancetype)sharedInstance {
    static NJApiDataManger *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[NJApiDataManger alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self doInit];
    }
    return self;
}



#pragma mark - Do Init

- (void)doInit {
    self.itemDic = [NSMutableDictionary dictionary];
    [self registerItems];
}

- (void)registerItems {
    for (Class itemClass in self.itemClasses) {
        NJApiDataItem *item = [[itemClass alloc] init];
        NSString *urlStr = item.url;
        if (urlStr.length == 0) {
            continue;
        }
        self.itemDic[urlStr] = item;
    }
}

#pragma mark - Override Methods

#pragma mark - Public Methods

- (NSData *)handleWithData:(NSData *)data
                  response:(NSURLResponse *)response
                     error:(NSError *)error {
    if (error) {
        return data;
    }
    NSString *path = response.URL.path ?: @"";
    // 首页推荐 / 开屏 / 顶部焦点图接口：统一在 JSON 层清洗广告数据。
    // 9.18 起首页存在 feed/index、feed/index/converge、feed/index/interest、
    // feed/index/tab、feed/index/vertical/tab、feed/nf 等多条下发通道，
    // 不能只匹配其中一个 URL。
    if ([path containsString:@"/splash/"]) {
        data = NJClearSplashListData(data);
        data = NJFilterAdResponseData(data);
    } else {
        NSArray<NSString *> *adPaths = @[
            @"/feed/index", @"/feed/nf", @"/feed/coldstart",
            @"/x/v2/banner", @"/pegasus/"
        ];
        for (NSString *adPath in adPaths) {
            if ([path containsString:adPath]) {
                data = NJFilterAdResponseData(data);
                break;
            }
        }
    }
    NSString *urlStr = response.URL.nj_fullPath;
    if (urlStr.length == 0) {
        return data;
    }
    NJApiDataItem *item = self.itemDic[urlStr];
    if (!item) {
        // 9.18 起部分接口会走备用域名（如 app.biliapi.net），
        // 完整 URL 不再匹配，这里按 path 兜底匹配
        NSString *requestPath = response.URL.path;
        if (requestPath.length > 0) {
            for (NSString *key in self.itemDic) {
                if ([[NSURL URLWithString:key].path isEqualToString:requestPath]) {
                    item = self.itemDic[key];
                    break;
                }
            }
        }
    }
    if (!item) {
        return data;
    }
    NSData *dataHandled = [item handleWithData:data
                                      response:response];
    return dataHandled;
}

#pragma mark - Private Methods

#pragma mark - Property Methods

- (NSArray<Class> *)itemClasses {
    if (!_itemClasses) {
        _itemClasses = @[[NJRcmdCardDataItem class],            // 首页-推荐
                         [NJLiveIndexFeedDataItem class],       // 首页-直播-索引
                         [NJLiveSecondGetListDataItem class],   // 首页-直播-具体板块数据
                         [NJAnimeChannelDataItem class],        // 首页-动画
                         [NJSearchSquareDataItem class],        // 搜索广场
                         [NJTabDataItem class],                 // 首页的版块
                         [NJUpperRcmdDataItem class],           // 详情-你可能感兴趣的up主
                         [NJShareChannelsDataItem class],       // 详情页-分享频道
                         [NJMineDataItem class],                // 我的
                         [NJStoryDataItem class],               // 竖屏模式
                         [NJSkinDataItem class],                // 皮肤
        ];
    }
    return _itemClasses;
}


@end
