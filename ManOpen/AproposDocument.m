/* AproposDocument.m created by lindberg on Tue 10-Oct-2000 */

#import "AproposDocument.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"
#import "PrefPanelController.h"
#import "MORestorationState.h"
#import "MOAproposTable.h"
#import "MOAproposPrinting.h"

/* Preferences for the results table. (NSTableView's own autosave isn't used: it
   restored saved column orders, and Name must always be first.) */
static NSString * const AproposNameWidthKey = @"AproposNameColumnWidth";
static NSString * const AproposSortKeyKey = @"AproposSortKey";
static NSString * const AproposSortAscendingKey = @"AproposSortAscending";

/* Posted by an Apropos window after the user changes the Name width or the sort,
   so every other open Apropos window applies the same settings right away. */
static NSString * const AproposTableSettingsDidChangeNotification = @"MOAproposTableSettingsDidChange";

static NSArray<NSSortDescriptor *> *SavedSortDescriptors(void)
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL ascending = ([defaults objectForKey:AproposSortAscendingKey] == nil) ? YES : [defaults boolForKey:AproposSortAscendingKey];

    return MOAproposSortDescriptors([defaults stringForKey:AproposSortKeyKey], ascending);
}

@interface AproposDocument () <NSTableViewDelegate>
@property(nonatomic) BOOL adjustingColumns; // YES while ManOpen itself sizes the columns
@property(nonatomic) BOOL applyingSavedSort; // YES while ManOpen itself sets the sort (not a header click)
@property(nonatomic,retain) NSString *searchString;
@property(nonatomic,retain) NSString *title;
@property(nonatomic,retain) NSMutableArray<NSDictionary<NSString *, NSString *> *> *titlesAndDescriptions; // duplicates are removed by MOAproposRowsFromOutput()
@end

@implementation AproposDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (void)_loadWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)aTitle
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSMutableString *command = [docController manCommandWithManPath:manPath];
    NSData *output;
    
    self.titlesAndDescriptions = [[NSMutableArray alloc] init];
	self.title = aTitle;
    [self setFileType:@"apropos"];

    /* Searching for a blank string doesn't work anymore... use a catchall regex */
    if ([apropos length] == 0)
        apropos = @".";
	self.searchString = apropos;

    /*
     * Starting on Tiger, man -k doesn't quite work the same as apropos directly.
     * Use apropos then, even on Panther.  Panther/Tiger no longer accept the -M
     * argument, so don't try... we set the MANPATH environment variable, which
     * gives a warning on Panther (stderr; ignored) but not on Tiger.
     */
//    [command appendString:@" -k"];
    [command setString:@"/usr/bin/apropos"];
    
    [command appendFormat:@" %@", EscapePath(apropos, YES)];
    output = [docController dataByExecutingCommand:command manPath:manPath];
    /* The whatis database appears to not be UTF8 -- at least, UTF8 can fail, even on 10.7 */
	[self parseOutput:[[NSString alloc] initWithData:output encoding:NSASCIIStringEncoding]];
}

- (instancetype)initWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)aTitle
{
	self = [super init];
	if (self)
	{
		[self _loadWithString:apropos manPath:manPath title:aTitle];
		
        if (self.titlesAndDescriptions.count == 0)
        {
            NSAlert *nothingFoundAlert = [[NSAlert alloc] init];
            
            nothingFoundAlert.messageText = NSLocalizedString(@"Nothing found", @"Title of an unsuccessful apropos search");
            nothingFoundAlert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"No pages related to '%@' found", @"Body of an unsuccessful apropos search"), apropos];
            (void)[nothingFoundAlert runModal];
			return nil;
		}
	}
    return self;
}


- (NSString *)windowNibName
{
    return @"Apropos";
}

- (NSString *)displayName
{
    return self.title;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    NSString *sizeString = [[NSUserDefaults standardUserDefaults] stringForKey:@"AproposWindowSize"];
    NSWindow *window = self.tableView.window;
    NSSize minimumContentSize = NSMakeSize(MOAproposMinimumContentWidth, MOAproposMinimumContentHeight);

    [super windowControllerDidLoadNib:windowController];

    window.contentMinSize = minimumContentSize;

    if (sizeString != nil)
    {
        NSSize windowSize = NSSizeFromString(sizeString);
        NSSize minimumFrameSize = [window frameRectForContentRect:NSMakeRect(0.0, 0.0, minimumContentSize.width, minimumContentSize.height)].size;
        NSRect frame = [window frame];

        if (windowSize.width > 30.0 && windowSize.height > 30.0) {
            frame.size.width = MAX(windowSize.width, minimumFrameSize.width);
            frame.size.height = MAX(windowSize.height, minimumFrameSize.height);
            [window setFrame:frame display:NO];
        }
    }

    self.tableView.target = self;
    self.tableView.doubleAction = @selector(openManPages:);
    self.tableView.delegate = self;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:window];
    [center addObserver:self selector:@selector(tableSettingsDidChange:) name:AproposTableSettingsDidChangeNotification object:nil];

    [self applySavedTableSettings];
}

