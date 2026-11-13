//
//  MOAproposPrinting.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  The printed form of an Apropos window: two text columns instead of a
//  picture of the on-screen table, so descriptions wrap and no line is cut
//  in half at a page break.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/* Point size for printed Apropos results. */
extern const CGFloat MOAproposPrintFontSize;

/*
 * The fraction of the printable width given to the Name column: the on-screen
 * share of the Name column, kept between 20% and 45% so both columns stay usable.
 */
CGFloat MOAproposPrintNameFraction(CGFloat screenNameWidth, CGFloat screenDescriptionWidth);

/*
 * The column header printed at the top of every page: the two titles in bold,
 * the description title starting at `nameColumnWidth`. Black text.
 */
NSAttributedString *MOAproposPrintHeader(CGFloat nameColumnWidth, NSFont *font, NSString *nameTitle, NSString *descriptionTitle);

/*
 * The body text to print: one paragraph per row, in the given order. The
 * description starts at `nameColumnWidth` and its wrapped lines stay in that
 * column. A name too wide for its column gets a line of its own, with the
 * description on the next line. All text is black, whatever the appearance.
 */
NSAttributedString *MOAproposPrintText(NSArray<NSDictionary<NSString *, NSString *> *> *rows,
                                       CGFloat nameColumnWidth,
                                       NSFont *font);

/*
 * The view that prints Apropos results: the body text, with `headerText`
 * drawn in the top margin of every page and the page number in the bottom
 * margin. The print info's top and bottom margins must be equal and leave
 * room for them (add MOAproposPrintMarginExtra); AppKit uses the bottom margin
 * at the top of the page when printing a flipped view.
 */
@interface MOAproposPrintView : NSTextView
@property(nonatomic, copy, nullable) NSAttributedString *headerText;

/*
 * A non-editable view `width` points wide, sized to fit `text`, using TextKit 1.
 * (A text view made with -initWithFrame: uses TextKit 2, which creates a view
 * for every text fragment on every printed page and gets slower with each one:
 * All Pages took many minutes to print.) The view keeps its text storage alive,
 * since printing runs after the caller returns.
 */
- (instancetype)initWithText:(NSAttributedString *)text width:(CGFloat)width;
@end

/* Extra margin needed for the repeated header, in points. */
extern const CGFloat MOAproposPrintMarginExtra;

NS_ASSUME_NONNULL_END
