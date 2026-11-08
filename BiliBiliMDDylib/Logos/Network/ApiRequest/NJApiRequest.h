//
//  NJApiRequest.h
//  BiliBiliTweak
//
//  Created by touchWorld on 2026/3/2.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NJApiRequest : NSObject

/// 执行启动任务
+ (void)runLaunchTasks;

/// 加载大积分信息（大积分数额、今日是否已签到）
+ (void)loadBigPointInfoWithCompletionHandler:(void (^ _Nullable)(NSInteger point, BOOL isSigned, NSInteger signCount))completionHandler
                                 errorHandler:(void (^ _Nullable)(NSError *error))errorHandler;

/// 会员中心大积分签到
+ (void)signBigPointWithCompletionHandler:(void (^ _Nullable)(BOOL success, NSString *message))completionHandler;

/// 把大积分数额作为独立 Label 显示在「我的」页面的硬币旁边
+ (void)applyBigPointToCoinLabel:(UILabel *)coinLabel;

/// 在「我的」页面重新排列硬币与大积分 Label（B币、硬币、大积分保持平级）
+ (void)layoutBigPointLabelInArea:(UIView *)area;

@end

NS_ASSUME_NONNULL_END
