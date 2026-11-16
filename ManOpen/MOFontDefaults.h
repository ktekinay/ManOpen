//
//  MOFontDefaults.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/16/26.
//
//  The man page font stored in preferences: how it's read, its default, and
//  Restore Default Font (Plans 1a.14).
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/* Preference key for the man page font. */
extern NSString * const MOManFontKey;  // "ManFont"

/*
 * The font man pages use when none is chosen: the system's fixed-pitch font
 * (Menlo on current macOS, set system-wide by NSFixedPitchFont) at 12 pt.
 * It isn't stored, so it follows that system setting.
 */
NSFont *MODefaultManFont(void);

/* A stored font as Preferences writes it, "size PostScriptName" (for example
   "12.000000 Menlo-Regular"); nil if it isn't that or the font isn't installed. */
NSFont * _Nullable MOFontFromPreference(id _Nullable value);

/* The man page font in `defaults`: the stored one, or else the default. */
NSFont *MOManFont(NSUserDefaults *defaults);

/* "Restore Default Font": removes the stored font, so the default applies again (R2). */
void MORestoreDefaultFont(NSUserDefaults *defaults);

NS_ASSUME_NONNULL_END
