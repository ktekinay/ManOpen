
#import "ManDocument.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"
#import "PrefPanelController.h"
#import "NSData+Utils.h"
#import "ManWindowController.h"
#import "MORestorationState.h"
#import "MOManPagePrinting.h"
#import "MOManPageStyle.h"

@interface ManDocument ()
/* The command the page was generated from, before the cat2rtf filter. */
@property(nonatomic, copy) NSString *sourceCommand;
@end


@implementation ManDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (void)_loadDocumentWithName:(NSString *)name
                      section:(NSString *)section
                      manPath:(NSString *)manPath
                        title:(NSString *)title
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSMutableString *command = [docController manCommandWithManPath:manPath];
    
    [self setFileType:@"man"];
    [self setShortTitle:title];
    
    if (section && [section length] > 0)
    {
        [command appendFormat:@" %@", [section lowercaseString]];
        self.xManPageURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"x-man-page://%@/%@", section, title]];
    }
    else
    {
        self.xManPageURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"x-man-page://%@", title]];
    }
    
    self.restoreData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                   name,    MORestoreNameKey,
                   title,   MORestoreTitleKey,
                   section, MORestoreSectionKey,
                   nil];
    
    [command appendFormat:@" %@", name];
    
    [self loadCommand:command];
}

- (instancetype)initWithName:(NSString *)name
	section:(NSString *)section
	manPath:(NSString *)manPath
	title:(NSString *)title
{
    self = [super init];
	if (self)
		[self _loadDocumentWithName:name section:section manPath:manPath title:title];
    return self;
}


- (void)makeWindowControllers
{
    ManWindowController *controller = [[ManWindowController alloc] initWithWindowNibName:@"ManPage"];
    
    [self addWindowController:controller];
}

/*
 * Standard NSDocument method.  We only want to override if we aren't
 * representing an actual file.
 */
- (NSString *)displayName
{
    return ([self fileURL] != nil)? [super displayName] : [self shortTitle];
}

- (void)addSectionHeader:(NSString *)header range:(NSRange)range
{
    /* Make sure it is a header -- error text sometimes is not Courier, so it gets passed in here. */
    if ([header rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].length > 0 &&
        [header rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].length == 0)
    {
        NSString *label = header;
        int count = 1;

        /* Check for dups (e.g. lesskey(1) ) */
        while ([self.sections containsObject:label]) {
            count++;
            label = [NSString stringWithFormat:@"%@ [%d]", header, count];
        }

        [self.sections addObject:label];
        [self.sectionRanges addObject:[NSValue valueWithRange:range]];
    }
}

- (void)showData
{
	@autoreleasepool
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSTextStorage *storage = nil;
		NSFont        *manFont = [defaults manFont];
		NSColor       *linkColor = MOManPageLinkColor();
		NSColor       *textColor = MOManPageTextColor();
		NSColor       *backgroundColor = MOManPageBackgroundColor();
        ManWindowController *manWC = self.windowControllers.firstObject;
		
		if (manWC.textView == nil || self.hasLoaded) return;
		
		if ([self.taskData isRTFData])
		{
			storage = [[NSTextStorage alloc] initWithRTF:self.taskData documentAttributes:NULL];
		}
		else if (self.taskData != nil)
		{
			storage = [[NSTextStorage alloc] initWithHTML:self.taskData documentAttributes:NULL];
		}
		
		if (storage == nil)
			storage = [[NSTextStorage alloc] init];
		
		if ([[storage string] rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].length == 0)
		{
			[[storage mutableString] setString:@"\nNo manual entry."];
		}
		
		if (self.sections == nil) {
			self.sections = [[NSMutableArray alloc] init];
			self.sectionRanges = [[NSMutableArray alloc] init];
		}
		[self.sections removeAllObjects];
		[self.sectionRanges removeAllObjects];
		
		/* Find the section headings, then apply the user's font and colors */
		if (storage != nil)
		{
			NSUInteger currIndex = 0;
			
			while (currIndex < [storage length])
			{
				NSRange currRange;
				NSDictionary *attribs = [storage attributesAtIndex:currIndex effectiveRange:&currRange];
				NSFont       *font = [attribs objectForKey:NSFontAttributeName];
				
				/* We mark "sections" with Helvetica fonts */
				if (font != nil && ![[font familyName] isEqualToString:@"Courier"]) {
					[self addSectionHeader:[[storage string] substringWithRange:currRange] range:currRange];
				}
				currIndex = NSMaxRange(currRange);
			}
			
			@try
			{
				MOApplyManPageStyle(storage, manFont, textColor);
			}
			@catch (NSException *localException)
			{
				NSLog(@"Exception during formatting: %@", localException);
			}
			
			[manWC.textView.layoutManager replaceTextStorage:storage];
			[manWC.textView.window invalidateCursorRectsForView:manWC.textView];
		}
		
        manWC.textView.linkTextAttributes = MOManPageLinkAttributes(manWC.textView.linkTextAttributes, linkColor);
		[manWC.textView setBackgroundColor:backgroundColor];
        [manWC.textView.window.toolbar validateVisibleItems];
		
		/*
		 * The 10.7 document reloading stuff can cause the loading methods to be invoked more than
		 * once, and the second time through we have thrown away our raw data.  Probably indicates
		 * some overkill code elsewhere on my part, but putting in the hadLoaded guard to only
		 * avoid doing anything after we have loaded real data seems to help.
		 */
		if (self.taskData != nil)
			self.hasLoaded = YES;
		
		// no need to keep around rtf data
        self.taskData = nil;
	}
}

