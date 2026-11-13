//
//  MOSectionListing.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOSectionListing.h"

const NSInteger MOSectionListingTagN = 20;

NSString *MOSectionListingQuery(NSInteger tag)
{
    if (tag == MOSectionListingTagN)
        return @"\\(n\\)";
    if (tag >= 1 && tag <= 9)
        return [NSString stringWithFormat:@"\\(%ld", (long)tag];
    return @"";
}

NSString *MOSectionListingTitle(NSInteger tag, NSString *menuItemTitle)
{
    if (tag == 0)
        return menuItemTitle;
    return [NSString stringWithFormat:NSLocalizedString(@"Section %@", @"Window title for File > List Pages > <section>; %@ is the menu item, such as \"3 - Library Calls\""), menuItemTitle];
}
