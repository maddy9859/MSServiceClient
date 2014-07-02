//  Created by Madhavi Solanki on 02/07/14.
//  Copyright (c) 2014 Madhavi. All rights reserved.

#ifndef ForgeModule_MSServiceClientDefines_h
#define ForgeModule_MSServiceClientDefines_h

#pragma mark Constants

#define RequestTimeout 3600.0


#pragma mark -
#pragma mark Error Domain/Codes

//NSString *const HTTPResponseErrorDomain = @"HTTPResponseErrorDomain";


typedef void (^MSCompletionHandler) (NSHTTPURLResponse *response, NSData *data, NSError *error);
typedef void (^MSProgressHandler) (float progress, int64_t bytesTransferred, int64_t totalBytes);
typedef void (^MSAuthenticationChallengeHandler) (NSURLAuthenticationChallenge *challenge);




typedef enum
{
    MSServiceClientAllocationError = 0,
    MSServiceClientInvalidFormatError = 1,
    MSServiceClientUnhandledFormatError = 2
    
} MSServiceClientErrorCode;


#pragma mark -
#pragma mark Enumerations

typedef enum
{
    MSServiceClientAllField = 0,
    MSServiceClientTitleField = 1,
    
} MSServiceClientFieldCode;



typedef enum
{
    MSServiceMethodGet,
    MSServiceMethodPost,
    MSServiceMethodPut,
    MSServiceMethodDelete
    
}MSServiceMethod;

enum
{
    MSServiceFormatRaw = 0,
    MSServiceFormatString = 1,
    MSServiceFormatFormEncoded = 2,
    MSServiceFormatJson = 3
    
};
typedef NSUInteger MSServiceFormat;

typedef enum
{
    MSServiceResultCancelled = -1,
    MSServiceResultFailed = 0,
    MSServiceResultSuccess = 1
    
} MSServiceResult;

#endif