/* Applies the saved sort and Name width, at load and when another Apropos window changes them. */
- (void)applySavedTableSettings
{
    NSArray<NSSortDescriptor *> *saved = SavedSortDescriptors();
    NSSortDescriptor *current = self.tableView.sortDescriptors.firstObject;

    if (current == nil || ![current.key isEqualToString:saved.firstObject.key] || current.ascending != saved.firstObject.ascending)
    {
        self.applyingSavedSort = YES;
        self.tableView.sortDescriptors = saved; // re-sorts through tableView:sortDescriptorsDidChange:
        self.applyingSavedSort = NO;
    }

    [self applyNameColumnWidth];
}

- (void)tableSettingsDidChange:(NSNotification *)notification
{
    if (notification.object != self)
        [self applySavedTableSettings];
}

/* Name keeps its saved width (clamped so Description stays usable); Description fills the rest. */
- (void)applyNameColumnWidth
{
    NSTableView *table = self.tableView;
    NSTableColumn *nameColumn = [table tableColumnWithIdentifier:MOAproposNameKey];
    NSTableColumn *descriptionColumn = [table tableColumnWithIdentifier:MOAproposDescriptionKey];

    if (nameColumn == nil || descriptionColumn == nil)
        return;

    CGFloat available = NSWidth(table.enclosingScrollView.contentView.bounds) - table.intercellSpacing.width * table.numberOfColumns;
    CGFloat saved = [[NSUserDefaults standardUserDefaults] doubleForKey:AproposNameWidthKey];

    self.adjustingColumns = YES;
    nameColumn.maxWidth = MAX(nameColumn.minWidth, available - descriptionColumn.minWidth); // dragging can't squeeze Description below its minimum
    nameColumn.width = MOAproposNameColumnWidth(available, saved, nameColumn.minWidth, descriptionColumn.minWidth);
    [table sizeLastColumnToFit];
    self.adjustingColumns = NO;
}

- (void)windowDidResize:(NSNotification *)notification
{
    [self applyNameColumnWidth];
}

/* NSTableViewDelegate: remember the Name width when the user drags the divider. */
- (void)tableViewColumnDidResize:(NSNotification *)notification
{
    NSTableColumn *column = notification.userInfo[@"NSTableColumn"];

    if (self.adjustingColumns || ![column.identifier isEqualToString:MOAproposNameKey])
        return;

    [[NSUserDefaults standardUserDefaults] setDouble:column.width forKey:AproposNameWidthKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:AproposTableSettingsDidChangeNotification object:self];
}

- (void)parseOutput:(NSString *)output
{
    self.titlesAndDescriptions = MOAproposRowsFromOutput(output);
    [self.titlesAndDescriptions sortUsingDescriptors:SavedSortDescriptors()];
}

- (IBAction)saveCurrentWindowSize:(id)sender
{
    NSSize size = self.tableView.window.frame.size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(size) forKey:@"AproposWindowSize"];
}

- (IBAction)openManPages:(id)sender
{
    if (sender == self.tableView)
    {
        NSInteger clickedRow = self.tableView.clickedRow;
        
        if (clickedRow >= 0L)
        {
            NSDictionary *titleAndDescription = self.titlesAndDescriptions[clickedRow];
            NSString *manPage = titleAndDescription[MOAproposNameKey];
            
            [[ManDocumentController sharedDocumentController] openString:manPage oneWordOnly:YES];
        }
    }
}

/* Prints the results as two text columns (not a picture of the table), so long descriptions
   wrap, no line is cut at a page break, and the text is black whatever the appearance. */
