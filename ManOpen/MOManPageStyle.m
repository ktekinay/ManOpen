//
//  MOManPageStyle.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOManPageStyle.h"

NSAttributedStringKey const MOOriginalFontAttributeName = @"MOOriginalFont";

BOOL MOApplyManPageStyle(NSMutableAttributedString *text, NSFont *font, NSColor *textColor)
{
    NSFontManager *manager = [NSFontManager sharedFontManager];
    NSString *family = font.familyName;
    CGFloat size = font.pointSize;
    NSRange all = NSMakeRange(0, text.length);
    // A page has only a handful of distinct fonts; convert each once.
    NSMutableDictionary<NSFont *, NSFont *> *converted = [NSMutableDictionary dictionary];
    __block BOOL fontsChanged = NO;

    [text beginEditing];
    [text enumerateAttributesInRange:all options:0 usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attributes, NSRange range, BOOL *stop) {
        NSFont *original = attributes[MOOriginalFontAttributeName] ?: attributes[NSFontAttributeName];
        if (original == nil)
            return;

        NSFont *newFont = converted[original];
        if (newFont == nil)
        {
            newFont = original;
            if (![newFont.familyName isEqualToString:family])
                newFont = [manager convertFont:newFont toFamily:family];
            if (newFont.pointSize != size)
                newFont = [manager convertFont:newFont toSize:size];
            converted[original] = newFont;
        }
        if (attributes[MOOriginalFontAttributeName] == nil)
            [text addAttribute:MOOriginalFontAttributeName value:original range:range];
        if (![attributes[NSFontAttributeName] isEqual:newFont])
        {
            fontsChanged = YES;
            [text addAttribute:NSFontAttributeName value:newFont range:range];
        }
    }];
    __block BOOL colorDiffers = NO;
    [text enumerateAttribute:NSForegroundColorAttributeName inRange:all options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (![value isEqual:textColor])
            colorDiffers = *stop = YES;
    }];
    if (colorDiffers)
        [text addAttribute:NSForegroundColorAttributeName value:textColor range:all];
    [text endEditing];
    return fontsChanged;
}

/* What each man page color draws as, by appearance; nil is the system default. */
typedef NS_ENUM(NSInteger, ManPageColor) { TextColor, LinkColor, BackgroundColor, ManPageColorCount };
static NSColor *Current[ManPageColorCount][2];

static NSString * const TextColorName = @"ManOpenTextColor";
static NSString * const LinkColorName = @"ManOpenLinkColor";
static NSString * const BackgroundColorName = @"ManOpenBackgroundColor";

MOColorAppearance MOColorAppearanceOf(NSAppearance *appearance)
{
    NSAppearanceName match = [appearance bestMatchFromAppearancesWithNames:@[ NSAppearanceNameAqua, NSAppearanceNameDarkAqua ]];
    return [match isEqualToString:NSAppearanceNameDarkAqua] ? MOColorAppearanceDark : MOColorAppearanceLight;
}

/* How many man page colors this thread is resolving right now. */
static _Thread_local NSUInteger Resolving;

/* A color that draws as the current setting for `which` (or `fallback`), resolved in the appearance it's drawn in. */
static NSColor *FollowingColor(NSString *name, ManPageColor which, NSColor *(^fallback)(void))
{
    return [NSColor colorWithName:name dynamicProvider:^NSColor *(NSAppearance *appearance) {
        NSColor *chosen = Current[which][MOColorAppearanceOf(appearance)];
        // A man page color that leads back to a man page color would never
        // finish resolving (B18), so the inner one draws as its default.
        NSColor *color = (Resolving == 0) ? (chosen ?: fallback()) : fallback();
        __block NSColor *resolved = nil;
        Resolving++;
        [appearance performAsCurrentDrawingAppearance:^{
            resolved = [color colorUsingType:NSColorTypeComponentBased];
        }];
        Resolving--;
        return resolved ?: color; // pattern colors can't be resolved; draw them as they are
    }];
}

NSColor *MOManPageTextColor(void)
{
    static NSColor *color;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ color = FollowingColor(TextColorName, TextColor, ^{ return [NSColor textColor]; }); });
    return color;
}

NSColor *MOManPageLinkColor(void)
{
    static NSColor *color;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ color = FollowingColor(LinkColorName, LinkColor, ^{ return [NSColor linkColor]; }); });
    return color;
}

NSColor *MOManPageBackgroundColor(void)
{
    static NSColor *color;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ color = FollowingColor(BackgroundColorName, BackgroundColor, ^{ return [NSColor textBackgroundColor]; }); });
    return color;
}

BOOL MOIsManPageColor(NSColor *color)
{
    if (color == nil || color.type != NSColorTypeCatalog)
        return NO;
    NSString *name = color.colorNameComponent;
    return [name isEqualToString:TextColorName] || [name isEqualToString:LinkColorName] || [name isEqualToString:BackgroundColorName];
}

void MOSetManPageColors(MOColorAppearance appearance, NSColor *text, NSColor *link, NSColor *background)
{
    NSInteger index = (appearance == MOColorAppearanceDark) ? 1 : 0;
    Current[TextColor][index] = MOIsManPageColor(text) ? nil : text;
    Current[LinkColor][index] = MOIsManPageColor(link) ? nil : link;
    Current[BackgroundColor][index] = MOIsManPageColor(background) ? nil : background;
}

NSDictionary<NSAttributedStringKey, id> *MOManPageLinkAttributes(NSDictionary<NSAttributedStringKey, id> *current, NSColor *linkColor)
{
    NSMutableDictionary *attributes = [current mutableCopy] ?: [NSMutableDictionary dictionary];
    attributes[NSForegroundColorAttributeName] = linkColor;
    return attributes;
}

/* The index of the last section starting at or before `index`, or NSNotFound. */
static NSUInteger SectionContaining(NSUInteger index, NSArray<NSValue *> *ranges)
{
    NSUInteger found = NSNotFound;
    for (NSUInteger i = 0; i < ranges.count; i++)
    {
        if (ranges[i].rangeValue.location <= index)
            found = i;
    }
    return found;
}

NSUInteger MOAnchorAfterReload(NSString *oldText, NSUInteger oldIndex,
                               NSArray<NSString *> *oldSections, NSArray<NSValue *> *oldSectionRanges,
                               NSString *newText,
                               NSArray<NSString *> *newSections, NSArray<NSValue *> *newSectionRanges)
{
    NSUInteger last = newText.length > 0 ? newText.length - 1 : 0;

    if ([oldText isEqualToString:newText])
        return MIN(oldIndex, last);

    NSUInteger oldSection = SectionContaining(oldIndex, oldSectionRanges);
    if (oldSection != NSNotFound && oldSection < oldSections.count)
    {
        NSUInteger newSection = [newSections indexOfObject:oldSections[oldSection]];
        if (newSection != NSNotFound && newSection < newSectionRanges.count)
        {
            NSUInteger start = newSectionRanges[newSection].rangeValue.location;
            NSUInteger end = (newSection + 1 < newSectionRanges.count) ? newSectionRanges[newSection + 1].rangeValue.location : newText.length;
            NSUInteger offset = oldIndex - oldSectionRanges[oldSection].rangeValue.location;
            NSUInteger anchor = start + offset;
            if (end > start && anchor >= end)
                anchor = end - 1;
            return MIN(anchor, last);
        }
    }
    return MIN(oldIndex, last);
}
