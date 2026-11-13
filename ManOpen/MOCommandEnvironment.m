//
//  MOCommandEnvironment.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOCommandEnvironment.h"

NSDictionary<NSString *, NSString *> *MOCommandEnvironment(NSDictionary<NSString *, NSString *> *inherited,
                                                           NSDictionary<NSString *, NSString *> *extra)
{
    NSMutableDictionary<NSString *, NSString *> *environment =
        (inherited != nil) ? [inherited mutableCopy] : [NSMutableDictionary dictionary];

    environment[@"MANPAGER"] = @"cat";
    environment[@"PAGER"] = @"cat";
    environment[@"WHATISPAGER"] = @"cat";
    [environment removeObjectForKey:@"MANCOLOR"];

    if (extra != nil)
        [environment addEntriesFromDictionary:extra];

    return [environment copy];
}
