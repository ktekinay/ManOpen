//
//  MOAppSelection.m
//  openman
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOAppSelection.h"

NSString * const MOMinimumCompatibleVersion = @"3.0";

@implementation MOAppCandidate

+ (instancetype)candidateWithURL:(NSURL *)url version:(NSString *)version
{
    MOAppCandidate *candidate = [[self alloc] init];
    candidate->_url = [url copy];
    candidate->_version = [version copy];
    return candidate;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", self.url.path, self.version];
}

@end

BOOL MOIsCompatibleVersion(NSString *version)
{
    if (![version isKindOfClass:[NSString class]] || version.length == 0)
        return NO;
    return [version compare:MOMinimumCompatibleVersion options:NSNumericSearch] != NSOrderedAscending;
}

NSURL *MOEnclosingAppBundle(NSString *resolvedExecutablePath)
{
    NSArray<NSString *> *components = resolvedExecutablePath.pathComponents;

    // Search from the end, so an app nested inside another app's bundle wins.
    for (NSInteger i = (NSInteger)components.count - 2; i >= 0; i--)
    {
        if ([components[i].pathExtension caseInsensitiveCompare:@"app"] == NSOrderedSame &&
            [components[i + 1] isEqualToString:@"Contents"])
        {
            NSArray *bundleComponents = [components subarrayWithRange:NSMakeRange(0, (NSUInteger)i + 1)];
            return [NSURL fileURLWithPath:[NSString pathWithComponents:bundleComponents] isDirectory:YES];
        }
    }
    return nil;
}

static NSInteger LocationRank(NSURL *url, NSString *homeDirectory)
{
    NSString *path = url.path.stringByStandardizingPath;
    NSString *userApplications = [[homeDirectory stringByAppendingPathComponent:@"Applications"] stringByAppendingString:@"/"];

    if ([path hasPrefix:@"/Applications/"])
        return 0;
    if ([path hasPrefix:userApplications])
        return 1;
    return 2;
}

NSURL *MOChooseManOpenApp(MOAppCandidate *ownApp, NSArray<MOAppCandidate *> *candidates, NSString *homeDirectory)
{
    if (ownApp != nil && MOIsCompatibleVersion(ownApp.version))
        return ownApp.url;

    MOAppCandidate *best = nil;
    NSInteger bestRank = 0;

    for (MOAppCandidate *candidate in candidates)
    {
        if (!MOIsCompatibleVersion(candidate.version))
            continue;

        NSInteger rank = LocationRank(candidate.url, homeDirectory);

        if (best == nil)
        {
            best = candidate;
            bestRank = rank;
            continue;
        }

        NSComparisonResult byVersion = [candidate.version compare:best.version options:NSNumericSearch];

        // Strictly better only, so ties keep Launch Services' order.
        if (byVersion == NSOrderedDescending || (byVersion == NSOrderedSame && rank < bestRank))
        {
            best = candidate;
            bestRank = rank;
        }
    }

    return best.url;
}
