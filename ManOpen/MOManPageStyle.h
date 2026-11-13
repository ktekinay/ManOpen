//
//  MOManPageStyle.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  Applying the man page font and colors from Preferences to a page's text,
//  repeatably, so open pages can follow preference changes (Plans 1a.9).
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/* Each run's font as the page was generated, kept so restyling never loses bold or italic. */
extern NSAttributedStringKey const MOOriginalFontAttributeName;

/*
 * Applies `font` (family and size) and `textColor` to `text`. Each run keeps
 * its own style: a bold or italic run becomes the bold or italic face of the
 * new family where one exists. The conversion always starts from the run's
 * original font, so going through a family without bold (such as Monaco) and
 * back restores the bold. Characters and their ranges don't change.
 * The text color is only set where it differs, so restyling with the same font
 * and color objects doesn't edit the text at all.
 * Returns whether any font changed (so the layout, and the scroll position, may have).
 */
BOOL MOApplyManPageStyle(NSMutableAttributedString *text, NSFont *font, NSColor *textColor);

/*
 * The colors man pages are drawn with. Each is one fixed color object that
 * draws as the color last given to MOSetManPageColors(), resolved in the
 * appearance it's drawn in. Pages keep using the same objects, so a color
 * change in Preferences only needs a redraw: no edit to the text and no new
 * layout, which keeps dragging in the color panel smooth on big pages (L2, L8).
 */
NSColor *MOManPageTextColor(void);
NSColor *MOManPageLinkColor(void);
NSColor *MOManPageBackgroundColor(void);

/* Sets what the man page colors draw as; nil means the system default for that color. */
void MOSetManPageColors(NSColor * _Nullable text, NSColor * _Nullable link, NSColor * _Nullable background);

/* `current` link attributes with the foreground color replaced by `linkColor`. */
NSDictionary<NSAttributedStringKey, id> *MOManPageLinkAttributes(NSDictionary<NSAttributedStringKey, id> * _Nullable current, NSColor *linkColor);

/*
 * Where to put the top of the window after a page is generated again
 * (Plans 1a.9, L7): the same character if the text is unchanged; otherwise
 * the same place in the same section (by name), clamped to that section;
 * otherwise the same character index, clamped to the new text.
 */
NSUInteger MOAnchorAfterReload(NSString *oldText, NSUInteger oldIndex,
                               NSArray<NSString *> *oldSections, NSArray<NSValue *> *oldSectionRanges,
                               NSString *newText,
                               NSArray<NSString *> *newSections, NSArray<NSValue *> *newSectionRanges);

NS_ASSUME_NONNULL_END
