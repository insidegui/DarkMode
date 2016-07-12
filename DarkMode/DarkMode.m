//
//  DarkMode.m
//  DarkMode
//
//  Created by Guilherme Rambo on 12/07/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

#import "DarkMode.h"
#import <objc/runtime.h>

@implementation DarkMode

+ (NSAppearance *)darkAppearance
{
    static NSAppearance *dark;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dark = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    });
    return dark;
}

+ (void)load
{
    Method m1 = class_getInstanceMethod([NSWindow class], @selector(setContentView:));
    Method m2 = class_getClassMethod([self class], @selector(overrideSetContentView:));
    class_addMethod([NSWindow class], @selector(originalSetContentView:), method_getImplementation(m1), method_getTypeEncoding(m1));
    method_exchangeImplementations(m1, m2);

    Method m3 = class_getInstanceMethod([NSWindow class], @selector(makeKeyAndOrderFront:));
    Method m4 = class_getClassMethod([self class], @selector(overrideMakeKeyAndOrderFront:));
    class_addMethod([NSWindow class], @selector(originalMakeKeyAndOrderFront:), method_getImplementation(m3), method_getTypeEncoding(m3));
    method_exchangeImplementations(m3, m4);
    
    for (NSWindow *window in [NSApplication sharedApplication].windows) {
        [self applyDarkAppearanceToWindow:window];
    }
}

+ (void)applyDarkAppearanceToWindow:(NSWindow *)window
{
    [window setAppearance:[self darkAppearance]];
    [self updateDarkModeStateForTreeStartingAtView:window.contentView];
}

+ (void)updateDarkModeStateForTreeStartingAtView:(__kindof NSView *)rootView
{
    for (NSView *view in rootView.subviews) {
        view.appearance = [self darkAppearance];
        
        if ([view isKindOfClass:[NSVisualEffectView class]]) {
            [(NSVisualEffectView *)view setMaterial:NSVisualEffectMaterialDark];
        }
        
        if ([view isKindOfClass:[NSClipView class]] ||
            [view isKindOfClass:[NSScrollView class]] ||
            [view isKindOfClass:[NSMatrix class]] ||
            [view isKindOfClass:[NSTextView class]] ||
            [view isKindOfClass:NSClassFromString(@"TBrowserTableView")] ||
            [view isKindOfClass:NSClassFromString(@"TIconView")]) {
            [view performSelector:@selector(setBackgroundColor:) withObject:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
//            NSLog(@"Background color set");
        }
        
        if (view.subviews.count > 0) [self updateDarkModeStateForTreeStartingAtView:view];
//        NSLog(@"%@", view);
    }
    
//    [rootView.window displayIfNeeded];
}

+ (void)originalSetContentView:(__kindof NSView *)contentView
{
    return; // runtime override
}

+ (void)overrideSetContentView:(__kindof NSView *)contentView
{
    [self originalSetContentView:contentView];
    
    [DarkMode updateDarkModeStateForTreeStartingAtView:contentView];
}

+ (void)originalMakeKeyAndOrderFront:(id)sender
{
    return; // runtime override
}

+ (void)overrideMakeKeyAndOrderFront:(id)sender
{
    [DarkMode applyDarkAppearanceToWindow:(NSWindow *)self];
    [self originalMakeKeyAndOrderFront:sender];
}

@end