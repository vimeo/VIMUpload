//
//  VIMTaskQueueArchiver.m
//  VIMUpload
//
//  Created by Alfred Hanssen on 8/14/15.
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

#import "VIMTaskQueueArchiver.h"
#import "NSURL+Extensions.h"

static NSString *const ArchiveExtension = @"archive";
static NSString *const TaskQueueDirectory = @"task-queue";

@interface VIMTaskQueueArchiver ()

@property (nullable, strong) NSString *sharedContainerID;

@end

@implementation VIMTaskQueueArchiver

- (instancetype)initWithSharedContainerID:(NSString *)containerID
{
    self = [super init];
    if (self)
    {
        _sharedContainerID = [containerID length] ? containerID : nil;
        
    }
    
    return self;
}

#pragma mark - VIMTaskQueueArchiverProtocol

- (nullable id)loadObjectForKey:(nonnull NSString *)key
{
    if (![key length])
    {
        return nil;
    }
    
    id object = nil;

    NSString *path = [self archivePathForKey:key];

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data)
    {
        @try
        {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        @catch (NSException *exception)
        {
            NSLog(@"VIMTaskQueueArchiver: Exception loading object: %@", exception);
            
            [self deleteObjectForKey:key];
        }
    }
    
    return object;
}

- (void)saveObject:(nonnull id)object forKey:(nonnull NSString *)key
{
    if (!object || ![key length])
    {
        return;
    }

    NSString *path = [self archivePathForKey:key];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    if (!success)
    {
        NSLog(@"VIMTaskQueueArchiver: Error saving object");
    }
}

- (void)deleteObjectForKey:(nonnull NSString *)key
{
    if (![key length])
    {
        return;
    }

    NSString *path = [self archivePathForKey:key];

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (!success)
    {
        NSLog(@"VIMTaskQueueArchiver: Error deleting object: %@", error);
    }
}

#pragma mark - Utilities

- (NSString *)archivePathForKey:(NSString *)key
{
    NSURL *baseURL = [NSURL taskQueueURLWithDirectoryName:TaskQueueDirectory sharedContainerIdentifier:self.sharedContainerID];
    
    NSString *filename = [key stringByAppendingPathExtension:ArchiveExtension];
    
    NSURL *URL = [baseURL URLByAppendingPathComponent:filename];
    
    return URL.absoluteString;
}

@end
