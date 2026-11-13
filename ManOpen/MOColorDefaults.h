//
//  MOColorDefaults.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  The man page colors stored in preferences: how they're archived, their
//  defaults, and cleanup of old stored values.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/* Preference keys for the man page colors. */
extern NSString * const MOTextColorKey;        // "ManTextColor"
extern NSString * const MOLinkColorKey;        // "ManLinkColor"
extern NSString * const MOBackgroundColorKey;  // "ManBackgroundColor"
/* ManOpen 2.x names, still read as defaults when present. */
extern NSString * const MOLegacyTextColorKey;        // "TextColor"
extern NSString * const MOLegacyLinkColorKey;        // "LinkColor"
extern NSString * const MOLegacyBackgroundColorKey;  // "BackgroundColor"

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
 * the dynamic default applies. Any other stored color is kept. Call before
 * registering defaults.
 */
void MOMigrateColorDefaults(NSUserDefaults *defaults);

/* "Restore Default Colors": removes the stored text, link and background colors
   (current and 2.x keys), so the dynamic system defaults apply again. */
void MORestoreDefaultColors(NSUserDefaults *defaults);

NS_ASSUME_NONNULL_END
