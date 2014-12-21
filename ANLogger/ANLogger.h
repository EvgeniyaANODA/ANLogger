//
//  ANLogger.h
//
//  Created by Oksana Kovalchuk on 18/12/14.
//  Copyright (c) 2014 Oksana Kovalchuk. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

extern int ddLogLevel;

#ifdef DEBUG
#define NSLog(args...) ANLog(args);
#endif

#define ANLogError(error) if (error != nil) DDLogError(@"%@",error);

#define ANLog(frmt, ...) \
LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define ANLogWarning(frmt, ...) \
LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define ANLogHTTP(frmt, ...) \
LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define ANLogDB(frmt, ...) \
LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

@interface ANLogger : NSObject

+ (void)initializeLogger;

@end
