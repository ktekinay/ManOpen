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

/*
 * The same, calling `whenEnding` as the session ends but while the panel is
 * still open and modal, before any other window can become key. Anything
 * that must stop following the panel (such as an active color well) stops
 * there, so closing the panel can't change it.
 */
+ (MOModalPanelEnd)runPanel:(NSPanel *)panel whenEnding:(nullable void (^)(MOModalPanelEnd end))whenEnding;

/*
 * Runs the shared Font panel the same way, sending the changes chosen in it
 * to `target`'s changeFont: (M2). A modal session refuses actions from the
 * font manager to a target outside the panel, such as the Preferences
 * window, so the session passes them on itself.
 */
+ (MOModalPanelEnd)runFontPanelSendingChangesTo:(id<NSFontChanging>)target;
@end

/*
 * A color well that, when clicked, runs the Color panel modally. Cancel puts
 * back the color the well had, and the preference it edits as it was stored
 * (M3). Used for the Preferences color wells.
 */
@interface MOModalColorWell : NSColorWell

/*
 * While the panel is open, each color it gives the well is sent as the well's
 * action. The session is modal, so a target outside the panel must answer
 * YES to -worksWhenModal to receive it.
 */

/* The preference the well's owner stores its color in; restored on Cancel. nil: none. */
@property(nonatomic, copy, nullable) NSString *preferenceKey;
/* Where that preference is stored. Default: the standard user defaults, in the app's domain. */
@property(nonatomic, strong, null_resettable) NSUserDefaults *preferences;
@property(nonatomic, copy, null_resettable) NSString *preferencesDomain;

/* YES from the click until the session has ended and the color is settled. */
@property(nonatomic, readonly, getter=isRunningModal) BOOL runningModal;
/* Called once the session has ended and the color is settled. */
@property(nonatomic, copy, nullable) void (^sessionDidEnd)(MOModalColorWell *well);

@end

NS_ASSUME_NONNULL_END