- (void)printDocumentWithSettings:(NSDictionary<NSPrintInfoAttributeKey,id> *)printSettings showPrintPanel:(BOOL)showPrintPanel delegate:(id)delegate didPrintSelector:(SEL)didPrintSelector contextInfo:(void *)contextInfo
{
    NSPrintInfo *printInfo = [self.printInfo copy];
    [printInfo.dictionary addEntriesFromDictionary:printSettings];
    printInfo.horizontalPagination = NSPrintingPaginationModeFit;
    printInfo.verticalPagination = NSPrintingPaginationModeAutomatic;
    printInfo.verticallyCentered = NO;
    // Room for the column header repeated on every page. Top and bottom are kept equal: for a
    // flipped view like NSTextView, AppKit places the body using the bottom margin at the top.
    CGFloat margin = MAX(printInfo.topMargin, printInfo.bottomMargin) + MOAproposPrintMarginExtra;
    printInfo.topMargin = margin;
    printInfo.bottomMargin = margin;

    CGFloat width = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin;
    NSTableColumn *nameColumn = [self.tableView tableColumnWithIdentifier:MOAproposNameKey];
    NSTableColumn *descriptionColumn = [self.tableView tableColumnWithIdentifier:MOAproposDescriptionKey];
    CGFloat nameWidth = round(width * MOAproposPrintNameFraction(nameColumn.width, descriptionColumn.width));

    NSFont *font = [NSFont systemFontOfSize:MOAproposPrintFontSize];
    NSAttributedString *text = MOAproposPrintText(self.titlesAndDescriptions, nameWidth, font);

    MOAproposPrintView *printView = [[MOAproposPrintView alloc] initWithText:text width:width];
    printView.headerText = MOAproposPrintHeader(nameWidth, font, nameColumn.headerCell.stringValue, descriptionColumn.headerCell.stringValue);

    NSPrintOperation *op = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
    op.jobTitle = self.displayName;
    [op setShowsPrintPanel:showPrintPanel];
    [op setShowsProgressPanel:showPrintPanel];
    [op runOperationModalForWindow:self.tableView.window delegate:nil didRunSelector:NULL contextInfo:NULL];
}

/* NSTableViewDelegate: no instant one-line expansion of cut-off cells; the tooltip below shows the text wrapped instead. */
- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

/* NSTableViewDelegate: when a cell's text is cut off, hovering shows all of it (wrapped). */
- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    NSSize fullSize = [cell cellSizeForBounds:NSMakeRect(0.0, 0.0, CGFLOAT_MAX, NSHeight(*rect))];

    return (fullSize.width > NSWidth(*rect)) ? cell.stringValue : nil;
}

/* NSTableView dataSource */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.titlesAndDescriptions.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return self.titlesAndDescriptions[row][tableColumn.identifier];
}

/* The sort changed: a header click, or applySavedTableSettings. Re-sort, keeping the selected row
   selected. Only a header click is saved and passed on to the other Apropos windows. */
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
    NSSortDescriptor *primary = tableView.sortDescriptors.firstObject;

    if (primary == nil)
        return;

    NSInteger selectedRow = tableView.selectedRow;
    NSDictionary *selected = (selectedRow >= 0 && selectedRow < (NSInteger)self.titlesAndDescriptions.count) ? self.titlesAndDescriptions[selectedRow] : nil;

    [self.titlesAndDescriptions sortUsingDescriptors:MOAproposSortDescriptors(primary.key, primary.ascending)];
    [tableView reloadData];

    if (selected != nil)
    {
        NSUInteger newRow = [self.titlesAndDescriptions indexOfObjectIdenticalTo:selected];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
        [tableView scrollRowToVisible:newRow];
    }

    if (!self.applyingSavedSort)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:primary.key forKey:AproposSortKeyKey];
        [defaults setBool:primary.ascending forKey:AproposSortAscendingKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:AproposTableSettingsDidChangeNotification object:self];
    }
}

/* Document restoration */
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.searchString forKey:MORestoreSearchStringKey];
    [coder encodeObject:self.title forKey:MORestoreAproposTitleKey];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    NSDictionary *restoreInfo = MODecodeAproposRestoreInfo(coder);

    if (restoreInfo == nil)
    {
        /* Nothing usable was saved; don't leave an empty window behind. */
        if (self.searchString == nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self close];
            });
        }
        return;
    }

    NSString *manPath = [[NSUserDefaults standardUserDefaults] manPath];

    [self _loadWithString:restoreInfo[MORestoreSearchStringKey] manPath:manPath title:restoreInfo[MORestoreAproposTitleKey]];
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
    [self.tableView reloadData];
}

@end
