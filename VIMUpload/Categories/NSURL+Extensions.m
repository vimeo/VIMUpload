//
//  NSURL+Extensions.m
//  VIMUpload
//
//  Created by Hanssen, Alfie on 9/9/15.
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

#import "NSURL+Extensions.h"

@implementation NSURL (Extensions)

// TODO: consolidate the below two methods [AH] 9/9/2015

+ (NSURL *)taskQueueURLWithDirectoryName:(NSString *)directoryName
               sharedContainerIdentifier:(NSString *)sharedContainerIdentifier
{
    NSParameterAssert(directoryName);
    
    if (!directoryName)
    {
        return nil;
    }

    NSURL *groupURL = nil;
    
    if (sharedContainerIdentifier)
    {
        groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:sharedContainerIdentifier];
    }
    
    if (groupURL == nil)
    {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        groupURL = [NSURL URLWithString:documentsDirectory];
    }
    
    groupURL = [groupURL URLByAppendingPathComponent:directoryName];
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:groupURL.absoluteString withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success)
    {
        NSLog(@"Unable to create task queue directory: %@", error);
        
        // If all else fails, use the temporary directory,
        // This is not preferred as the file could be removed without notice,
        // Causing upload to fail [AH] 9/9/2015
        
        NSString *URLString = [NSTemporaryDirectory() stringByAppendingPathComponent:directoryName];
        
        groupURL = [NSURL URLWithString:URLString];
    }
    
    return groupURL;
}

+ (NSURL *)uploadURLWithDirectoryName:(NSString *)directoryName
            sharedContainerIdentifier:(NSString *)sharedContainerIdentifier
{
    NSParameterAssert(directoryName);
    
    if (!directoryName)
    {
        return nil;
    }
    
    NSURL *groupURL = nil;
    
    if (sharedContainerIdentifier)
    {
        groupURL = [[NSFileManager new] containerURLForSecurityApplicationGroupIdentifier:sharedContainerIdentifier];
    }
    
    if (groupURL == nil)
    {
//        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        groupURL = [NSURL URLWithString:NSTemporaryDirectory()];
    }
    
    groupURL = [groupURL URLByAppendingPathComponent:directoryName];
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:groupURL.absoluteString withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success)
    {
        NSLog(@"Unable to create export directory: %@", error);
        
        // If all else fails, use the temporary directory,
        // This is not preferred as the file could be removed without notice,
        // Causing upload to fail [AH] 9/9/2015
        
        NSString *URLString = [NSTemporaryDirectory() stringByAppendingPathComponent:directoryName];
        
        groupURL = [NSURL URLWithString:URLString];
    }
    
    return groupURL;
}

@end
