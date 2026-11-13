//
//  MOAppSelection.h
//  openman
//
//  Created by Kem Tekinay on 11/13/26.
//
//  Which copy of ManOpen openman talks to. Several copies with the same bundle
//  identifier can be installed (an old 2.x in /Applications, development
//  builds, ...); only 3.0 and later accept openman's requests.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* The first ManOpen version that accepts openman's requests. */
extern NSString * const MOMinimumCompatibleVersion; // @"3.0"

/* A copy of ManOpen: where it is and its CFBundleShortVersionString. */
@interface MOAppCandidate : NSObject
@property(nonatomic, readonly) NSURL *url;
@property(nonatomic, readonly, nullable) NSString *version;
+ (instancetype)candidateWithURL:(NSURL *)url version:(nullable NSString *)version;
@end

/* YES if `version` is MOMinimumCompatibleVersion or later (numeric comparison). */
BOOL MOIsCompatibleVersion(NSString * _Nullable version);

/*
 * The app bundle that contains an executable, given the executable's real path
 * (symlinks already resolved): ".../X.app" for ".../X.app/Contents/...".
 * nil if the path isn't inside an app bundle.
 */
NSURL * _Nullable MOEnclosingAppBundle(NSString *resolvedExecutablePath);

/*
 * The copy of ManOpen to launch:
 *   1. `ownApp`, the app this openman is embedded in, if it's compatible;
 *   2. otherwise the compatible candidate with the highest version, preferring
 *      /Applications, then ~/Applications (`homeDirectory`), then anywhere else,
 *      then the order Launch Services listed them in;
 *   3. nil if no copy is compatible. An incompatible copy is never chosen.
 */
NSURL * _Nullable MOChooseManOpenApp(MOAppCandidate * _Nullable ownApp,
                                     NSArray<MOAppCandidate *> *candidates,
                                     NSString *homeDirectory);

NS_ASSUME_NONNULL_END
