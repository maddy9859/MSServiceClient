
//  Created by Madhavi Solanki on 02/07/14.
//  Copyright (c) 2014 Madhavi. All rights reserved.

#import "MSServiceOperation.h"


@interface MSServiceOperation () <NSURLSessionDelegate, NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate,NSURLConnectionDelegate,NSURLConnectionDataDelegate>


@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLResponse *responseReceived;
@property (nonatomic, strong) NSMutableData *accumulatedData;
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, getter = isCancelled) BOOL cancelled;
@property (nonatomic, getter = isFailed) BOOL failed;
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) NSURLSessionUploadTask *uploadTask;

@property (nonatomic) NSURLSession *session;
@end



@implementation MSServiceOperation
@synthesize backgroundSessionCompletionHandler;
+ (MSServiceOperation *)operationWithRequest:(NSMutableURLRequest *)request andDestinationPath:(NSString *)destinationPath
{
    return [[self alloc] initWithRequest:request andDestinationPath:destinationPath];
}

+(MSServiceOperation *)operationWithRequest:(NSMutableURLRequest *)request
{
    //    NSLog(@"Request Data : %@",request.HTTPBody);
    return [[self alloc] initWithRequest:request];
}

- (MSServiceOperation *)initWithRequest:(NSMutableURLRequest *)request andDestinationPath:(NSString *)_destinationPath
{
    if ((self = [self initWithRequest:request]))
    {
        writeToFile = YES;
        destinationPath = _destinationPath;
        [self refreshDownloadData];
    }
    return self;
}

-(void)refreshDownloadData
{
    if([[NSFileManager defaultManager]fileExistsAtPath:destinationPath])
        [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
    
    [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
    downloadFileHandler = [NSFileHandle fileHandleForUpdatingAtPath:destinationPath];
    bytesTransferred = 0;
}

-(MSServiceOperation *)initWithRequest:(NSMutableURLRequest *)request
{
    if ((self = [self init]))
    {
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            _downloadURL = request.URL.absoluteString;
            writeToFile = NO;
            _request = request;
            
            //        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
            //        self.session = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: nil];
            [self setupBackgrounding];
            _autoRetryDelay = 5.0;
            
            self.session = [self backgroundSession];
            
            if ([[request HTTPMethod] isEqualToString:@"POST"] ) {
                
                self.downloadTask = [self.session downloadTaskWithRequest:_request];
            }
            else
            {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"yourfilename.dat"];
                NSURL *uradadl = [[NSURL alloc]initFileURLWithPath:dataPath];
                self.uploadTask = [self.session uploadTaskWithRequest:_request fromFile:uradadl];
                
            }
            if (self.uploadTask) {
//                [self.uploadTask resume];
            }
            
            else if (self.downloadTask) {
//                [self.downloadTask resume];
            }
            

        }
        //iOS 6.0
        else
        {
            _downloadURL = request.URL.absoluteString;
            writeToFile = NO;
            _request = request;
            _autoRetryDelay = 5.0;
            _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
            NSLog(@"This is iOS version less than 7 no background support available");
        }
        

    }
    return self;
}



- (void)setupBackgrounding {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appBackgrounding:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appForegrounding:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
}

- (void)appBackgrounding: (NSNotification *)notification {
    [self keepAlive];
}

- (void) keepAlive {
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        [self keepAlive];
    }];
}

- (void)appForegrounding: (NSNotification *)notification {
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}

- (NSURLSession *)backgroundSession
{
    /*
     Using disptach_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
     */
			NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:[NSString stringWithFormat:@"com.forge.changer-code.backgroundTransfer.%@",[self randomStringWithLength:12]]];
        configuration.allowsCellularAccess = YES;

		NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
	return session;
}

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

-(NSString *) randomStringWithLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length]) % [letters length]]];
    }
    
    return randomString;
}


- (BOOL)isConcurrent
{
    return YES;
}

