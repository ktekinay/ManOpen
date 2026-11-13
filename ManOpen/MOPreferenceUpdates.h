//
//  MOPreferenceUpdates.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  Which preference changes update open man pages, and how; and batching of
//  rapid changes (Plans 1a.9, L1–L8).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, MOManPageUpdate) {
    MOManPageUpdateNone                 = 0,
    MOManPageUpdateRestyle              = 1 << 0, // font or colors: restyle the text in place (L1, L2)
    MOManPageUpdateRegenerateAll        = 1 << 1, // bold or italics: generate every page again (L3)
    MOManPageUpdateRegenerateNroffFiles = 1 << 2, // nroff command: generate pages opened from nroff files again (L4)
};

typedef NS_ENUM(NSInteger, MOManPageSource) {
    MOManPageSourceName,        // opened by name (man), or by section listing
    MOManPageSourceNroffFile,   // opened from a raw nroff (man) file, possibly gzipped
    MOManPageSourceCatFile,     // opened from a preformatted (cat) file, possibly gzipped
};

/* The preferences that affect open man pages. */
NSArray<NSString *> *MOObservedPreferenceKeys(void);

/* What a change to `key` means for open pages. Other settings, the man path among them, don't touch open pages (L5, L6). */
MOManPageUpdate MOUpdateForPreferenceKey(NSString *key);

/*
 * What one page needs, given the combined pending updates: Regenerate (which
 * also applies the current style) if the page is affected by a pending
 * regeneration, otherwise Restyle if pending, otherwise None.
 */
typedef NS_ENUM(NSInteger, MOManPageAction) {
    MOManPageActionNone,
    MOManPageActionRestyle,
    MOManPageActionRegenerate,
};
MOManPageAction MOActionForPage(MOManPageUpdate pending, MOManPageSource source);

/*
 * Batches rapid changes (L8): the first change starts a short wait; changes
 * during it are merged; when it ends, the handler runs once with all of them.
 * So the handler runs at most once per interval, and, as it reads the current
 * settings, the last value wins. Runs in every run loop mode, including while
 * a modal panel (such as the Font or Color panel from Preferences) is open.
 */
@interface MOChangeCoalescer : NSObject
- (instancetype)initWithInterval:(NSTimeInterval)interval handler:(void (^)(NSUInteger changes))handler NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)noteChanges:(NSUInteger)changes;
@end

/* L8: open pages update at most about 10 times per second. */
extern const NSTimeInterval MOPreferenceUpdateInterval;

NS_ASSUME_NONNULL_END
