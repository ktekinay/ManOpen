//
//  MOManPath.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOManPath.h"

NSString *MOManPathFromDirectories(NSArray<NSString *> *directories)
{
    NSMutableArray<NSString *> *entries = [NSMutableArray array];

    for (id directory in directories)
    {
        if ([directory isKindOfClass:[NSString class]] && [directory length] > 0)
            [entries addObject:directory];
    }

    // The trailing empty entry tells man to append its default search path.
    // (Joining a lone empty entry would give "", which means "no path" to ManOpen.)
    if (entries.count == 0)
        return @":";

    return [[entries componentsJoinedByString:@":"] stringByAppendingString:@":"];
}