- (void)start
{
    @synchronized (self)
    {
        if (!_executing && !_cancelled)
        {
            [self willChangeValueForKey:@"isExecuting"];
            _startDate = [NSDate date];
            _executing = YES;
            _finished = NO;
            _accumulatedData = nil;
                       if (self.uploadTask) {
                [self.uploadTask resume];
            }
            
            else if (self.downloadTask) {
                    [self.downloadTask resume];
                }
            else
            {
                [_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
                [_connection start];
            }
            
            [self didChangeValueForKey:@"isExecuting"];
        }
    }
}

- (void)cancel
{
    @synchronized (self)
    {
        if (!_cancelled)
        {
            [self willChangeValueForKey:@"isCancelled"];
            _cancelled = YES;
            if (self.uploadTask) {
                [self.uploadTask cancel];
            }
            else if (self.downloadTask) {
                [self.downloadTask cancel];
            }
            else
            {
                 [_connection cancel];

                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
                [self connection:_connection didFailWithError:error];
            }
            
            [self didChangeValueForKey:@"isCancelled"];
            
            //call callback
           
        }
    }
}

- (void)finish
{
    @synchronized (self)
    {
        if (_executing && !_finished)
        {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            _executing = NO;
            _finished = YES;
            [self didChangeValueForKey:@"isFinished"];
            [self didChangeValueForKey:@"isExecuting"];
        }
    }
}

- (void)fail
{
    @synchronized (self)
    {
        if (!_failed)
        {
            [self willChangeValueForKey:@"isCancelled"];
            _failed = YES;
            if (self.uploadTask) {
                [self.uploadTask cancel];
            }
            else if (self.downloadTask) {
                [self.downloadTask cancel];
            }
            else
            {
                [_connection cancel];
                //call callback
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
                [self connection:_connection didFailWithError:error];

            }
                      [self didChangeValueForKey:@"isCancelled"];
            
            
        }
    }
}

- (NSSet *)autoRetryErrorCodes
{
    if (!_autoRetryErrorCodes)
    {
        static NSSet *codes = nil;
        if (!codes)
        {
            codes = [NSSet setWithObjects:
                     @(NSURLErrorTimedOut),
                     @(NSURLErrorCannotFindHost),
                     @(NSURLErrorCannotConnectToHost),
                     @(NSURLErrorDNSLookupFailed),
                     @(NSURLErrorNotConnectedToInternet),
                     @(NSURLErrorNetworkConnectionLost),
                     nil];
        }
        return codes;
    }
    return _autoRetryErrorCodes;
}

#pragma mark NSURLSessionDelegate

/*
 If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
// */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if (backgroundSessionCompletionHandler) {
        void (^completionHandler)() = backgroundSessionCompletionHandler;
        backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    
    NSLog(@"All tasks are finished");
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error == nil)
    {
        NSLog(@"Task: %@ completed successfully", task);
        
        
        [self finish];
        
        NSError *error = nil;
        if ([task.response respondsToSelector:@selector(statusCode)])
        {
            //treat status codes >= 400 as an error
            NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
            if (statusCode == 200)
            {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"The server returned a %i error", @"RequestQueue HTTPResponse error message format"), statusCode];
                NSDictionary *infoDict = @{NSLocalizedDescriptionKey: message};
                error = [NSError errorWithDomain:@"HTTPResponseErrorDomain"
                                            code:statusCode
                                        userInfo:infoDict];
            }
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"yourfilename.dat"];
        [[NSFileManager defaultManager]removeItemAtPath:dataPath error:nil];
        
    }
    else
    {
        NSLog(@"Error code  %s %@ %@", __PRETTY_FUNCTION__, task.response, error);

    }
    self.downloadProgressHandler = nil;
    if (writeToFile)
        [downloadFileHandler closeFile];
    if (_completionHandler)
        _completionHandler((NSHTTPURLResponse *)task.response, _accumulatedData, error);
    self.downloadTask = nil;
	
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    if (_uploadProgressHandler)
    {
        float progress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
        _uploadProgressHandler(progress, totalBytesSent, totalBytesExpectedToSend);
    }
    
    
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    NSLog(@"CHALLENGE!!! (%@)", challenge.protectionSpace.authenticationMethod);
    
    if (challenge.error)
        NSLog(@"  -- error: %@", challenge.error.description);
    if (challenge.previousFailureCount > 0)
        NSLog(@"  -- previous failure count = %d", challenge.previousFailureCount);
    if (challenge.proposedCredential)
        NSLog(@"  -- proposed credential user: %@", challenge.proposedCredential.user);
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"   server = %@", challenge.protectionSpace.host);
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodNTLM]) {
        NSLog(@"   NSURLAuthenticationMethodNTLM");
        NSURLCredential *credential = [NSURLCredential credentialWithUser:@"username" password:@"passwordIsSecretShhh" persistence:NSURLCredentialPersistenceForSession];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        NSLog(@"   ????");
    }
    _executing= YES;
    _finished = NO;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
    /*
     Report progress on the task.
     If you created more than one task, you might keep references to them and report on them individually.
     */
    
