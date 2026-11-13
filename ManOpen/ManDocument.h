
#import <Cocoa/Cocoa.h>
#import "MOPreferenceUpdates.h"

@interface ManDocument : NSDocument

- (instancetype)initWithName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath title:(NSString *)title;

@property(nonatomic,retain) NSString *shortTitle;
@property(nonatomic,retain) NSData *taskData;
@property(nonatomic,assign) BOOL hasLoaded;
@property(nonatomic,retain) NSURL *xManPageURL;
@property(nonatomic,retain) NSMutableArray<NSString *> *sections;
@property(nonatomic,retain) NSMutableArray<NSValue *> *sectionRanges;
@property(nonatomic,retain) NSMutableDictionary<NSString *, NSString *> *restoreData;

- (void)loadCommand:(NSString *)command;

- (void)showData;

/* Where the page came from, which decides what a preference change does to it (Plans 1a.9). */
@property(nonatomic, readonly) MOManPageSource pageSource;
/* Applies the current font and colors from Preferences to the page in place, keeping the scroll position. */
- (void)applyCurrentStyle;
/* Generates the page again (for bold, italics or the nroff command), keeping the scroll position and selection. */
- (void)reloadContent;

@end
