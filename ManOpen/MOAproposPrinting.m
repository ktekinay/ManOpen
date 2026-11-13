//
//  MOAproposPrinting.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOAproposPrinting.h"
#import "MOAproposTable.h"

const CGFloat MOAproposPrintFontSize = 10.0;
const CGFloat MOAproposPrintMarginExtra = 24.0;

CGFloat MOAproposPrintNameFraction(CGFloat screenNameWidth, CGFloat screenDescriptionWidth)
{
    CGFloat total = screenNameWidth + screenDescriptionWidth;
    CGFloat fraction = (total > 0.0) ? screenNameWidth / total : 0.3;

    return MIN(MAX(fraction, 0.20), 0.45);
}

static NSParagraphStyle *ColumnStyle(CGFloat nameColumnWidth, CGFloat spacingAfter)
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];

    style.tabStops = @[ [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:nameColumnWidth options:@{}] ];
    style.headIndent = nameColumnWidth; // wrapped description lines stay in the Description column
    style.paragraphSpacing = spacingAfter;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    return style;
}

static NSFont *BoldFont(NSFont *font)
{
    NSFontDescriptor *boldDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:NSFontDescriptorTraitBold];
    return [NSFont fontWithDescriptor:boldDescriptor size:font.pointSize] ?: font;
}

NSAttributedString *MOAproposPrintHeader(CGFloat nameColumnWidth, NSFont *font, NSString *nameTitle, NSString *descriptionTitle)
{
    NSDictionary *attributes = @{ NSFontAttributeName: BoldFont(font),
                                  NSForegroundColorAttributeName: [NSColor blackColor],
                                  NSParagraphStyleAttributeName: ColumnStyle(nameColumnWidth, 0.0) };

    return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\t%@", nameTitle, descriptionTitle]
                                           attributes:attributes];
}

NSAttributedString *MOAproposPrintText(NSArray<NSDictionary<NSString *, NSString *> *> *rows,
                                       CGFloat nameColumnWidth,
                                       NSFont *font)
{
    CGFloat rowSpacing = round(font.pointSize * 0.3);
    CGFloat gap = font.pointSize; // minimum space between a name and its description
    NSColor *black = [NSColor blackColor];

    NSDictionary *rowAttributes = @{ NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: black,
                                     NSParagraphStyleAttributeName: ColumnStyle(nameColumnWidth, rowSpacing) };
    NSDictionary *measureAttributes = @{ NSFontAttributeName: font };

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];

    for (NSDictionary<NSString *, NSString *> *row in rows)
    {
        NSString *name = row[MOAproposNameKey] ?: @"";
        NSString *description = row[MOAproposDescriptionKey] ?: @"";

        // Each row is one paragraph, so pagination can keep it together. A name too wide for
        // its column ends with a line separator; the description's line starts at the
        // paragraph's head indent, which is the Description column.
        NSString *separator = ([name sizeWithAttributes:measureAttributes].width > nameColumnWidth - gap) ? @"\u2028" : @"\t";

        [text appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@%@\n", name, separator, description]
                                                                      attributes:rowAttributes]];
    }

    return text;
}

@interface MOAproposPrintView ()
@property(nonatomic, strong) NSTextStorage *ownedTextStorage; // the text system doesn't retain its storage
@end

@implementation MOAproposPrintView

- (instancetype)initWithText:(NSAttributedString *)text width:(CGFloat)width
{
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:text];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:NSMakeSize(width, CGFLOAT_MAX)];

    container.widthTracksTextView = YES;
    container.lineFragmentPadding = 0.0;
    [layoutManager addTextContainer:container];
    [storage addLayoutManager:layoutManager];

    self = [super initWithFrame:NSMakeRect(0.0, 0.0, width, 100.0) textContainer:container];
    if (self)
    {
        _ownedTextStorage = storage;
        self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        self.drawsBackground = NO;
        self.editable = NO;
        self.verticallyResizable = YES;
        self.horizontallyResizable = NO;
        self.maxSize = NSMakeSize(width, CGFLOAT_MAX);
        [self sizeToFit];
    }
    return self;
}

