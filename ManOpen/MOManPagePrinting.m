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
    view.linkTextAttributes = screenView.linkTextAttributes;
    view.verticallyResizable = YES;
    view.horizontallyResizable = NO;
    view.maxSize = NSMakeSize(width, CGFLOAT_MAX);
    [view sizeToFit];

    return view;
}
