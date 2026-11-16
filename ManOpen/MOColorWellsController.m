//
//  MOColorWellsController.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/16/26.
//

#import "MOColorWellsController.h"

static void *MOStoredColorsContext = &MOStoredColorsContext;
static void *MOApplicationAppearanceContext = &MOApplicationAppearanceContext;

@implementation MOColorWellsController
{
    NSUserDefaults *_defaults;
    NSArray<MOModalColorWell *> *_wells; // indexed by MOColorSetting
    BOOL _followsApplication;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults domain:(NSString *)domain
                        textWell:(MOModalColorWell *)textWell
                        linkWell:(MOModalColorWell *)linkWell
                  backgroundWell:(MOModalColorWell *)backgroundWell
{
    self = [super init];
    if (self)
    {
        _defaults = defaults;
        _wells = @[ textWell, linkWell, backgroundWell ];
        _appearance = MOColorAppearanceOf(NSApp.effectiveAppearance);

        __weak MOColorWellsController *weakSelf = self;
        for (MOModalColorWell *well in _wells)
        {
            well.preferences = defaults;
            well.preferencesDomain = domain;
            well.target = self;
            well.action = @selector(wellChanged:);
            well.sessionDidEnd = ^(MOModalColorWell *well) {
                [weakSelf updateWells];
            };
        }
        for (NSString *key in MOAllColorKeys())
            [defaults addObserver:self forKeyPath:key options:0 context:MOStoredColorsContext];
        [self updateWells];
    }
    return self;
}

- (void)dealloc
{
    for (NSString *key in MOAllColorKeys())
        [_defaults removeObserver:self forKeyPath:key context:MOStoredColorsContext];
    if (_followsApplication)
        [NSApp removeObserver:self forKeyPath:@"effectiveAppearance" context:MOApplicationAppearanceContext];
}

- (void)setAppearance:(MOColorAppearance)appearance
{
    if (appearance == _appearance)
        return;
    _appearance = appearance;
    [self updateWells];
}

- (void)followApplicationAppearance
{
    if (_followsApplication)
        return;
    _followsApplication = YES;
    [NSApp addObserver:self forKeyPath:@"effectiveAppearance" options:NSKeyValueObservingOptionInitial context:MOApplicationAppearanceContext];
}

- (void)restoreDefaultColors
{
    MORestoreDefaultColors(_defaults, self.appearance); // the wells follow through observing
}

/* Each well shows, and edits, the setting for the current appearance; one with its panel open is left alone. */
- (void)updateWells
{
    for (MOColorSetting setting = MOColorSettingText; setting <= MOColorSettingBackground; setting++)
    {
        MOModalColorWell *well = _wells[setting];
        if (well.isRunningModal)
            continue;
        well.preferenceKey = MOColorKey(setting, self.appearance);
        NSColor *color = MOColorForSetting(_defaults, setting, self.appearance);
        if (![well.color isEqual:color])
            well.color = color;
    }
}

/* The wells' actions arrive while their Color panel is modal. */
- (BOOL)worksWhenModal
{
    return YES;
}

/* A color chosen in a well, stored under the key the well is editing. */
- (void)wellChanged:(MOModalColorWell *)well
{
    NSString *key = well.preferenceKey;
    NSColor *color = well.color;
    if (key == nil || color == nil || MOIsManPageColor(color)) // never store a page's own color (B18)
        return;
    NSData *data = MODataFromColor(color);
    if (data != nil && ![[_defaults objectForKey:key] isEqual:data])
        [_defaults setObject:data forKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    if (context == MOStoredColorsContext)
        [self updateWells];
    else if (context == MOApplicationAppearanceContext)
        self.appearance = MOColorAppearanceOf(NSApp.effectiveAppearance);
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
