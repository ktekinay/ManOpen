//
//  MOPreferenceUpdates.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOPreferenceUpdates.h"

const NSTimeInterval MOPreferenceUpdateInterval = 0.1;

static NSDictionary<NSString *, NSNumber *> *UpdatesByKey(void)
{
    static NSDictionary *updates;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        updates = @{
            @"ManFont":             @(MOManPageUpdateRestyle),
            @"ManTextColor":        @(MOManPageUpdateRestyle),
            @"ManLinkColor":        @(MOManPageUpdateRestyle),
            @"ManBackgroundColor":  @(MOManPageUpdateRestyle),
            @"UseBold":             @(MOManPageUpdateRegenerateAll),
            @"UseItalics":          @(MOManPageUpdateRegenerateAll),
            @"NroffCommand":        @(MOManPageUpdateRegenerateNroffFiles),
        };
    });
    return updates;
}

NSArray<NSString *> *MOObservedPreferenceKeys(void)
{
    return [UpdatesByKey().allKeys sortedArrayUsingSelector:@selector(compare:)];
}

MOManPageUpdate MOUpdateForPreferenceKey(NSString *key)
{
    return UpdatesByKey()[key].unsignedIntegerValue;
}

MOManPageAction MOActionForPage(MOManPageUpdate pending, MOManPageSource source)
{
    if ((pending & MOManPageUpdateRegenerateAll) ||
        ((pending & MOManPageUpdateRegenerateNroffFiles) && source == MOManPageSourceNroffFile))
        return MOManPageActionRegenerate;
    if (pending & MOManPageUpdateRestyle)
        return MOManPageActionRestyle;
    return MOManPageActionNone;
}

@implementation MOChangeCoalescer
{
    NSTimeInterval _interval;
    void (^_handler)(NSUInteger);
    NSUInteger _pending;
    NSTimer *_timer;
}

- (instancetype)initWithInterval:(NSTimeInterval)interval handler:(void (^)(NSUInteger))handler
{
    self = [super init];
    if (self)
    {
        _interval = interval;
        _handler = [handler copy];
    }
    return self;
}

- (void)dealloc
{
    [_timer invalidate];
}

- (void)noteChanges:(NSUInteger)changes
{
    if (changes == 0)
        return;
    _pending |= changes;
    if (_timer != nil)
        return;

    __weak MOChangeCoalescer *weakSelf = self;
    _timer = [NSTimer timerWithTimeInterval:_interval repeats:NO block:^(NSTimer *timer) {
        [weakSelf fire];
    }];
    // Common modes include the modal panel and event tracking modes.
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)fire
{
    NSUInteger changes = _pending;
    _pending = 0;
    _timer = nil;
    if (changes != 0)
        _handler(changes);
}

@end
