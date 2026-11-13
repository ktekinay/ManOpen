//
//  MOReopenPolicy.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  What ManOpen does when it's reopened (a Dock click, or another app bringing
//  it forward) and when, if ever, the Title panel opens on its own. Plain
//  decisions over a description of the app's windows, so they can be tested
//  without AppKit.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MOWindowKind) {
    MOWindowKindDocument,   // a man page or Apropos window
    MOWindowKindPanel,      // one of ManOpen's own panels: Title, Apropos search, Help, Preferences
    MOWindowKindOther,      // anything else, such as the system Font and Color panels
};

@interface MOWindowState : NSObject
@property(nonatomic, readonly) MOWindowKind kind;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;
@property(nonatomic, readonly, getter=isMinimized) BOOL minimized;
+ (instancetype)windowOfKind:(MOWindowKind)kind visible:(BOOL)visible minimized:(BOOL)minimized;
@end

typedef NS_ENUM(NSInteger, MOReopenAction) {
    MOReopenActionBringForward,     // bring the window at `windowIndex` forward; no Title panel
    MOReopenActionRestoreMinimized, // restore the minimized window at `windowIndex`
    MOReopenActionNoWindows,        // no ManOpen windows: the Title panel may open (by preference, after a delay)
};

typedef struct {
    MOReopenAction action;
    NSUInteger windowIndex; // NSNotFound for MOReopenActionNoWindows
} MOReopenDecision;

/*
 * The reopen decision (Plans 1a.7, N1–N4). `windows` is front to back.
 *   - The frontmost visible document or ManOpen panel is brought forward (N1, N2).
 *   - Otherwise the frontmost minimized document window is restored (N3).
 *   - Otherwise there are no windows (N4). Windows of kind Other never count.
 */
MOReopenDecision MODecideReopen(NSArray<MOWindowState *> *windows);

/* Whether ManOpen has any window that counts (N1): a visible document or panel, or a minimized document. */
BOOL MOHasManOpenWindows(NSArray<MOWindowState *> *windows);

/*
 * Whether the delayed Title panel should open now, when its delay ends (N7):
 * only if ManOpen is still the active app and still has no windows.
 */
BOOL MOShouldOpenDelayedTitlePanel(BOOL appIsActive, NSArray<MOWindowState *> *windows);

/* How long to wait before the Title panel opens on its own: after a reopen (N7), and at launch (N9). */
extern const NSTimeInterval MOTitlePanelReopenDelay;
extern const NSTimeInterval MOTitlePanelLaunchDelay;

NS_ASSUME_NONNULL_END
