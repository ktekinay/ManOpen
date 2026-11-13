//
//  MOReopenPolicy.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOReopenPolicy.h"

// Long enough for a page requested while ManOpen is brought forward to arrive
// first; short enough not to feel slow after a Dock click. Launching takes
// longer to settle (openman waits for ManOpen's message port), so it waits more.
const NSTimeInterval MOTitlePanelReopenDelay = 0.3;
const NSTimeInterval MOTitlePanelLaunchDelay = 0.6;

@implementation MOWindowState

+ (instancetype)windowOfKind:(MOWindowKind)kind visible:(BOOL)visible minimized:(BOOL)minimized
{
    MOWindowState *state = [[self alloc] init];
    state->_kind = kind;
    state->_visible = visible;
    state->_minimized = minimized;
    return state;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ kind %ld%@%@>", self.class, (long)self.kind,
            self.visible ? @" visible" : @"", self.minimized ? @" minimized" : @""];
}

@end

static BOOL Counts(MOWindowState *window)
{
    return window.kind == MOWindowKindDocument || window.kind == MOWindowKindPanel;
}

MOReopenDecision MODecideReopen(NSArray<MOWindowState *> *windows)
{
    for (NSUInteger i = 0; i < windows.count; i++)
    {
        if (Counts(windows[i]) && windows[i].visible)
            return (MOReopenDecision){ MOReopenActionBringForward, i };
    }
    for (NSUInteger i = 0; i < windows.count; i++)
    {
        if (windows[i].kind == MOWindowKindDocument && windows[i].minimized)
            return (MOReopenDecision){ MOReopenActionRestoreMinimized, i };
    }
    return (MOReopenDecision){ MOReopenActionNoWindows, NSNotFound };
}

BOOL MOHasManOpenWindows(NSArray<MOWindowState *> *windows)
{
    return MODecideReopen(windows).action != MOReopenActionNoWindows;
}

BOOL MOShouldOpenDelayedTitlePanel(BOOL appIsActive, NSArray<MOWindowState *> *windows)
{
    return appIsActive && !MOHasManOpenWindows(windows);
}
