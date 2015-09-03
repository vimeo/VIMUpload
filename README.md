# VIMUpload

`VIMUpload` is an Objective-C library that enables upload of videos to Vimeo. Its core component is a serial task queue that executes composite tasks (tasks with subtasks). 

The upload system uses a background configured NSURLSession to manage a queue of video uploads (i.e. uploads continue regardless of whether the app is in the foreground or background). It can be configured to manage two background sessions if you plan on initiating uploads from within an app as well as an extension.

The upload queue can be paused and resumed, and it is automatically paused/resumed when losing/gaining an internet connection. It can also be configured to restrict uploads to wifi only. 

The queue is persisted to disk so that in the event of an app termination event it can be reconstructed to the state it was in before termination.

If you're looking to interact with the Vimeo API for things other than video upload, check out [VIMNetworking](https://github.com/vimeo/VIMNetworking).

## Sample Project

Check out the [Pegasus] (https://github.com/vimeo/Pegasus) sample project.

## Setup

### Cocoapods

```Ruby
# Add this to your podfile
target 'YourTarget' do
	pod 'VIMUpload', '1.0.0' # Replace with the latest version
end
```

Note that VIMUpload depends on `AFNetworking`. It will be imported as a pod. 

###Git Submodules

Add `VIMUpload` and `AFNetworking` (Release 2.5.4) as submodules of your git repository. 

```
git submodule add git@github.com:vimeo/VIMUpload.git
git submodule add git@github.com:AFNetworking/AFNetworking.git
```

Add each submodule's classes to your project / target. 

If you're also including `VIMNetworking` in your project / target, note that both `VIMUpload` and `VIMNetworking` include the `Certificate/digicert-sha2.cer` file (this file is used for cert pinning). You'll have to remove one of the `digicert-sha2.cer` files from your target to avoid a "Multiple build commands for output file..." warning.

## Prerequisites

1. Ensure that you've verified your Vimeo account. When you create an account, you'll receive an email asking that you verify your account. Until you verify your account you will not be able to upload videos using the API. 
2. Ensure you have been granted permission to use the "upload" scope. This permission must explicitly be granted by Vimeo API admins. You can request this permission on your app page under "Request upload access". Visit [developer.vimeo.com](https://developer.vimeo.com/).
3. Ensure that the OAuth token that you're using to make your requests has the "upload" scope included.

## Initialization

Subclass `VIMTaskQueue` and implement a singleton object:

```Objective-C
+ (instancetype)sharedAppQueue
{
    static MYUploadTaskQueueSubclass *sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
      	NSURL *url = [NSURL URLWithString:@"https://api.vimeo.com/"];

        NSURLSessionConfiguration *configuration = ...; // A background configuration with optional shared container identifier (if you plan on uploading from an extension)
        
    	VIMNetworkTaskSessionManager *sessionManager =  [[VIMNetworkTaskSessionManager alloc] initWithBaseURL:url sessionConfiguration:configuration];
    	sessionManager.requestSerializer = ...;
    	sessionManager.responseSerializer = ...;

	// Where client.requestSerializer is an AFJSONRequestSerializer subclass that serializes the following information on each request:
	// [serializer setValue:@"application/vnd.vimeo.*+json; version=3.2" forHTTPHeaderField:@"Accept"];
	// [serializer setValue:@"Bearer your_oauth_token" forHTTPHeaderField:@"Authorization"];

        sharedInstance = [[self alloc] initWithSessionManager:sessionManager];

    });
    
    return sharedInstance;
}
```

If you plan to initiate uploads from an extension, you will need to use a separate instance of `VIMUploadTaskQueue`, initialized with a separate `VIMNetworkTaskSessionManager`, initialized with a separate background session identifier.

Load your `VIMUploadTaskQueue`(s) at each app launch.

```Objective-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // ...

    [MYUploadTaskQueueSubclass sharedAppQueue];
    [MYUploadTaskQueueSubclass sharedExtensionQueue];

    return YES;
}
```

Implement the `application:handleEventsForBackgroundURLSession:completionHandler:` method in your AppDelegate:

```Objective-C
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    if ([identifier isEqualToString:[MYUploadTaskQueueSubclass sharedAppQueue].sessionManager.session.configuration.identifier])
    {
        [MYUploadTaskQueueSubclass sharedAppQueue].sessionManager.completionHandler = completionHandler;
    }
    else if ([identifier isEqualToString:[MYUploadTaskQueueSubclass sharedExtensionQueue].sessionManager.session.configuration.identifier])
    {
        [MYUploadTaskQueueSubclass sharedExtensionQueue].sessionManager.completionHandler = completionHandler;
    }
}
```

## Uploading Videos 

Enqueue a `PHAsset` for upload.

```Objective-C
PHAsset *asset = ...;
VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithPHAsset:asset];
[[MYUploadTaskQueueSubclass sharedAppQueue] uploadVideoAssets:@[videoAsset]];
```

Enqueue an `AVURLAsset` for upload.

```Objective-C
NSURL *URL = ...;
AVURLAsset *URLAsset = [AVURLAsset assetWithURL:URL];
BOOL canUploadFromSource = ...; // If the asset doesn't need to be copied to a tmp directory before upload, set this to YES
VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithURLAsset:URLAsset canUploadFromSource:canUploadFromSource];
[[MYUploadTaskQueueSubclass sharedAppQueue] uploadVideoAssets:@[videoAsset]];
```

Enqueue multiple assets for upload.

```Objective-C
NSArray *videoAssets = @[...];
[[MYUploadTaskQueueSubclass sharedAppQueue] uploadVideoAssets:videoAssets];
```

Cancel an upload.

```Objective-C
VIMVideoAsset *videoAsset = ...;
[[MYUploadTaskQueueSubclass sharedAppQueue] cancelUploadForVideoAsset:videoAsset];
```

Cancel all uploads.

```Objective-C
[[MYUploadTaskQueueSubclass sharedAppQueue] cancelAllUploads];
```

Pause all uploads.

```Objective-C
[[MYUploadTaskQueueSubclass sharedAppQueue] pause];
```

Resume all uploads.

```Objective-C
[[MYUploadTaskQueueSubclass sharedAppQueue] resume];
```

Ensure that uploads only occur when connected via wifi...or not. If `cellularUploadEnabled` is set to `NO`, the upload queue will automatically pause when leaving wifi and automatically resume when entering wifi. (Note: the queue will automatically pause/resume when the device is taken offline/online.)

```Objective-C
[MYUploadTaskQueueSubclass sharedAppQueue].cellularUploadEnabled = NO;
```

Add video metadata to an enqueued or in-progress upload.

```Objective-C
VIMVideoAsset *videoAsset = ...;

VIMVideoMetadata *videoMetadata = [[VIMVideoMetadata alloc] init];
videoMetadata.videoTitle = @"Really cool title";
videoMetadata.videoDescription = @"Really cool description"";
videoMetadata.videoPrivacy = (NSString *)VIMPrivacyValue_Private;

[[MYUploadTaskQueueSubclass sharedAppQueue] addMetadata:videoMetadata toVideoAsset:videoAsset withCompletionBlock:^(BOOL didAdd) {
    
    if (!didAdd)
    {
        // The upload has already finished, 
        // Set the metadata using the VIMAPIClient method updateVideoWithURI:title:description:privacy:completionHandler:
    }
    
}];
```

## Tracking Upload State & Progress

If you build UI to support pause and resume, listen for the `VIMNetworkTaskQueue_DidSuspendOrResumeNotification` notification and update your UI accordingly.

```Objective-C
- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadTaskQueueDidSuspendOrResume:) name:VIMNetworkTaskQueue_DidSuspendOrResumeNotification object:nil];
}

- (void)uploadTaskQueueDidSuspendOrResume:(NSNotification *)notification
{
    BOOL isSuspended = [[MYUploadTaskQueueSubclass sharedAppQueue] isSuspended];
    [self.pauseResumeButton setSelected:isSuspended];
}
```

Use KVO to communicate upload state and upload progress via your UI. Observe changes to `VIMVideoAsset`'s `uploadState` and `uploadProgressFraction` properties.

```Objective-C
static void *UploadStateContext = &UploadStateContext;
static void *UploadProgressContext = &UploadProgressContext;

- (void)addObservers
{
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) options:NSKeyValueObservingOptionNew context:UploadStateContext];
    
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) options:NSKeyValueObservingOptionNew context:UploadProgressContext];
}

- (void)removeObservers
{
    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) context:UploadStateContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }

    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) context:UploadProgressContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == UploadStateContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadState))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadStateDidChange];
            });
        }
    }
    else if (context == UploadProgressContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadProgressFraction))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadProgressDidChange];
            });
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

When your UI is loaded or refreshed, associate your newly create VIMVideoAsset objects with their upload task counterparts so your UI continues to communicate upload state and progress.

```Objective-C
NSArray *videoAssets = self.datasource.items; // For example
[[MYUploadTaskQueueSubclass sharedAppQueue] associateVideoAssetsWithUploads:videoAssets];
```

## License

`VIMUpload` is available under the MIT license. See the LICENSE file for more info.

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`

Get in touch [here](Vimeo.com/help/contact)
