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

static NSColor *CurrentText, *CurrentLink, *CurrentBackground;

/* A color that draws as `*current` (or `fallback`), resolved in the appearance it's drawn in. */
static NSColor *FollowingColor(NSString *name, NSColor * __strong *current, NSColor *(^fallback)(void))
{
    return [NSColor colorWithName:name dynamicProvider:^NSColor *(NSAppearance *appearance) {
        NSColor *color = *current ?: fallback();
        __block NSColor *resolved = nil;
        [appearance performAsCurrentDrawingAppearance:^{
            resolved = [color colorUsingType:NSColorTypeComponentBased];
        }];
        return resolved ?: color; // pattern colors can't be resolved; draw them as they are
    }];
}

NSColor *MOManPageTextColor(void)
{
    static NSColor *color;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ color = FollowingColor(@"ManOpenTextColor", &CurrentText, ^{ return [NSColor textColor]; }); });
    return color;
}

NSColor *MOManPageLinkColor(void)
{
    static NSColor *color;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ color = FollowingColor(@"ManOpenLinkColor", &CurrentLink, ^{ return [NSColor linkColor]; }); });
    return color;
}

NSColor *MOManPageBackgroundColor(void)
{
    static NSColor *color;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ color = FollowingColor(@"ManOpenBackgroundColor", &CurrentBackground, ^{ return [NSColor textBackgroundColor]; }); });
    return color;
}

void MOSetManPageColors(NSColor *text, NSColor *link, NSColor *background)
{
    CurrentText = text;
    CurrentLink = link;
    CurrentBackground = background;
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
