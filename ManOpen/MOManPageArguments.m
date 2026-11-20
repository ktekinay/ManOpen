//
//  MOManPageArguments.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/20/26.
//

#import "MOManPageArguments.h"

const NSUInteger MOMaxManPageNameLength = 256;

static BOOL OnlyCharactersFrom(NSString *string, NSCharacterSet *allowed)
{
    return [string rangeOfCharacterFromSet:allowed.invertedSet].location == NSNotFound;
}

BOOL MOIsValidManPageName(NSString *name)
{
    static NSCharacterSet *allowed;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        allowed = [NSCharacterSet characterSetWithCharactersInString:
                   @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._+:@-["];
    });

    if (![name isKindOfClass:[NSString class]] || name.length == 0 || name.length > MOMaxManPageNameLength)
        return NO;
    if ([name hasPrefix:@"-"])
        return NO;
    return OnlyCharactersFrom(name, allowed);
}

BOOL MOIsValidManSection(NSString *section)
{
    static NSCharacterSet *allowed;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        allowed = [NSCharacterSet characterSetWithCharactersInString:
                   @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"];
    });

    if (section == nil)
        return YES;
    if (![section isKindOfClass:[NSString class]] || section.length > 8)
        return NO;
    return OnlyCharactersFrom(section, allowed);
}

NSString *MOShellQuoted(NSString *string)
{
    // Inside single quotes the shell treats every character literally except
    // the closing quote, so each ' becomes '\'' (close, escaped quote, reopen).
    return [NSString stringWithFormat:@"'%@'", [string stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"]];
}

NSString *MOManPageArguments(NSString *name, NSString *section)
{
    if (!MOIsValidManPageName(name) || !MOIsValidManSection(section))
        return nil;
    if (section.length > 0)
        return [NSString stringWithFormat:@" %@ %@", MOShellQuoted(section.lowercaseString), MOShellQuoted(name)];
    return [NSString stringWithFormat:@" %@", MOShellQuoted(name)];
}
