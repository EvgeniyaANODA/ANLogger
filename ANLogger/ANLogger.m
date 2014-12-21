//
//  ANLogger.m
//
//  Created by Oksana Kovalchuk on 18/12/14.
//  Copyright (c) 2014 Oksana Kovalchuk. All rights reserved.
//

#import "ANLogger.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"
#import <libkern/OSAtomic.h>
#import "UIColor+ANAdditions.h"

static NSString* const kDateFormatString = @"hh:MM:ss.SSS";
int ddLogLevel = DDLogLevelVerbose;

@interface ANLogger () <DDLogFormatter>

@property (atomic, strong) NSDateFormatter *threadUnsafeDateFormatter;
@property (atomic, assign) int atomicLoggerCount;

@end

@implementation ANLogger

+ (instancetype)shared
{
    static id _sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [self new];
    });
    return _sharedClient;
}

+ (void)initializeLogger
{
    [ANLogger shared];
#ifndef RELEASE
    // Standard lumberjack initialization
    DDFileLogger* fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24 * 200; // 200 days rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    ANLog(@"Log started at directory : %@",[fileLogger.logFileManager createNewLogFile]);
    
    [DDLog addLogger:fileLogger];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    // And we also enable colors
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor an_colorWithHexString:@"ee7049"] backgroundColor:nil forFlag:DDLogFlagError];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor an_colorWithHexString:@"fbe659"] backgroundColor:nil forFlag:DDLogFlagWarning];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor an_colorWithHexString:@"72ed23"] backgroundColor:nil forFlag:DDLogFlagInfo];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor an_colorWithHexString:@"31ccf2"] backgroundColor:nil forFlag:DDLogFlagDebug];
    [DDTTYLogger sharedInstance].logFormatter = [ANLogger shared];
#endif
}

- (NSString *)stringFromDate:(NSDate *)date
{
    int32_t loggerCount = OSAtomicAdd32(0, &_atomicLoggerCount);
    
    if (loggerCount <= 1)
    {
        // Single-threaded mode.
        
        if (self.threadUnsafeDateFormatter == nil)
        {
            self.threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [self.threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [self.threadUnsafeDateFormatter setDateFormat:kDateFormatString];
        }
        
        return [self.threadUnsafeDateFormatter stringFromDate:date];
    }
    else
    {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"CustomFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:kDateFormatString];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    return [NSString stringWithFormat:@"%@ | %@",[self stringFromDate:logMessage.timestamp] ,logMessage.message];
}

- (void)didAddToLogger:(id <DDLogger>)logger
{
    OSAtomicIncrement32(&_atomicLoggerCount);
}
- (void)willRemoveFromLogger:(id <DDLogger>)logger
{
    OSAtomicDecrement32(&_atomicLoggerCount);
}

@end
