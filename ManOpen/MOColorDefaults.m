//
//  MOColorDefaults.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOColorDefaults.h"

NSString * const MOTextColorKey = @"ManTextColor";
NSString * const MOLinkColorKey = @"ManLinkColor";
NSString * const MOBackgroundColorKey = @"ManBackgroundColor";
NSString * const MOLegacyTextColorKey = @"TextColor";
NSString * const MOLegacyLinkColorKey = @"LinkColor";
NSString * const MOLegacyBackgroundColorKey = @"BackgroundColor";

NSColor *MOColorFromData(NSData *data)
{
    if (![data isKindOfClass:[NSData class]] || data.length == 0)
        return nil;

    id object = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:data error:NULL];
    // The unarchiver can hand back a string even though NSColor was asked for.
    NSColor *color = [object isKindOfClass:[NSColor class]] ? object : nil;

    if (color == nil && object == nil)
    {
        // ManOpen 2.x stored colors with the old, non-keyed NSArchiver.
        @try
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            id object = [NSUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
            color = [object isKindOfClass:[NSColor class]] ? object : nil;
        }
        @catch (NSException *exception)
        {
            color = nil;
        }
    }
    return color;
}

NSData *MODataFromColor(NSColor *color)
{
    if (color == nil)
        return nil;
    return [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:YES error:NULL];
}

NSColor *MODefaultLinkColor(void)
{
    return [NSColor linkColor];
}

BOOL MOIsOldDefaultLinkColor(NSColor *color)
{
    if (color == nil || color.type != NSColorTypeComponentBased || ![color.colorSpace isEqual:[NSColorSpace deviceRGBColorSpace]])
        return NO;

    const CGFloat tolerance = 0.001; // stored as floats
    return fabs(color.redComponent - 0.1) < tolerance &&
           fabs(color.greenComponent - 0.1) < tolerance &&
           fabs(color.blueComponent - 1.0) < tolerance &&
           fabs(color.alphaComponent - 1.0) < tolerance;
}

void MOMigrateColorDefaults(NSUserDefaults *defaults)
{
    // Call before registering defaults, so only stored values are seen.
    for (NSString *key in @[ MOLinkColorKey, MOLegacyLinkColorKey ])
    {
        NSData *data = [defaults dataForKey:key];

        if (data != nil && MOIsOldDefaultLinkColor(MOColorFromData(data)))
            [defaults removeObjectForKey:key];
    }
}

void MORestoreDefaultColors(NSUserDefaults *defaults)
{
    for (NSString *key in @[ MOTextColorKey, MOLinkColorKey, MOBackgroundColorKey,
                             MOLegacyTextColorKey, MOLegacyLinkColorKey, MOLegacyBackgroundColorKey ])
    {
        [defaults removeObjectForKey:key];
    }
}
