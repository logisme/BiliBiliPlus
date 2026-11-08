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

/// 把大积分数额显示到「我的」页面的硬币 Label 旁边
+ (void)applyBigPointToCoinLabel:(UILabel *)coinLabel;

@end

NS_ASSUME_NONNULL_END
