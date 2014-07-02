
//  Created by Madhavi Solanki on 02/07/14.
//  Copyright (c) 2014 Madhavi. All rights reserved.

#import <Foundation/Foundation.h>
#import "MSServiceClientDefines.h"

@interface MSServiceOperation : NSOperation
{
    NSFileHandle * downloadFileHandler;
    long long bytesTransferred;
    BOOL writeToFile;
    UIBackgroundTaskIdentifier bgTask;

    NSString * destinationPath;
}

@property (nonatomic , strong) NSString * downloadURL;
@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, copy) MSCompletionHandler completionHandler;
@property (nonatomic, copy) MSProgressHandler uploadProgressHandler;
@property (nonatomic, copy) MSProgressHandler downloadProgressHandler;
@property (nonatomic, copy) MSAuthenticationChallengeHandler authenticationChallengeHandler;
@property (nonatomic, copy) NSSet *autoRetryErrorCodes;
@property (nonatomic) NSTimeInterval autoRetryDelay;
@property (nonatomic) BOOL autoRetry;
@property (nonatomic, readonly) NSDate * startDate;
@property (copy) void (^backgroundSessionCompletionHandler)();


+ (MSServiceOperation *)operationWithRequest:(NSMutableURLRequest *)request andDestinationPath:(NSString *)destinationPath;
- (MSServiceOperation *)initWithRequest:(NSMutableURLRequest *)request andDestinationPath:(NSString *)destinationPath;

+ (MSServiceOperation *)operationWithRequest:(NSMutableURLRequest *)request;
- (MSServiceOperation *)initWithRequest:(NSMutableURLRequest *)request;

@end