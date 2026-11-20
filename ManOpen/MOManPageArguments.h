//
//  MOManPageArguments.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/20/26.
//
//  The page name and section given to man(1), checked and quoted so each
//  reaches man as exactly one argument (Plans 6.0).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* The longest page name accepted. Real names are under 80 characters. */
extern const NSUInteger MOMaxManPageNameLength;

/*
 * YES for something that can be a page name: 1 to MOMaxManPageNameLength
 * characters from A–Z, a–z, 0–9 and . _ + : @ - [ (as in "c++",
 * "git-commit", "perl5.30", "Tcl_Eval", "DBIx::Class", ".rhosts" and "["),
 * not starting with "-", which man would take as an option.
 */
BOOL MOIsValidManPageName(NSString * _Nullable name);

/* YES for a section: 1 to 8 letters and digits ("1", "3pm", "n", "1ssl"). nil or empty means no section, which is also fine. */
BOOL MOIsValidManSection(NSString * _Nullable section);

/* `string` quoted for /bin/sh, so the shell passes it on as one argument, unchanged. */
NSString *MOShellQuoted(NSString *string);

/*
 * The arguments that ask man for a page: " 'section' 'name'", or " 'name'"
 * with no section. The section is lowercased, as man expects. nil if the name
 * or section isn't valid; then nothing should be run.
 */
NSString * _Nullable MOManPageArguments(NSString * _Nullable name, NSString * _Nullable section);

NS_ASSUME_NONNULL_END
