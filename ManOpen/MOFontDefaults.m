//
//  MOFontDefaults.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/16/26.
//

#import "MOFontDefaults.h"

NSString * const MOManFontKey = @"ManFont";

NSFont *MODefaultManFont(void)
{
    return [NSFont userFixedPitchFontOfSize:12.0];
}

NSFont *MOFontFromPreference(id value)
{
    if (![value isKindOfClass:[NSString class]])
        return nil;

    NSRange space = [value rangeOfString:@" "];
    if (space.location == NSNotFound)
        return nil;

    CGFloat size = [[value substringToIndex:space.location] doubleValue];
    NSString *name = [value substringFromIndex:NSMaxRange(space)];
    if (size <= 0.0 || name.length == 0)
        return nil;
    return [NSFont fontWithName:name size:size];
}

NSFont *MOManFont(NSUserDefaults *defaults)
{
    return MOFontFromPreference([defaults objectForKey:MOManFontKey]) ?: MODefaultManFont();
}

void MORestoreDefaultFont(NSUserDefaults *defaults)
{
    [defaults removeObjectForKey:MOManFontKey];
}
