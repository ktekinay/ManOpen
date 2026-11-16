//
//  MOColorWellsController.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/16/26.
//
//  The Text, Link and Background color wells in Preferences ▸ Appearance.
//  They show and edit the colors for the appearance ManOpen is in
//  (Plans 1a.13, C1–C4, C7).
//

#import <AppKit/AppKit.h>
#import "MOColorDefaults.h"
#import "MOModalPanel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MOColorWellsController : NSObject

/*
 * Drives the wells from `defaults` (stored in `domain`). Each well shows the
 * color for the current appearance: the one chosen there, or the system
 * default as it looks there (C2). A color chosen in a well is stored for that
 * appearance only (C3). The wells follow any change to the stored colors.
 */
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults domain:(NSString *)domain
                        textWell:(MOModalColorWell *)textWell
                        linkWell:(MOModalColorWell *)linkWell
                  backgroundWell:(MOModalColorWell *)backgroundWell NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/*
 * The appearance the wells show and edit. Setting it updates the wells (C4),
 * except one whose Color panel is open: that one keeps editing the appearance
 * it was opened in, and catches up when the panel closes.
 */
@property(nonatomic) MOColorAppearance appearance;

/* Keeps `appearance` matching the application's appearance, live (C4). */
- (void)followApplicationAppearance;

/* Restore Default Colors, for the current appearance only (C7). */
- (void)restoreDefaultColors;

@end

NS_ASSUME_NONNULL_END