- (NSString *)filterCommand
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    /* HTML parser in tiger got slow... RTF is faster, and is usable now that it supports hyperlinks */
    //    NSString *tool = @"cat2html";
    NSString *tool = @"cat2rtf";
    NSString *command = [[NSBundle mainBundle] pathForResource:tool ofType:nil];

    command = EscapePath(command, YES);
    command = [command stringByAppendingString:@" -lH"]; // generate links, mark headers
    if ([defaults boolForKey:@"UseItalics"])
        command = [command stringByAppendingString:@" -i"];
    if (![defaults boolForKey:@"UseBold"])
        command = [command stringByAppendingString:@" -g"];

    return command;
}

- (void)loadCommand:(NSString *)command
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSString *fullCommand = [NSString stringWithFormat:@"%@ | %@", command, [self filterCommand]];
	
    self.sourceCommand = command;
    self.taskData = nil;
    self.taskData = [docController dataByExecutingCommand:fullCommand];

    [self showData];
}

- (void)loadManFile:(NSString *)filename isGzip:(BOOL)isGzip
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *nroffFormat = [defaults stringForKey:@"NroffCommand"];
    NSString *nroffCommand;
    BOOL     hasQuote = ([nroffFormat rangeOfString:@"'%@'"].length > 0);

    /* If Gzip, change the command into a filter of the output of gzcat.  I'm
       getting the feeling that the customizable nroff command is more trouble
       than it's worth, especially now that OSX uses the good version of gnroff */
    if (isGzip)
    {
        NSString *repl = hasQuote? @"'%@'" : @"%@";
        NSRange replRange = [nroffFormat rangeOfString:repl];
        if (replRange.length > 0) {
			NSMutableString *formatCopy = nroffFormat.mutableCopy;
            [formatCopy replaceCharactersInRange:replRange withString:@""];
            nroffFormat = [NSString stringWithFormat:@"/usr/bin/gzip -dc %@ | %@", repl, formatCopy];
        }
    }
    
    nroffCommand = [NSString stringWithFormat:nroffFormat, EscapePath(filename, !hasQuote)];
    [self loadCommand:nroffCommand];
}

