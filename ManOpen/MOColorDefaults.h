//
//  MOColorDefaults.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  The man page colors stored in preferences: how they're archived, their
//  defaults, and cleanup of old stored values. Each color has a value for
//  Light Mode and one for Dark Mode (Plans 1a.13).
//

#import <AppKit/AppKit.h>
#import "MOManPageStyle.h"

NS_ASSUME_NONNULL_BEGIN

/* Preference keys for the man page colors. */
extern NSString * const MOTextColorKey;        // "ManTextColor"
extern NSString * const MOLinkColorKey;        // "ManLinkColor"
extern NSString * const MOBackgroundColorKey;  // "ManBackgroundColor"
/* ManOpen 2.x names, still read as the Light Mode color when the key above isn't stored. */
extern NSString * const MOLegacyTextColorKey;        // "TextColor"
extern NSString * const MOLegacyLinkColorKey;        // "LinkColor"
extern NSString * const MOLegacyBackgroundColorKey;  // "BackgroundColor"
/* The Dark Mode colors (C1). The keys above hold the Light Mode colors, which
   is what earlier versions still read (C10). */
extern NSString * const MOTextColorDarkKey;        // "ManTextColorDark"
extern NSString * const MOLinkColorDarkKey;        // "ManLinkColorDark"
extern NSString * const MOBackgroundColorDarkKey;  // "ManBackgroundColorDark"

/* The man page colors that can be chosen in Preferences. */
typedef NS_ENUM(NSInteger, MOColorSetting) {
    MOColorSettingText,
    MOColorSettingLink,
    MOColorSettingBackground,
};

/* Where a color chosen for `setting` in `appearance` is stored. */
NSString *MOColorKey(MOColorSetting setting, MOColorAppearance appearance);

/*
 * The color chosen for `setting` in `appearance`, or nil if none was: the
 * system default applies (C2). Light also reads the 2.x key. A stored copy of
 * a man page color counts as none (B18).
 */
NSColor * _Nullable MOStoredColor(NSUserDefaults *defaults, MOColorSetting setting, MOColorAppearance appearance);

/* The system default for `setting`: text, link or text background color. Each adapts to the appearance it's drawn in. */
NSColor *MODefaultColor(MOColorSetting setting);

/* What `setting` is in `appearance`: the chosen color, or the default. */
NSColor *MOColorForSetting(NSUserDefaults *defaults, MOColorSetting setting, MOColorAppearance appearance);

/* Every key a man page color is read from, current, 2.x and Dark. */
NSArray<NSString *> *MOAllColorKeys(void);

/* Decodes a stored color: a keyed archive, or ManOpen 2.x's NSArchiver format. nil if neither. */
NSColor * _Nullable MOColorFromData(NSData * _Nullable data);

/* Archives a color for storing in preferences. A system (dynamic) color stays dynamic. */
NSData * _Nullable MODataFromColor(NSColor * _Nullable color);

/* The default link color: the system link color, which adapts to Light Mode,
   Dark Mode and Increase Contrast. */
NSColor *MODefaultLinkColor(void);

/* YES for the fixed blue that earlier versions used as the default link color
   (device RGB 0.1, 0.1, 1.0), which is unreadable in Dark Mode. */
BOOL MOIsOldDefaultLinkColor(NSColor * _Nullable color);

/*
 * One-time cleanup at launch: a stored link color (current or 2.x key) that's
 * exactly the old default was never chosen by the user, so it's removed and
 * the dynamic default applies. So is a stored copy of one of the colors man
 * pages draw with (MOIsManPageColor), under any key, which was never a real
 * choice either. Any other stored color is kept. A color stored by an earlier
 * version is under the Light key, so it stays the Light color and Dark starts
 * at the defaults (C8); nothing needs moving.
 */
void MOMigrateColorDefaults(NSUserDefaults *defaults);

/* "Restore Default Colors" for one appearance (C7): removes the text, link and
   background colors stored for it (for Light, the 2.x keys too), so the
   dynamic system defaults apply again there. The other appearance's are kept. */
void MORestoreDefaultColors(NSUserDefaults *defaults, MOColorAppearance appearance);

NS_ASSUME_NONNULL_END