//    if (downloadTask == self.downloadTask)
//    {
//        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    }
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    
    
    /*
     The download completed, you need to copy the file at targetPath before the end of this block.
     As an example, copy the file to the Documents directory of your app.
     */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs objectAtIndex:0];
    
    NSURL *originalURL = [[downloadTask originalRequest] URL];
    NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:[originalURL lastPathComponent]];
    NSError *errorCopy;
    
    // For the purposes of testing, remove any esisting file at the destination.
    [fileManager removeItemAtURL:destinationURL error:NULL];
    BOOL success = [fileManager copyItemAtURL:downloadURL toURL:destinationURL error:&errorCopy];
    if (success)
    {
        if (_accumulatedData == nil)
        {
            _accumulatedData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)MAX(0, downloadTask.response.expectedContentLength)];
        }
        NSData* data = [NSData dataWithContentsOfFile:[destinationURL path]];
        [_accumulatedData appendData:data];
        [fileManager removeItemAtURL:destinationURL error:NULL];

        NSLog(@"Hey I donwloaded data in background");
    }
    else
    {
        /*
         In the general case, what you might do in the event of failure depends on the error and the specifics of your application.
         */
    }
}
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (_autoRetry && [self.autoRetryErrorCodes containsObject:@(error.code)])
    {
        if(writeToFile)
        {
            [downloadFileHandler closeFile];
            [self refreshDownloadData];
        }
        else
            _accumulatedData = nil;
        
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        [_connection performSelector:@selector(start) withObject:nil afterDelay:_autoRetryDelay];
        _startDate = [NSDate date];
    }
    else
    {
        [self fail];
        NSHTTPURLResponse *_response = [[NSHTTPURLResponse alloc] initWithURL:_request.URL statusCode:error.code HTTPVersion:nil headerFields:nil];
        if (_completionHandler) _completionHandler(_response, _accumulatedData, error);
    }
}

- (void)connection:(NSURLConnection *)_connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (_authenticationChallengeHandler)
    {
        _authenticationChallengeHandler(challenge);
    }
    else
    {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"CHALLENGE!!! (%@)", challenge.protectionSpace.authenticationMethod);
    
    if (challenge.error)
        NSLog(@"  -- error: %@", challenge.error.description);
    if (challenge.previousFailureCount > 0)
        NSLog(@"  -- previous failure count = %d", challenge.previousFailureCount);
    if (challenge.proposedCredential)
        NSLog(@"  -- proposed credential user: %@", challenge.proposedCredential.user);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSLog(@"   server = %@", challenge.protectionSpace.host);
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }else {
        NSLog(@"   ????");
    }
    _executing= YES;
    _finished = NO;

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _responseReceived = response;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (_uploadProgressHandler)
    {
        float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        _uploadProgressHandler(progress, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(!writeToFile)
    {
        if (_accumulatedData == nil)
        {
            _accumulatedData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)MAX(0, _responseReceived.expectedContentLength)];
        }
        [_accumulatedData appendData:data];
    }
    else
        [downloadFileHandler writeData:data];
    
    if (_downloadProgressHandler)
    {
        bytesTransferred += [data length];
        NSInteger totalBytes = (NSUInteger)MAX(0, _responseReceived.expectedContentLength);
        _downloadProgressHandler((float)bytesTransferred / (float)totalBytes, bytesTransferred, totalBytes);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)_connection
{
    [self finish];
    
    NSError *error = nil;
    if ([_responseReceived respondsToSelector:@selector(statusCode)])
    {
        //treat status codes >= 400 as an error
        NSInteger statusCode = [(NSHTTPURLResponse *)_responseReceived statusCode];
        if (statusCode / 100 >= 4)
        {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"The server returned a %i error", @"RequestQueue HTTPResponse error message format"), statusCode];
            NSDictionary *infoDict = @{NSLocalizedDescriptionKey: message};
            error = [NSError errorWithDomain:@"HTTPResponseErrorDomain"
                                        code:statusCode
                                    userInfo:infoDict];
        }
    }
    
    self.downloadProgressHandler = nil;
    if (writeToFile)
        [downloadFileHandler closeFile];
    if (_completionHandler)
        _completionHandler((NSHTTPURLResponse *)_responseReceived, _accumulatedData, error);
    
}


@end
