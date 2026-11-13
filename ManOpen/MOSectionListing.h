//
//  MOSectionListing.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  File > List Pages lists a whole section by running apropos with a search
//  that matches the section reference, such as "(3)", in every index line.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* The List Pages menu item tag for "n - Tcl Calls". Tags 1-9 are the numbered
   sections, and 0 is All Pages. */
extern const NSInteger MOSectionListingTagN;

/*
 * The apropos search that lists every page in the section with this menu tag.
 *
 * apropos treats its argument as an extended regular expression, so the
 * parenthesis is escaped: "\(3" matches "printf(3)" and suffixed sections
 * such as "(3pm)", and "\(n\)" matches only section n. (The unescaped forms
 * failed: "(3" is an invalid expression, and "(n)" matches any line with an n.)
 * All Pages (0) returns the empty string, which ManOpen turns into ".".
 */
NSString *MOSectionListingQuery(NSInteger tag);

/*
 * The window title for a List Pages window, built from the menu item's title:
 * "All Pages" for All Pages (0), and "Section 3 - Library Calls" for a section
 * whose menu item is "3 - Library Calls".
 */
NSString *MOSectionListingTitle(NSInteger tag, NSString *menuItemTitle);

NS_ASSUME_NONNULL_END
