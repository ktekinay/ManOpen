//
//  MOManPagePrinting.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  Printing a man page from a separate view, so the printout never uses Dark
//  Mode colors and the on-screen window is left alone.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * A view of class `viewClass` (NSTextView or a subclass, such as ManTextView,
 * which draws page numbers) for printing the page shown by `screenView`:
 *   - a copy of its text, laid out at the same width, inset and padding, so
 *     the preformatted lines break exactly as on screen;
 *   - the same link appearance (linkTextAttributes);
 *   - the light (Aqua) appearance, so system colors such as the default text
 *     and link colors print dark on white, while colors the user chose print
 *     as chosen;
 *   - no background, whatever the background color preference;
 *   - TextKit 1 (printing a TextKit 2 view slows down with every page).
 * The view keeps its text alive while printing runs.
 */
NSTextView *MOMakeManPagePrintView(Class viewClass, NSTextView *screenView);

NS_ASSUME_NONNULL_END
