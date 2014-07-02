
//  Created by Madhavi Solanki on 02/07/14.
//  Copyright (c) 2014 Madhavi. All rights reserved.


#import "MSServiceClient.h"


@implementation MSServiceClient
@synthesize reachability;

#pragma mark -
#pragma mark Constructors

- (id)init
{
    if ((self = [super init]))
    {
        
    }
    _queueMode = RequestQueueModeFirstInFirstOut;
    _operations = [[NSMutableArray alloc] init];
    _maxConcurrentRequestCount = 2;
    _allowDuplicateRequests = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNetworkChange:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    
    [self setReachability:[Reachability reachabilityForInternetConnection]];
    [self.reachability startNotifier];
    return self;
}

-(void)handleNetworkChange:(NSNotification *)sender {
    
    NetworkStatus netStatus = [self.reachability currentReachabilityStatus];
    
    if (netStatus == NotReachable)
    {
        NSLog(@"NotReachable");
        [self setSuspended:YES];
    }
    
    if (netStatus == ReachableViaWiFi)
    {
        NSLog(@"ReachableViaWiFi");
        [self setSuspended:NO];

    }
    
    if (netStatus == ReachableViaWWAN)
    {
        NSLog(@"ReachableViaWWAN");
        [self setSuspended:NO];

    }
}


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

{
    
    NSString *stringURL = [NSString stringWithFormat:@"%@%@",uri,[self getString:parameters]]; //Add encoding if required.
    
    NSURL *datasourceURL = [NSURL URLWithString:stringURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:datasourceURL];
    
    for(NSString *key in headers)
    {
        [request addValue:[headers objectForKey:key] forHTTPHeaderField:key];
    }
    [request setHTTPBody:body];
    [request setHTTPMethod:[self getMethodName:method]];
    MSServiceOperation *operation = [MSServiceOperation operationWithRequest:request];
    
    [self addRequest:request  getOperation:operation completionHandler:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        
        completion(response,data,error);
    }];
    
    
    return operation;
    
    
}

-(NSString *)getMethodName:(MSServiceMethod)method
{
    NSString *methodName;
    
    switch (method) {
        case MSServiceMethodDelete:
        {
            methodName = @"DELETE";
        }
        break;case MSServiceMethodGet:
        {
            methodName = @"GET";

        }
        break;case MSServiceMethodPost:
        {
            methodName = @"POST";

        }
        break;case MSServiceMethodPut:
        {
            methodName = @"PUT";

        }
        break;
        default:
            break;
    }
    
    return methodName;
    
}
-(NSString*)getString:(NSDictionary *)dict
{
    __autoreleasing NSMutableString *mutableString = [[NSMutableString alloc] init];
    
    for (NSString *string in [dict allKeys])
    {
        NSString *result = [NSString stringWithFormat:@"%@=%@&",string,[dict objectForKey:string]];
        result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [mutableString appendString:result];
    }
    return mutableString;
}


- (NSString *)urlEncodeWithString: (NSString*)string
{
    CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
                                                                    NULL,
                                                                    (CFStringRef)string,
                                                                    NULL,
                                                                    (CFStringRef)@" ",
                                                                    kCFStringEncodingUTF8 );
    return (NSString *)CFBridgingRelease(urlString);
}


- (NSUInteger)requestCount
{
    return [_operations count];
}

- (NSArray *)requests
{
    return [_operations valueForKeyPath:@"request"];
}

- (void)dequeueOperations
{

     if (!_suspended == YES)
    {
        NSInteger count = MIN([_operations count], _maxConcurrentRequestCount ?: INT_MAX);
        for (int i = 0; i < count; i++)
        {
            [(MSServiceOperation *)_operations[i] start];
        }
    }
}

#pragma mark Public methods

- (void)setSuspended:(BOOL)suspended
{
    _suspended = suspended;
    [self dequeueOperations];
}

- (void)addOperation:(MSServiceOperation *)operation
{
    if (!_allowDuplicateRequests)
    {
        for (int i = [_operations count] - 1; i >= 0 ; i--)
        {
            MSServiceOperation *_operation = _operations[i];
            if ([_operation.request isEqual:operation.request])
            {
                [_operation cancel];
            }
        }
    }
    
    NSInteger index = 0;
    if (_queueMode == RequestQueueModeFirstInFirstOut)
    {
        index = [_operations count];
    }
    else
    {
        for (index = 0; index < [_operations count]; index++)
        {
            if (![_operations[index] isExecuting])
            {
                break;
            }
        }
    }
    if (index < [_operations count])
    {
        [_operations insertObject:operation atIndex:index];
    }
    else
    {
        [_operations addObject:operation];
    }
    
    [operation addObserver:self forKeyPath:@"isExecuting" options:NSKeyValueChangeSetting context:NULL];
    [self dequeueOperations];
}

- (void)addRequest:(NSMutableURLRequest *)request getOperation:(MSServiceOperation *)operation completionHandler:(MSCompletionHandler)completionHandler
{
    operation.completionHandler = completionHandler;
    [self addOperation:operation];
    
}

- (void)cancelRequest:(NSURLRequest *)request
{
    for (int i = [_operations count] - 1; i >= 0 ; i--)
    {
        MSServiceOperation *operation = _operations[i];
        if (operation.request == request)
        {
            [operation cancel];
        }
    }
}

- (void)cancelAllRequests
{
    NSArray *operationsCopy = _operations;
    _operations = [NSMutableArray array];
    for (MSServiceOperation *operation in operationsCopy)
    {
        [operation cancel];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    MSServiceOperation *operation = object;
    if (!operation.isExecuting)
    {
        [operation removeObserver:self forKeyPath:@"isExecuting"];
        [_operations removeObject:operation];
        [self dequeueOperations];
    }
}






@end
