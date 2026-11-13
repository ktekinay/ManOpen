//
//  MOModalPanel.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  The Font and Color panels opened from Preferences are modal, with OK and
//  Cancel (Plans 1a.10, M1–M6, decision IQ7).
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/* How a modal panel was dismissed. */
typedef NS_ENUM(NSInteger, MOModalPanelEnd) {
    MOModalPanelEndOK,            // OK, or Return
    MOModalPanelEndCancel,        // Cancel, or Escape
    MOModalPanelEndCloseCommand,  // Command-W
    MOModalPanelEndClosed,        // closed some other way (for example, the app quitting)
};

/* Only OK keeps the choice; everything else restores the value from when the panel opened (M3, M3a). */
BOOL MOModalPanelEndKeepsChoice(MOModalPanelEnd end);

/*
 * A preference as stored when a panel opened: its stored value, or the fact
 * that nothing was stored (the registered default applied). Restoring puts
 * back exactly that, so cancelling never turns a system default into a fixed
 * value.
 */
@interface MOPreferenceSnapshot : NSObject
+ (instancetype)snapshotOfKey:(NSString *)key inDefaults:(NSUserDefaults *)defaults domain:(NSString *)domain;
@property(nonatomic, readonly, copy) NSString *key;
@property(nonatomic, readonly, nullable) id storedValue; // nil: nothing was stored
- (void)restoreInDefaults:(NSUserDefaults *)defaults;
@end

/*
 * Runs the shared Font or Color panel application-modally (M1) with OK and
 * Cancel buttons added below it (M3) and its close button hidden (M3a).
 * Return is OK; Escape is Cancel; Command-W and any other close count as
 * Cancel. Afterwards the panel is closed and its accessory view and close
 * button are put back, so other uses of the panel are modeless as usual (M5).
 */
@interface MOModalPanelSession : NSObject
+ (MOModalPanelEnd)runPanel:(NSPanel *)panel;
@end

/*
 * A color well that, when clicked, runs the Color panel modally. The well is
 * bound to a preference; Cancel restores that preference as it was stored
 * (M3). Used for the Preferences color wells.
 */
@interface MOModalColorWell : NSColorWell
@end

NS_ASSUME_NONNULL_END
