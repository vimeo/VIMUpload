//
//  VIMNetworkTaskSessionManager.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 4/8/15.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
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

#import "VIMNetworkTaskSessionManager.h"
#import "VIMTaskQueueDebugger.h"

@implementation VIMNetworkTaskSessionManager

- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self)
    {        
#if (defined(ADHOC) || defined(RELEASE))
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        self.securityPolicy.allowInvalidCertificates = NO;
        self.securityPolicy.validatesDomainName = YES;
#endif
    }
    
    return self;
}

#pragma mark - Public API

- (void)setupBlocks
{
    [self setupSessionDidBecomeInvalid];
    [self setupDownloadTaskDidFinish];
    [self setupTaskDidComplete];
    [self setupDidFinishEventsForBackgroundURLSession];
}

- (void)callBackgroundEventsCompletionHandler
{
    if (self.completionHandler)
    {
        [VIMTaskQueueDebugger postLocalNotificationWithContext:self.session.configuration.identifier message:@"calling completionHandler"];
        
        self.completionHandler();
        self.completionHandler = nil;
    }
}

#pragma mark - Private API

- (void)setupSessionDidBecomeInvalid
{
    [self setSessionDidBecomeInvalidBlock:^(NSURLSession *session, NSError *error) {
        
        [VIMTaskQueueDebugger postLocalNotificationWithContext:session.configuration.identifier message:@"sessionDidBecomeInvalid"];
        
    }];
}

- (void)setupDownloadTaskDidFinish
{
    __weak typeof(self) welf = self;
    [self setDownloadTaskDidFinishDownloadingBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
        
        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return nil;
        }
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(sessionManager:downloadTask:didFinishWithLocation:)])
        {
            [strongSelf.delegate sessionManager:strongSelf downloadTask:downloadTask didFinishWithLocation:location];
        }
        
        return nil;
    }];
}

- (void)setupTaskDidComplete
{
    __weak typeof(self) welf = self;
    [self setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        
        [VIMTaskQueueDebugger postLocalNotificationWithContext:session.configuration.identifier message:@"sessionTaskDidComplete"];
        
        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return;
        }
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(sessionManager:taskDidComplete:)])
        {
            [strongSelf.delegate sessionManager:strongSelf taskDidComplete:task];
        }
        
    }];
}

- (void)setupDidFinishEventsForBackgroundURLSession
{
    __weak typeof(self) welf = self;
    [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        
        [VIMTaskQueueDebugger postLocalNotificationWithContext:session.configuration.identifier message:@"sessionDidFinishBackgroundEvents"];
        
        __strong typeof(welf) strongSelf = welf;
        if (strongSelf == nil)
        {
            return;
        }
        
        BOOL shouldCallCompletionHandler = YES;
        
        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(sessionManagerShouldCallBackgroundEventsCompletionHandler:)])
        {
            shouldCallCompletionHandler = [strongSelf.delegate sessionManagerShouldCallBackgroundEventsCompletionHandler:strongSelf];
        }
        
        if (shouldCallCompletionHandler)
        {
            [strongSelf callBackgroundEventsCompletionHandler];
        }
        
    }];
}

@end
