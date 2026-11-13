//
//  MOManPath.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * Builds the man path ManOpen passes to man and apropos from the directories
 * listed in Preferences.
 *
 * The directories are joined with ":" in order, and the result always ends
 * with an empty entry (a trailing ":"). man(1) replaces an empty entry with
 * its own default search path, so pages that Terminal finds without a MANPATH
 * are found too, after the listed directories. That matters on current macOS,
 * where the C library pages (sections 2 and 3, such as printf(3)) are
 * installed only in the Xcode or Command Line Tools SDK, which man adds to its
 * default path on its own.
 *
 * Empty entries in `directories` are skipped. An empty or nil list returns ":",
 * which means man's default path alone.
 */
NSString *MOManPathFromDirectories(NSArray<NSString *> * _Nullable directories);

NS_ASSUME_NONNULL_END
