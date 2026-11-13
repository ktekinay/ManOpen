//
//  ManWindowController.h
//  ManOpen (Application)
//
//  Created by Nick Zitzmann on 2/23/21.
//

#import <Cocoa/Cocoa.h>

@interface ManTextView : NSTextView
- (void)scrollRangeToTop:(NSRange)charRange;
/* The character at the top of the visible part of the page. */
- (NSUInteger)characterIndexAtTop;
/* Scrolls so the line containing `index` is at the top (as far as the page allows). */
- (void)scrollCharacterIndexToTop:(NSUInteger)index;
@end

NS_ASSUME_NONNULL_BEGIN

@interface ManWindowController : NSWindowController <NSMenuDelegate, NSMenuItemValidation, NSTextViewDelegate, NSToolbarDelegate, NSToolbarItemValidation, NSWindowDelegate>
@property(nonatomic,retain) IBOutlet ManTextView *textView;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openSelection:(id)sender;
- (IBAction)displaySection:(id)sender;
- (IBAction)copyURL:(id)sender;
@end

NS_ASSUME_NONNULL_END
