//
//  MOManPagePrinting.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MOManPagePrinting.h"
#import <objc/runtime.h>

static const void *MOPrintTextStorageKey = &MOPrintTextStorageKey;

NSTextView *MOMakeManPagePrintView(Class viewClass, NSTextView *screenView)
{
    CGFloat width = NSWidth(screenView.bounds);
    NSSize inset = screenView.textContainerInset;
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:screenView.textStorage];
    NSMutableDictionary *linkAttributes = [screenView.linkTextAttributes mutableCopy] ?: [NSMutableDictionary dictionary];

    // Print in the default colors, whatever the user chose (resolved light below).
    [storage addAttribute:NSForegroundColorAttributeName value:[NSColor textColor] range:NSMakeRange(0, storage.length)];
    linkAttributes[NSForegroundColorAttributeName] = [NSColor linkColor];

    // A text view applies linkTextAttributes only when drawing to the screen, so
    // links would print in the text color; write the link style into the text.
    NSMutableDictionary *printedLinkAttributes = [linkAttributes mutableCopy];
    [printedLinkAttributes removeObjectForKey:NSCursorAttributeName];
    [storage enumerateAttribute:NSLinkAttributeName inRange:NSMakeRange(0, storage.length) options:0
                     usingBlock:^(id link, NSRange range, BOOL *stop) {
        if (link != nil)
            [storage addAttributes:printedLinkAttributes range:range];
    }];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:NSMakeSize(width - 2.0 * inset.width, CGFLOAT_MAX)];

    container.lineFragmentPadding = screenView.textContainer.lineFragmentPadding;
    container.widthTracksTextView = YES;
    [layoutManager addTextContainer:container];
    [storage addLayoutManager:layoutManager];

    NSTextView *view = [[viewClass alloc] initWithFrame:NSMakeRect(0.0, 0.0, width, 100.0) textContainer:container];

    // The text system doesn't retain its storage; keep it as long as the view.
    objc_setAssociatedObject(view, MOPrintTextStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    view.drawsBackground = NO;
    view.editable = NO;
    view.selectable = NO;
    view.textContainerInset = inset;
    view.linkTextAttributes = linkAttributes;
    view.verticallyResizable = YES;
    view.horizontallyResizable = NO;
    view.maxSize = NSMakeSize(width, CGFLOAT_MAX);
    [view sizeToFit];

    return view;
}
