//
//  NSError+VIMUpload.m
//  VIMUpload
//
//  Created by Hanssen, Alfie on 7/30/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "NSError+VIMUpload.h"
#import "AFNetworking.h"

NSString *const VIMTempFileMakerErrorDomain = @"VIMTempFileMakerErrorDomain";
NSString *const VIMUploadFileTaskErrorDomain = @"VIMUploadFileTaskErrorDomain";
NSString *const VIMCreateRecordTaskErrorDomain = @"VIMCreateRecordTaskErrorDomain";
NSString *const VIMMetadataTaskErrorDomain = @"VIMMetadataTaskErrorDomain";
NSString *const VIMActivateRecordTaskErrorDomain = @"VIMActivateRecordTaskErrorDomain";

@implementation NSError (VIMUpload)

+ (NSError *)errorWithError:(NSError *)error domain:(NSString *)domain
{
    if (error == nil)
    {
        return nil;
    }
    
    // TODO: Modify this so we're adding a custom domain rather than overwriting the original domain [ghking] 10/6/15
    
    return [NSError errorWithDomain:domain code:error.code userInfo:error.userInfo];
}

+ (NSError *)errorWithURLResponse:(NSURLResponse *)response domain:(NSString *)domain description:(NSString *)description
{
    if (response == nil)
    {
        return nil;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    if (description)
    {
        userInfo[NSLocalizedDescriptionKey] = description;
    }
    
    userInfo[AFNetworkingOperationFailingURLResponseErrorKey] = response;

    return [NSError errorWithDomain:domain code:0 userInfo:userInfo];
}

- (BOOL)isInsufficientLocalStorageError
{
    return self.code == VIMUploadErrorCodeInsufficientLocalStorage;
}

- (BOOL)isMetadataFailedToSaveError
{
    return [self.domain isEqualToString:VIMMetadataTaskErrorDomain];
}

@end