/* Moves a page break that would split a row (one paragraph) to just above that row, so the
   row starts on the next page. A row taller than a whole page is split anyway, so it starts
   where it falls instead of leaving a mostly empty page behind. */
- (void)adjustPageHeightNew:(CGFloat *)newBottom top:(CGFloat)oldTop bottom:(CGFloat)proposedBottom limit:(CGFloat)bottomLimit
{
    [super adjustPageHeightNew:newBottom top:oldTop bottom:proposedBottom limit:bottomLimit];

    NSLayoutManager *layoutManager = self.layoutManager;
    NSTextContainer *container = self.textContainer;
    NSString *string = self.textStorage.string;
    CGFloat originY = self.textContainerOrigin.y;
    CGFloat bottom = *newBottom;

    if (layoutManager == nil || string.length == 0)
        return;

    // The row whose text sits just below the proposed break.
    NSUInteger glyph = [layoutManager glyphIndexForPoint:NSMakePoint(1.0, bottom - originY + 0.5) inTextContainer:container];
    NSUInteger character = [layoutManager characterIndexForGlyphAtIndex:glyph];
    if (character >= string.length)
        return;

    NSRange row = [string paragraphRangeForRange:NSMakeRange(character, 0)];
    NSRange rowGlyphs = [layoutManager glyphRangeForCharacterRange:row actualCharacterRange:NULL];
    NSRect rowRect = [layoutManager boundingRectForGlyphRange:rowGlyphs inTextContainer:container];
    CGFloat rowTop = NSMinY(rowRect) + originY;
    CGFloat rowBottom = NSMaxY(rowRect) + originY;

    BOOL fitsOnAPage = (rowBottom - rowTop) <= (proposedBottom - oldTop);

    if (rowTop < bottom && rowBottom > bottom && rowTop > oldTop && rowTop >= bottomLimit && fitsOnAPage)
        *newBottom = rowTop;
}

/* Called once per page while printing, with the view temporarily sized to the whole sheet. */
- (void)drawPageBorderWithSize:(NSSize)size
{
    [super drawPageBorderWithSize:size];

    NSPrintOperation *operation = [NSPrintOperation currentOperation];
    NSPrintInfo *printInfo = operation.printInfo;
    CGFloat left = printInfo.leftMargin;
    CGFloat width = size.width - left - printInfo.rightMargin;
    BOOL flipped = [NSGraphicsContext currentContext].isFlipped; // the page border isn't drawn in the view's own (flipped) coordinates

    if (self.headerText != nil)
    {
        CGFloat height = ceil([self.headerText boundingRectWithSize:NSMakeSize(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin].size.height);
        CGFloat gap = 6.0; // between the header's rule and the first row
        CGFloat bodyTop = flipped ? printInfo.topMargin : size.height - printInfo.topMargin;
        CGFloat headerY = flipped ? bodyTop - gap - height : bodyTop + gap;
        CGFloat ruleY = flipped ? bodyTop - gap / 2.0 : bodyTop + gap / 2.0;

        [self.headerText drawWithRect:NSMakeRect(left, headerY, width, height) options:NSStringDrawingUsesLineFragmentOrigin];

        [[NSColor blackColor] setFill];
        NSRectFill(NSMakeRect(left, ruleY - 0.25, width, 0.5));
    }

    NSDictionary *numberAttributes = @{ NSFontAttributeName: [NSFont systemFontOfSize:MOAproposPrintFontSize],
                                        NSForegroundColorAttributeName: [NSColor blackColor] };
    NSString *pageNumber = [NSString stringWithFormat:@"%ld", (long)operation.currentPage];
    NSSize numberSize = [pageNumber sizeWithAttributes:numberAttributes];
    CGFloat numberMiddle = printInfo.bottomMargin / 2.0;
    CGFloat numberY = flipped ? size.height - numberMiddle - numberSize.height / 2.0 : numberMiddle - numberSize.height / 2.0;

    [pageNumber drawAtPoint:NSMakePoint((size.width - numberSize.width) / 2.0, numberY) withAttributes:numberAttributes];
}

@end
