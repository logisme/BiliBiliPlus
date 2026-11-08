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

/// 过滤开屏 / 首页顶部焦点图（TopView）广告：清空下发列表，避免广告混入信息流
static NSData *NJFilterSplashResponseData(NSData *data) {
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
        // 顶部焦点图（TopView）字段
        for (NSString *key in [dataDic allKeys]) {
            NSString *lowerKey = [key lowercaseString];
            if ([lowerKey containsString:@"topview"] ||
                [lowerKey containsString:@"top_view"] ||
                [lowerKey isEqualToString:@"banner_item"]) {
                [dataDic removeObjectForKey:key];
            }
        }
    } else if ([dataObject isKindOfClass:[NSArray class]]) {
        root[@"data"] = @[];
    }
    NSData *filteredData = [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];
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
    NSString *path = response.URL.path;
    if (path.length > 0 &&
        ([path containsString:@"/splash/list"] ||
         [path containsString:@"/splash/brand/list"])) {
        data = NJFilterSplashResponseData(data);
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
