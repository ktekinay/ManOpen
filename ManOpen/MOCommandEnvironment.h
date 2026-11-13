//
//  MOCommandEnvironment.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * Returns the environment for a man, apropos, or filter command run by ManOpen.
 *
 * ManOpen reads the output of man and apropos through a pipe, so it must not
 * depend on the user's pager settings. ManOpen inherits the environment of
 * whatever launched it; launched from a shell (directly, with open(1), or by
 * openman), that includes PAGER and friends. An interactive pager such as
 * pspg produces no output without a terminal, which made every page and
 * search come back empty.
 *
 * The result is a copy of `inherited` where:
 *   - MANPAGER, PAGER, and WHATISPAGER are set to "cat",
 *   - MANCOLOR is removed, so man(1) never pipes through "less -R",
 * and then every entry in `extra` (for example MANPATH) is added on top.
 * All other inherited variables are passed through unchanged.
 */
NSDictionary<NSString *, NSString *> *MOCommandEnvironment(NSDictionary<NSString *, NSString *> * _Nullable inherited,
                                                           NSDictionary<NSString *, NSString *> * _Nullable extra);

NS_ASSUME_NONNULL_END
