//
//  MOAproposTable.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOAproposTable.h"

NSString * const MOAproposNameKey = @"titles";
NSString * const MOAproposDescriptionKey = @"descriptions";

const CGFloat MOAproposDefaultNameColumnWidth = 180.0;
const CGFloat MOAproposMinimumContentWidth = 360.0;
const CGFloat MOAproposMinimumContentHeight = 200.0;

NSMutableArray<NSDictionary<NSString *, NSString *> *> *MOAproposRowsFromOutput(NSString *output)
{
    NSMutableArray *rows = [NSMutableArray array];
    // Deduplicate by the line text: NSDictionary's hash is just its count, so a set
    // of row dictionaries degrades to quadratic time (8 s for All Pages).
    NSMutableSet<NSString *> *seen = [NSMutableSet set];

    for (NSString *line in [output componentsSeparatedByString:@"\n"])
    {
        NSRange dashRange;

        if ([line length] == 0) continue;

        dashRange = [line rangeOfString:@"\t\t- "]; //OPENSTEP
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@"\t- "]; //OPENSTEP
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@"\t-" options:NSBackwardsSearch|NSAnchoredSearch];
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@" - "]; //MacOSX
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@" -" options:NSBackwardsSearch|NSAnchoredSearch];

        if (dashRange.length == 0) continue;
        if ([seen containsObject:line]) continue;
        [seen addObject:line];

        [rows addObject:@{ MOAproposNameKey: [line substringToIndex:dashRange.location],
                           MOAproposDescriptionKey: [line substringFromIndex:NSMaxRange(dashRange)] }];
    }

    return rows;
}

CGFloat MOAproposNameColumnWidth(CGFloat available, CGFloat preferred, CGFloat minName, CGFloat minDescription)
{
    CGFloat width = (preferred > 0.0) ? preferred : MOAproposDefaultNameColumnWidth;
    CGFloat maxName = available - minDescription;

    if (width > maxName)
        width = maxName;
    if (width < minName)
        width = minName;

    return width;
}

NSArray<NSSortDescriptor *> *MOAproposSortDescriptors(NSString *key, BOOL ascending)
{
    NSString *primary = [key isEqualToString:MOAproposDescriptionKey] ? MOAproposDescriptionKey : MOAproposNameKey;
    NSString *secondary = [primary isEqualToString:MOAproposNameKey] ? MOAproposDescriptionKey : MOAproposNameKey;
    SEL compare = @selector(localizedStandardCompare:);

    return @[ [NSSortDescriptor sortDescriptorWithKey:primary ascending:ascending selector:compare],
              [NSSortDescriptor sortDescriptorWithKey:secondary ascending:YES selector:compare] ];
}
