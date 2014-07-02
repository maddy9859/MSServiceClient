
//  Created by Madhavi Solanki on 02/07/14.
//  Copyright (c) 2014 Madhavi. All rights reserved.


//MSServiceClient upload and download data from given URL.
//It handles data upload/download when the internet connection is not available.
//Data can be upload/download even when application is running in background.

#import <Foundation/Foundation.h>
#import "MSServiceOperation.h"
#import "MSServiceClientDefines.h"
#import "Reachability.h"

typedef enum
{
    RequestQueueModeFirstInFirstOut = 0,
    RequestQueueModeLastInFirstOut = 1
}
RequestQueueMode;

@interface MSServiceClient : NSObject

#pragma mark -
#pragma mark Properties

@property (nonatomic, strong) NSOperationQueue *requestQueue;

@property (nonatomic, assign) NSTimeInterval requestTimeout;
@property(nonatomic,strong)Reachability *reachability;

@property (nonatomic,strong) NSMutableArray *operations;
@property (nonatomic) NSUInteger maxConcurrentRequestCount;
@property (nonatomic, getter = isSuspended) BOOL suspended;
@property (nonatomic, readonly) NSUInteger requestCount;
@property (nonatomic, copy, readonly) NSArray *requests;
@property (nonatomic) RequestQueueMode queueMode;
@property (nonatomic) BOOL allowDuplicateRequests;



#pragma mark -
#pragma mark Constructors

- (id)init;

#pragma mark -
#pragma mark Instance Methods

- (MSServiceOperation *)beginRequestWithURL: (NSString *)uri
                                   method: (MSServiceMethod)method
                                  headers: (NSDictionary *)headers
                                    field:(MSServiceClientFieldCode)field
                               parameters: (NSDictionary *)parameters
                                     body: (NSData *)body
                                   format: (MSServiceFormat)format
                                transform: (id (^)(NSHTTPURLResponse *response, id data))transform
                               completion: (void (^)(NSHTTPURLResponse *response, NSData *data, NSError *error))completion
                                  context: (id)context;
- (void)addOperation:(MSServiceOperation *)operation;
- (void)addRequest:(NSMutableURLRequest *)request getOperation:(MSServiceOperation *)operation completionHandler:(MSCompletionHandler)completionHandler;
- (void)cancelRequest:(NSMutableURLRequest *)request;
- (void)cancelAllRequests;


@end
