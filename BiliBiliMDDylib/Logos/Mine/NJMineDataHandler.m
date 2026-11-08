//
//  NJMineDataHandler.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/1/5.
//

#import "NJMineDataHandler.h"
#import "NJSettingCache.h"

/// 大积分中心入口 id（自定义，不与官方 id 冲突）
#define NJ_BIG_POINT_CENTER_ITEM_ID 9999

@interface NJMineDataHandler ()

/// 业务id白名单（这些是核心服务，始终显示）
@property (nonatomic, strong) NSSet<NSNumber *> *bizIdWhiteList;


@end

@implementation NJMineDataHandler

#pragma mark - Life Cycle Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        [self doInit];
    }
    return self;
}



#pragma mark - Do Init

- (void)doInit {
    self.bizIdWhiteList = [[NSSet alloc] initWithObjects:@(396),     // 离线缓存
                                                         @(397),     // 历史记录
                                                         @(3072),    // 我的收藏
                                                         @(2830),    // 稍后再看
                                                         @(407),     // 联系客服
                                                         @(410),     // 设置
                                                         nil
    ];
}

#pragma mark - Override Methods

#pragma mark - Public Methods

/// 处理数据
/// - Parameter tabData: 要处理的数据
/// @return 处理后的数据
- (NSArray *)handleData:(NSArray *)mineData {
    // 收集接口返回的全部可配置服务，供设置页多选使用
    [self collectServicesFromData:mineData];

    NSSet<NSString *> *selectedIds = [[NJSettingCache sharedInstance] selectedMineServiceIds];
    NSMutableArray *newMineData = [NSMutableArray array];
    for (NSDictionary *bizData in mineData) {
        NSDictionary *dataHandled = [self handleSectionData:bizData selectedIds:selectedIds];
        if (dataHandled) {
            [newMineData addObject:dataHandled];
        }
    }

    // 大积分中心入口：用户勾选后才显示
    if ([selectedIds containsObject:[@(NJ_BIG_POINT_CENTER_ITEM_ID) stringValue]]) {
        [newMineData addObject:[self bigPointCenterSection]];
    }
    return [newMineData copy];
}

#pragma mark - Private Methods

/// 收集接口中的服务项（id + title），持久化到设置缓存
- (void)collectServicesFromData:(NSArray *)mineData {
    NSMutableArray<NSDictionary *> *services = [NSMutableArray array];
    NSMutableSet<NSString *> *seenIds = [NSMutableSet set];
    for (NSDictionary *sectionData in mineData) {
        id items = sectionData[@"items"];
        if (![items isKindOfClass:[NSArray class]]) {
            continue;
        }
        for (NSDictionary *item in items) {
            id itemId = item[@"id"];
            NSString *title = item[@"title"];
            if (![itemId isKindOfClass:[NSNumber class]] || title.length == 0) {
                continue;
            }
            NSString *itemIdStr = [itemId stringValue];
            // 核心服务无需出现在选择列表里
            if ([self.bizIdWhiteList containsObject:itemId] ||
                [seenIds containsObject:itemIdStr]) {
                continue;
            }
            [seenIds addObject:itemIdStr];
            [services addObject:@{@"id": itemIdStr, @"title": title}];
        }
    }
    // 追加大积分中心
    [services addObject:@{@"id": [@(NJ_BIG_POINT_CENTER_ITEM_ID) stringValue],
                          @"title": @"大积分中心"}];
    [[NJSettingCache sharedInstance] saveMineServices:[services copy]];
}

/// 处理分组数据
/// @param sectionData 分组数据
/// @return 处理后的分组数据
- (NSDictionary *)handleSectionData:(NSDictionary *)sectionData selectedIds:(NSSet<NSString *> *)selectedIds {
    if (!sectionData[@"items"] ||
        ![sectionData[@"items"] isKindOfClass:[NSArray class]]) {
        return sectionData;
    }
    NSArray *items = sectionData[@"items"];
    NSMutableArray *newItems = [NSMutableArray array];
    for (NSDictionary *item in items) {
        NSDictionary *itemHandled = [self handleItemData:item selectedIds:selectedIds];
        if (itemHandled) {
            [newItems addObject:itemHandled];
        }
    }
    if (newItems.count == 0) {
        return nil;
    }
    NSMutableDictionary *newSectionData = [NSMutableDictionary dictionaryWithDictionary:sectionData];
    newSectionData[@"items"] = [newItems copy];
    return [newSectionData copy];
}


/// 处理项目数据
/// @param itemData 项目数据
/// @return 处理后的项目数据
- (NSDictionary *)handleItemData:(NSDictionary *)itemData selectedIds:(NSSet<NSString *> *)selectedIds {
    if (!itemData[@"id"] ||
        ![itemData[@"id"] isKindOfClass:[NSNumber class]]) {
        return itemData;
    }
    NSNumber *bizId = itemData[@"id"];
    // 核心服务始终显示
    if ([self.bizIdWhiteList containsObject:bizId]) {
        return itemData;
    }
    // 其余服务：默认全部隐藏，只有用户勾选后才显示
    if ([selectedIds containsObject:[bizId stringValue]]) {
        return itemData;
    }
    return nil;
}

/// 大积分中心分组
- (NSDictionary *)bigPointCenterSection {
    NSDictionary *item = @{
        @"id": @(NJ_BIG_POINT_CENTER_ITEM_ID),
        @"title": @"大积分中心",
        @"uri": @"https://big.bilibili.com/mobile/bigPoint?closable=1&msource=0",
        @"icon": @"https://i0.hdslb.com/bfs/archive/e932404f2ee62e075a772920019e9fbdb4b5656a.png",
        @"common_op_item": @{},
        @"corner_pixel": @(0),
        @"biz_type": @(0),
    };
    return @{
        @"title": @"更多服务",
        @"items": @[item],
        @"style": @(2),
        @"button": @{},
    };
}

#pragma mark - Property Methods



@end
