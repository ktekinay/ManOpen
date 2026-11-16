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

/* The appearances man page colors can be chosen for (Plans 1a.13, C1). */
typedef NS_ENUM(NSInteger, MOColorAppearance) {
    MOColorAppearanceLight,
    MOColorAppearanceDark,
};

/*
 * Which set of colors an appearance uses: Dark for Dark Mode and its
 * variants (Increase Contrast, vibrant), otherwise Light (C6).
 */
MOColorAppearance MOColorAppearanceOf(NSAppearance * _Nullable appearance);

/*
 * The colors man pages are drawn with. Each is one fixed color object that
 * draws as the color last given to MOSetManPageColors() for the appearance
 * it's drawn in, resolved in that appearance. Pages keep using the same
 * objects, so a color change in Preferences, or a switch between Light and
 * Dark Mode, only needs a redraw: no edit to the text and no new layout,
 * which keeps dragging in the color panel smooth on big pages (L2, L8, C5).
 */
NSColor *MOManPageTextColor(void);
NSColor *MOManPageLinkColor(void);
NSColor *MOManPageBackgroundColor(void);

/*
 * Sets what the man page colors draw as in `appearance`; nil means the system
 * default for that color, as it looks in the appearance drawn in. One of the
 * man page colors themselves (or a stored copy of one) also means the default:
 * drawing it would only lead back to itself.
 */
void MOSetManPageColors(MOColorAppearance appearance, NSColor * _Nullable text, NSColor * _Nullable link, NSColor * _Nullable background);

/* YES for one of the man page colors above, or a copy of one decoded from preferences. */
BOOL MOIsManPageColor(NSColor * _Nullable color);

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
