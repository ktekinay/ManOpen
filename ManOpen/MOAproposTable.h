//
//  MOAproposTable.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  Layout and sorting rules for the Apropos results table, kept separate from
//  AproposDocument so they can be unit tested.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

NS_ASSUME_NONNULL_BEGIN

/* Row dictionary keys; they are also the table column identifiers. */
extern NSString * const MOAproposNameKey;          // "titles"
extern NSString * const MOAproposDescriptionKey;   // "descriptions"

/* Smallest content size for an Apropos window: room for both columns at their
   minimum widths (80 + 120 pt), the scroller, and several rows. */
extern const CGFloat MOAproposMinimumContentWidth;
extern const CGFloat MOAproposMinimumContentHeight;

/* Name column width used until the user resizes it. */
extern const CGFloat MOAproposDefaultNameColumnWidth;

/*
 * Parses apropos output into rows (MOAproposNameKey / MOAproposDescriptionKey),
 * one per line of the form "name(section), ... - description". Lines without a
 * separator are skipped, and duplicate lines (apropos repeats a page when its
 * directory is on the man path twice) are kept only once, in first-seen order.
 * Runs in linear time: All Pages produces 20,000+ lines.
 */
NSMutableArray<NSDictionary<NSString *, NSString *> *> *MOAproposRowsFromOutput(NSString * _Nullable output);

/*
 * The width to give the Name column.
 *
 * `available` is the width both columns share. The result is `preferred`
 * clamped so that Name is at least `minName` wide and Description keeps at
 * least `minDescription`. If the space is too small for both minimums, Name
 * gets its minimum. A `preferred` of zero or less means "not set" and uses
 * MOAproposDefaultNameColumnWidth.
 */
CGFloat MOAproposNameColumnWidth(CGFloat available, CGFloat preferred, CGFloat minName, CGFloat minDescription);

/*
 * The sort descriptors for the results: `key` (Name or Description) in the
 * given direction, compared the way Finder compares names
 * (localizedStandardCompare:), then the other column ascending to break ties.
 * An unknown or nil key sorts by Name.
 */
NSArray<NSSortDescriptor *> *MOAproposSortDescriptors(NSString * _Nullable key, BOOL ascending);

NS_ASSUME_NONNULL_END
