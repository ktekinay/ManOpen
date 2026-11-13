//
//  MORestorationState.h
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//
//  Decoding and validation of the window-restoration state that ManDocument
//  and AproposDocument save, kept separate from the documents so it can be
//  unit tested.
//
//  Apps built with the macOS 14 SDK or later get secure coding for restorable
//  state, so every value must be decoded with an explicit list of classes.
//  The keys and the shape of the data are unchanged from earlier versions, so
//  state saved by older builds still restores.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* ManDocument: one dictionary, stored under MORestoreWindowInfoKey, holding either
   Name (+ optional Section and Title) for a page opened by name, or
   URL + DocType for a page opened from a file. */
extern NSString * const MORestoreWindowInfoKey;
extern NSString * const MORestoreNameKey;
extern NSString * const MORestoreSectionKey;
extern NSString * const MORestoreTitleKey;
extern NSString * const MORestoreFileURLKey;
extern NSString * const MORestoreFileTypeKey;

/* AproposDocument: two strings stored directly in the coder. */
extern NSString * const MORestoreSearchStringKey;
extern NSString * const MORestoreAproposTitleKey;

/*
 * Checks a decoded ManDocument restoration dictionary and returns a clean copy,
 * or nil if it can't be used. A usable dictionary is either:
 *   - by name: Name is a non-empty string; Section and Title are strings if
 *     present. A missing Title is replaced with the Name.
 *   - from a file: URL is a file URL and DocType is one of man, mangz, cat, catgz.
 * Any value of an unexpected type makes the whole dictionary unusable.
 * Unknown keys are dropped.
 */
NSDictionary<NSString *, id> * _Nullable MOValidatedManPageRestoreInfo(id _Nullable object);

/*
 * Decodes and validates ManDocument's restoration dictionary from `coder`.
 * Returns nil if it's missing, can't be decoded with the allowed classes
 * (NSDictionary, NSString, NSURL), or isn't valid. Never throws.
 */
NSDictionary<NSString *, id> * _Nullable MODecodeManPageRestoreInfo(NSCoder *coder);

/*
 * Decodes and validates AproposDocument's restoration state from `coder`.
 * Returns a dictionary with MORestoreSearchStringKey (a string, possibly empty,
 * which means "all pages") and MORestoreAproposTitleKey (the search string if
 * no title was saved), or nil if there's no usable search string. Never throws.
 */
NSDictionary<NSString *, NSString *> * _Nullable MODecodeAproposRestoreInfo(NSCoder *coder);

NS_ASSUME_NONNULL_END
