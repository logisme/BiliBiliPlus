//
//  NJTabDataTabHandler.m
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/1/4.
//

#import "NJTabDataTabHandler.h"

@implementation NJTabDataTabHandler

#pragma mark - Life Cycle Methods


#pragma mark - Override Methods

/// 业务类型
- (NSString *)bizType {
    return @"tab";
}

/// 处理数据
/// - Parameter data: 要处理的数据
/// @return 处理后的数据
- (NSObject *)handleData:(NSObject *)data {
    if (![data isKindOfClass:[NSArray class]]) {
        return data;
    }
    NSArray *items = (NSArray *)data;
    NSMutableArray *newItems = [NSMutableArray array];
    for (NSMutableDictionary *itemDic in items) {
        NSDictionary *itemData = [self handleItemData:itemDic];
        if (itemData) {
            [newItems addObject:itemData];
        }
    }
    return [newItems copy];
}

#pragma mark - Private Methods

/// 处理数据
/// - Parameter tabData: 版块数据
- (NSDictionary *)handleItemData:(NSMutableDictionary *)tabData {
    // 保留全部版块，包括“新征程”等活动版块，避免顶部快捷栏丢失入口
    return tabData;
}

@end