- (void)loadCatFile:(NSString *)filename isGzip:(BOOL)isGzip
{
    NSString *binary = isGzip? @"/usr/bin/gzip -dc" : @"/bin/cat";
    [self loadCommand:[NSString stringWithFormat:@"%@ '%@'", binary, EscapePath(filename, NO)]];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error
{
    if ([type isEqual:@"man"])
        [self loadManFile:[url path] isGzip:NO];
    else if ([type isEqual:@"mangz"])
        [self loadManFile:[url path] isGzip:YES];
    else if ([type isEqual:@"cat"])
        [self loadCatFile:[url path] isGzip:NO];
    else if ([type isEqual:@"catgz"])
        [self loadCatFile:[url path] isGzip:YES];
    else {
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObject:@"Invalid document type" forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            *error = [NSError errorWithDomain:@"ManOpen" code:0 userInfo:errorDetail];
        return NO;
    }

    // strip extension twice in case it is a e.g. "1.gz" filename
    [self setShortTitle:[[[[url path] lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathExtension]];
    self.xManPageURL = url;
    
    self.restoreData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                   url,    MORestoreFileURLKey,
                   type,   MORestoreFileTypeKey,
                   nil];

    if (self.taskData == nil)
    {
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObject:@"Could not read manual data" forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            *error = [NSError errorWithDomain:@"ManOpen" code:0 userInfo:errorDetail];
        return NO;
    }

    return YES;
}

#pragma mark - Following preference changes (Plans 1a.9)

- (MOManPageSource)pageSource
{
    NSString *type = self.restoreData[MORestoreFileTypeKey];

    if (self.restoreData[MORestoreFileURLKey] == nil)
        return MOManPageSourceName;
    if ([type isEqualToString:@"cat"] || [type isEqualToString:@"catgz"])
        return MOManPageSourceCatFile;
    return MOManPageSourceNroffFile;
}

- (void)applyCurrentStyle
{
    ManWindowController *manWC = self.windowControllers.firstObject;
    ManTextView *textView = manWC.textView;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (textView == nil)
        return;

    NSUInteger top = [textView characterIndexAtTop];
    // The colors are the shared man page colors, which follow Preferences when drawn;
    // only the font needs an edit. A color change is just a redraw.
    BOOL fontsChanged = MOApplyManPageStyle(textView.textStorage, defaults.manFont, MOManPageTextColor());

    if (![textView.linkTextAttributes[NSForegroundColorAttributeName] isEqual:MOManPageLinkColor()])
        textView.linkTextAttributes = MOManPageLinkAttributes(textView.linkTextAttributes, MOManPageLinkColor());
    if (![textView.backgroundColor isEqual:MOManPageBackgroundColor()])
        textView.backgroundColor = MOManPageBackgroundColor();
    [textView setNeedsDisplay:YES];
    if (fontsChanged)
        [textView scrollCharacterIndexToTop:top];
}

- (void)reloadContent
{
    ManWindowController *manWC = self.windowControllers.firstObject;
    ManTextView *textView = manWC.textView;
    NSURL *fileURL = self.restoreData[MORestoreFileURLKey];
    NSString *fileType = self.restoreData[MORestoreFileTypeKey];

    if (fileURL == nil && self.sourceCommand == nil)
        return;

    NSString *oldText = [textView.string copy] ?: @"";
    NSUInteger oldTop = (textView != nil) ? [textView characterIndexAtTop] : 0;
    NSArray<NSString *> *oldSections = [self.sections copy] ?: @[];
    NSArray<NSValue *> *oldRanges = [self.sectionRanges copy] ?: @[];
    NSArray<NSValue *> *oldSelection = textView.selectedRanges;

    self.hasLoaded = NO;
    if (fileURL != nil)
        [self readFromURL:fileURL ofType:fileType error:NULL]; // builds the nroff command again from Preferences
    else
        [self loadCommand:self.sourceCommand];

    if (textView == nil)
        return;
    if ([textView.string isEqualToString:oldText] && oldSelection != nil)
        textView.selectedRanges = oldSelection;
    [textView scrollCharacterIndexToTop:MOAnchorAfterReload(oldText, oldTop, oldSections, oldRanges,
                                                            textView.string, self.sections ?: @[], self.sectionRanges ?: @[])];
}

/* Always use global page layout */
- (IBAction)runPageLayout:(id)sender
{
    [[NSApplication sharedApplication] runPageLayout:sender];
}

- (void)printDocumentWithSettings:(NSDictionary<NSPrintInfoAttributeKey,id> *)printSettings showPrintPanel:(BOOL)showPrintPanel delegate:(id)delegate didPrintSelector:(SEL)didPrintSelector contextInfo:(void *)contextInfo
{
    ManWindowController *manWC = self.windowControllers.firstObject;
    /* Print a separate light-appearance copy, so Dark Mode never reaches the paper
       and the window itself doesn't change. */
    NSTextView *printView = MOMakeManPagePrintView([ManTextView class], manWC.textView);
    NSPrintOperation *operation = [NSPrintOperation printOperationWithView:printView];
    NSPrintInfo      *printInfo = [operation printInfo];

    [printInfo setVerticallyCentered:NO];
    [printInfo setHorizontallyCentered:YES];
    [printInfo setHorizontalPagination:NSPrintingPaginationModeFit];
    [operation setShowsPrintPanel:showPrintPanel];
    [operation setShowsProgressPanel:showPrintPanel];

    [operation runOperationModalForWindow:manWC.window delegate:nil didRunSelector:NULL contextInfo:NULL];
}


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.restoreData forKey:MORestoreWindowInfoKey];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    NSDictionary *restoreInfo = MODecodeManPageRestoreInfo(coder);
    BOOL restored;

    if (restoreInfo[MORestoreNameKey] != nil)
    {
        NSString *manPath = [[NSUserDefaults standardUserDefaults] manPath];

        [self _loadDocumentWithName:restoreInfo[MORestoreNameKey]
                            section:restoreInfo[MORestoreSectionKey]
                            manPath:manPath
                              title:restoreInfo[MORestoreTitleKey]];
        restored = YES;
    }
    /* Usually, URL-backed documents have been automatically restored already
       (the xManPageURL would be set), but just in case... */
    else if (restoreInfo[MORestoreFileURLKey] != nil && self.xManPageURL == nil)
    {
        restored = [self readFromURL:restoreInfo[MORestoreFileURLKey] ofType:restoreInfo[MORestoreFileTypeKey] error:NULL];
    }
    else
    {
        restored = (self.xManPageURL != nil);
    }

    if (!restored)
    {
        /* Nothing usable was saved (missing or invalid state, state saved by a
           build that restored blank windows, or a file that no longer exists).
           Don't leave an empty, untitled "No manual entry" window behind;
           close it once restoration finishes. */
        dispatch_async(dispatch_get_main_queue(), ^{
            [self close];
        });
        return;
    }

    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

@end
