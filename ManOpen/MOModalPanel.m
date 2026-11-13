//
//  MOModalPanel.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOModalPanel.h"

BOOL MOModalPanelEndKeepsChoice(MOModalPanelEnd end)
{
    return end == MOModalPanelEndOK;
}

#pragma mark - MOPreferenceSnapshot

@implementation MOPreferenceSnapshot

+ (instancetype)snapshotOfKey:(NSString *)key inDefaults:(NSUserDefaults *)defaults domain:(NSString *)domain
{
    MOPreferenceSnapshot *snapshot = [[self alloc] init];
    snapshot->_key = [key copy];
    snapshot->_storedValue = [defaults persistentDomainForName:domain][key];
    return snapshot;
}

- (void)restoreInDefaults:(NSUserDefaults *)defaults
{
    if (self.storedValue != nil)
        [defaults setObject:self.storedValue forKey:self.key];
    else
        [defaults removeObjectForKey:self.key];
}

@end

#pragma mark - The OK and Cancel buttons

@interface MOModalPanelAccessoryView : NSView
@property(nonatomic, copy) void (^onEnd)(MOModalPanelEnd end);
@end

@implementation MOModalPanelAccessoryView

- (instancetype)initWithWidth:(CGFloat)width
{
    self = [super initWithFrame:NSMakeRect(0.0, 0.0, width, 44.0)];
    if (self)
    {
        NSButton *ok = [NSButton buttonWithTitle:NSLocalizedString(@"OK", @"Button that keeps the choice in the Font or Color panel opened from Preferences")
                                          target:self action:@selector(ok:)];
        NSButton *cancel = [NSButton buttonWithTitle:NSLocalizedString(@"Cancel", @"Button that undoes the choice in the Font or Color panel opened from Preferences")
                                              target:self action:@selector(cancel:)];
        ok.keyEquivalent = @"\r";
        cancel.keyEquivalent = @"\e";
        ok.identifier = @"MOModalPanelOK";
        cancel.identifier = @"MOModalPanelCancel";

        CGFloat buttonWidth = MAX(MAX(NSWidth(ok.frame), NSWidth(cancel.frame)), 80.0);
        CGFloat x = width - 12.0 - buttonWidth;
        for (NSButton *button in @[ ok, cancel ])
        {
            button.frame = NSMakeRect(x, 8.0, buttonWidth, NSHeight(button.frame));
            button.autoresizingMask = NSViewMinXMargin;
            [self addSubview:button];
            x -= buttonWidth + 12.0;
        }
        self.autoresizingMask = NSViewWidthSizable;
    }
    return self;
}

- (void)ok:(id)sender
{
    self.onEnd(MOModalPanelEndOK);
}

- (void)cancel:(id)sender
{
    self.onEnd(MOModalPanelEndCancel);
}

/* Command-W cancels: the close button is hidden while the panel is modal. */
- (BOOL)performKeyEquivalent:(NSEvent *)event
{
    NSEventModifierFlags flags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    if (flags == NSEventModifierFlagCommand && [event.charactersIgnoringModifiers isEqualToString:@"w"])
    {
        self.onEnd(MOModalPanelEndCloseCommand);
        return YES;
    }
    return [super performKeyEquivalent:event];
}

@end

#pragma mark - MOModalPanelSession

@interface MOModalPanelSession ()
@property(nonatomic, strong) NSPanel *panel;
@property(nonatomic, assign) MOModalPanelEnd end;
@property(nonatomic, assign) BOOL ended;
@end

@implementation MOModalPanelSession

+ (MOModalPanelEnd)runPanel:(NSPanel *)panel
{
    MOModalPanelSession *session = [[self alloc] init];
    session.panel = panel;
    return [session run];
}

- (MOModalPanelEnd)run
{
    NSPanel *panel = self.panel;
    BOOL hasAccessory = [panel respondsToSelector:@selector(accessoryView)] && [panel respondsToSelector:@selector(setAccessoryView:)];
    NSView *previousAccessory = hasAccessory ? [(id)panel accessoryView] : nil;
    MOModalPanelAccessoryView *accessory = [[MOModalPanelAccessoryView alloc] initWithWidth:NSWidth(panel.contentView.frame)];
    NSButton *closeButton = [panel standardWindowButton:NSWindowCloseButton];
    BOOL closeButtonWasHidden = closeButton.hidden;
    __weak MOModalPanelSession *weakSelf = self;

    accessory.onEnd = ^(MOModalPanelEnd end) {
        [weakSelf endWith:end];
    };
    if (hasAccessory)
        [(id)panel setAccessoryView:accessory];
    closeButton.hidden = YES;

    // Any other close (for example the app quitting) counts as Cancel.
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:panel queue:nil
                                                                usingBlock:^(NSNotification *note) {
        [weakSelf endWith:MOModalPanelEndClosed];
    }];

    self.end = MOModalPanelEndClosed;
    [panel makeKeyAndOrderFront:nil];
    [NSApp runModalForWindow:panel];

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    if (panel.isVisible)
        [panel orderOut:nil];
    if (hasAccessory)
        [(id)panel setAccessoryView:previousAccessory];
    closeButton.hidden = closeButtonWasHidden;
    return self.end;
}

- (void)endWith:(MOModalPanelEnd)end
{
    if (self.ended)
        return;
    self.ended = YES;
    self.end = end;
    if (end == MOModalPanelEndOK)
        [self.panel makeFirstResponder:nil]; // finish an edit in progress, such as a typed font size or hex color
    [NSApp stopModal];
}

@end

#pragma mark - MOModalColorWell

@implementation MOModalColorWell
{
    BOOL _runningModal;
}

- (void)activate:(BOOL)exclusive
{
    [super activate:exclusive];
    if (_runningModal)
        return;
    _runningModal = YES;
    // Start the modal session after the click that activated the well is done.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self runModalColorPanel];
    });
}

/* The preference this well is bound to ("values.ManTextColor" → "ManTextColor"), if any. */
- (nullable NSString *)boundPreferenceKey
{
    NSString *path = [self infoForBinding:NSValueBinding][NSObservedKeyPathKey];
    return [path hasPrefix:@"values."] ? [path substringFromIndex:@"values.".length] : nil;
}

- (void)runModalColorPanel
{
    if (!self.isActive)
    {
        _runningModal = NO;
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [self boundPreferenceKey];
    NSString *domain = [NSBundle mainBundle].bundleIdentifier;
    MOPreferenceSnapshot *original = (key != nil && domain != nil) ? [MOPreferenceSnapshot snapshotOfKey:key inDefaults:defaults domain:domain] : nil;
    NSColor *originalColor = self.color;

    MOModalPanelEnd end = [MOModalPanelSession runPanel:[NSColorPanel sharedColorPanel]];

    [self deactivate]; // so later uses of the color panel don't change this preference (M5)
    if (!MOModalPanelEndKeepsChoice(end))
    {
        if (original != nil)
            [original restoreInDefaults:defaults]; // the binding shows it in the well
        else
            self.color = originalColor;
    }
    _runningModal = NO;
}

@end
