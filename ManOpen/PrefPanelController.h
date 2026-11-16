/* PrefPanelController.h created by lindberg on Fri 08-Oct-1999 */

#import <AppKit/AppKit.h>

@class MOModalColorWell, MOColorWellsController;

@interface PrefPanelController : NSWindowController <NSFontChanging, NSMenuItemValidation>
{
    NSMutableArray *manPathArray;
    IBOutlet NSArrayController *manPathController;
    IBOutlet NSTableView *manPathTableView;
    IBOutlet NSTextField *fontField;
    IBOutlet NSMatrix *generalSwitchMatrix;
    IBOutlet NSPopUpButton *appPopup;
    IBOutlet MOModalColorWell *textColorWell;
    IBOutlet MOModalColorWell *linkColorWell;
    IBOutlet MOModalColorWell *backgroundColorWell;
    MOColorWellsController *colorWells;
}

+ (id)sharedInstance;
+ (void)registerManDefaults;

- (IBAction)openFontPanel:(id)sender;
- (IBAction)restoreDefaultColors:(id)sender;
- (IBAction)restoreDefaultFont:(id)sender;

@end

@interface PrefPanelController (ManPath)
- (IBAction)addPathFromPanel:(id)sender;
@end
@interface PrefPanelController (DefaultManApp)
- (IBAction)chooseNewApp:(id)sender;
@end

@interface NSUserDefaults (ManOpenPreferences)
- (NSFont *)manFont;
- (NSString *)manPath;
@end

// This needs to be in the header so IB can find it
@interface DisplayPathFormatter : NSFormatter
@end
