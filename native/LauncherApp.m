#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

static NSUserInterfaceItemIdentifier const LauncherItemIdentifier = @"LauncherItem";

@interface LauncherApplication : NSObject
@property (copy) NSString *name;
@property (copy) NSString *searchText;
@property (strong) NSURL *URL;
@property (strong) NSImage *icon;
@end

@implementation LauncherApplication
@end

@interface LauncherWindow : NSWindow
@end

@implementation LauncherWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
@end

@interface LauncherWallpaperView : NSView
@property (strong) NSImage *wallpaper;
@end

@implementation LauncherWallpaperView

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    if (self.wallpaper == nil || self.wallpaper.size.width <= 0 || self.wallpaper.size.height <= 0) {
        NSGradient *fallback = [[NSGradient alloc]
            initWithStartingColor:[NSColor colorWithSRGBRed:0.08 green:0.13 blue:0.22 alpha:1.0]
            endingColor:[NSColor colorWithSRGBRed:0.20 green:0.15 blue:0.30 alpha:1.0]];
        [fallback drawInRect:bounds angle:-25.0];
        return;
    }

    NSSize imageSize = self.wallpaper.size;
    CGFloat scale = MAX(bounds.size.width / imageSize.width, bounds.size.height / imageSize.height);
    NSSize drawSize = NSMakeSize(imageSize.width * scale, imageSize.height * scale);
    NSRect drawRect = NSMakeRect(
        NSMidX(bounds) - drawSize.width / 2.0,
        NSMidY(bounds) - drawSize.height / 2.0,
        drawSize.width,
        drawSize.height
    );
    NSGraphicsContext.currentContext.imageInterpolation = NSImageInterpolationHigh;
    [self.wallpaper drawInRect:drawRect
                     fromRect:NSZeroRect
                    operation:NSCompositingOperationSourceOver
                     fraction:1.0
               respectFlipped:YES
                        hints:nil];
}

@end

@interface LauncherTintView : NSView
@end

@implementation LauncherTintView
- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithSRGBRed:0.015 green:0.025 blue:0.045 alpha:0.24] setFill];
    NSRectFill(self.bounds);
}
@end

@interface LauncherSettingsBackdropView : NSView
@property (copy) void (^dismissHandler)(void);
@end

@implementation LauncherSettingsBackdropView
- (void)mouseDown:(NSEvent *)event {
    if (self.dismissHandler != nil) self.dismissHandler();
}
@end

@interface LauncherSearchPillView : NSVisualEffectView
@property (weak) NSSearchField *searchField;
@end

@implementation LauncherSearchPillView
- (void)mouseDown:(NSEvent *)event {
    if (self.searchField != nil) {
        [self.window makeFirstResponder:self.searchField];
    }
}
@end

@interface LauncherPageDotsView : NSView
@property NSInteger pageCount;
@property NSInteger currentPage;
@property (copy) void (^pageHandler)(NSInteger page);
- (void)updateWithPageCount:(NSInteger)pageCount currentPage:(NSInteger)currentPage;
@end

@implementation LauncherPageDotsView

- (BOOL)isFlipped { return YES; }

- (NSSize)intrinsicContentSize {
    return NSMakeSize(MAX(16.0, self.pageCount * 14.0), 18.0);
}

- (void)updateWithPageCount:(NSInteger)pageCount currentPage:(NSInteger)currentPage {
    self.pageCount = pageCount;
    self.currentPage = currentPage;
    self.hidden = pageCount <= 1;
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.pageCount <= 1) return;
    CGFloat spacing = 14.0;
    CGFloat totalWidth = self.pageCount * spacing;
    CGFloat startX = NSMidX(self.bounds) - totalWidth / 2.0 + spacing / 2.0;
    for (NSInteger index = 0; index < self.pageCount; index++) {
        NSColor *color = index == self.currentPage
            ? [NSColor colorWithWhite:1.0 alpha:0.92]
            : [NSColor colorWithWhite:1.0 alpha:0.34];
        [color setFill];
        NSRect dotRect = NSMakeRect(startX + index * spacing - 3.0, NSMidY(self.bounds) - 3.0, 6.0, 6.0);
        [[NSBezierPath bezierPathWithOvalInRect:dotRect] fill];
    }
}

- (void)mouseDown:(NSEvent *)event {
    if (self.pageCount <= 1 || self.pageHandler == nil) return;
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    CGFloat spacing = 14.0;
    CGFloat totalWidth = self.pageCount * spacing;
    CGFloat startX = NSMidX(self.bounds) - totalWidth / 2.0;
    NSInteger page = (NSInteger)floor((point.x - startX) / spacing);
    page = MAX(0, MIN(self.pageCount - 1, page));
    self.pageHandler(page);
}

@end

@interface LauncherCollectionItem : NSCollectionViewItem
@property (strong) NSImageView *iconView;
@property (strong) NSTextField *nameLabel;
@end

@implementation LauncherCollectionItem

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 160, 170)];
    self.view.wantsLayer = YES;

    self.iconView = [[NSImageView alloc] initWithFrame:NSZeroRect];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.iconView.imageAlignment = NSImageAlignCenter;
    self.iconView.wantsLayer = YES;

    self.nameLabel = [NSTextField labelWithString:@""];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.alignment = NSTextAlignmentCenter;
    self.nameLabel.font = [NSFont systemFontOfSize:14.0 weight:NSFontWeightMedium];
    self.nameLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.96];
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.nameLabel.maximumNumberOfLines = 1;
    self.nameLabel.cell.truncatesLastVisibleLine = YES;
    NSShadow *labelShadow = [[NSShadow alloc] init];
    labelShadow.shadowColor = [NSColor colorWithWhite:0.0 alpha:0.72];
    labelShadow.shadowBlurRadius = 3.0;
    labelShadow.shadowOffset = NSMakeSize(0, -1);
    self.nameLabel.shadow = labelShadow;

    [self.view addSubview:self.iconView];
    [self.view addSubview:self.nameLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.iconView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.iconView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.iconView.widthAnchor constraintEqualToConstant:124.0],
        [self.iconView.heightAnchor constraintEqualToConstant:124.0],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:2.0],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-2.0],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.iconView.bottomAnchor constant:9.0]
    ]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.iconView.image = nil;
    self.nameLabel.stringValue = @"";
    self.iconView.alphaValue = 1.0;
}

- (void)configureWithApplication:(LauncherApplication *)application {
    self.iconView.image = application.icon;
    self.nameLabel.stringValue = application.name;
    self.view.toolTip = application.name;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.08;
        self.iconView.animator.alphaValue = selected ? 0.68 : 1.0;
    }];
}

@end

static NSUserInterfaceItemIdentifier const SettingsCellIdentifier = @"SettingsCell";

@interface LauncherSettingsCellView : NSTableCellView
@property (strong) NSImageView *appIconView;
@property (strong) NSTextField *appNameLabel;
@property (strong) NSButton *blockedCheckbox;
- (void)configureWithApplication:(LauncherApplication *)application blocked:(BOOL)blocked;
@end

@implementation LauncherSettingsCellView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self == nil) return nil;
    self.identifier = SettingsCellIdentifier;
    self.wantsLayer = YES;
    self.layer.cornerRadius = 10.0;

    self.appIconView = [[NSImageView alloc] initWithFrame:NSZeroRect];
    self.appIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.appIconView.imageScaling = NSImageScaleProportionallyUpOrDown;

    self.appNameLabel = [NSTextField labelWithString:@""];
    self.appNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.appNameLabel.font = [NSFont systemFontOfSize:14.0 weight:NSFontWeightMedium];
    self.appNameLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.92];
    self.appNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

    self.blockedCheckbox = [NSButton checkboxWithTitle:@"屏蔽" target:nil action:nil];
    self.blockedCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    self.blockedCheckbox.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightRegular];
    self.blockedCheckbox.contentTintColor = [NSColor colorWithSRGBRed:0.45 green:0.72 blue:1.0 alpha:1.0];

    [self addSubview:self.appIconView];
    [self addSubview:self.appNameLabel];
    [self addSubview:self.blockedCheckbox];
    [NSLayoutConstraint activateConstraints:@[
        [self.appIconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12.0],
        [self.appIconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.appIconView.widthAnchor constraintEqualToConstant:38.0],
        [self.appIconView.heightAnchor constraintEqualToConstant:38.0],
        [self.appNameLabel.leadingAnchor constraintEqualToAnchor:self.appIconView.trailingAnchor constant:12.0],
        [self.appNameLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.appNameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.blockedCheckbox.leadingAnchor constant:-12.0],
        [self.blockedCheckbox.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12.0],
        [self.blockedCheckbox.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
    return self;
}

- (void)configureWithApplication:(LauncherApplication *)application blocked:(BOOL)blocked {
    self.appIconView.image = application.icon;
    self.appNameLabel.stringValue = application.name;
    self.blockedCheckbox.state = blocked ? NSControlStateValueOn : NSControlStateValueOff;
    self.toolTip = application.URL.path;
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSCollectionViewDataSource, NSCollectionViewDelegate, NSSearchFieldDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (strong) LauncherWindow *window;
@property (strong) NSVisualEffectView *searchPill;
@property (strong) NSSearchField *searchField;
@property (strong) NSButton *settingsButton;
@property (strong) NSCollectionView *collectionView;
@property (strong) NSTextField *messageLabel;
@property (strong) LauncherPageDotsView *pageDots;
@property (strong) NSArray<LauncherApplication *> *allApplications;
@property (strong) NSArray<LauncherApplication *> *filteredApplications;
@property (strong) NSArray<LauncherApplication *> *pageApplications;
@property (strong) NSArray<LauncherApplication *> *settingsApplications;
@property (strong) NSMutableSet<NSString *> *hiddenApplicationPaths;
@property (strong) NSView *settingsBackdrop;
@property (strong) NSVisualEffectView *settingsPanel;
@property (strong) NSSearchField *settingsSearchField;
@property (strong) NSTableView *settingsTableView;
@property (strong) NSTextField *settingsSummaryLabel;
@property NSInteger columns;
@property NSInteger rows;
@property NSInteger itemsPerPage;
@property NSInteger currentPage;
@property CGFloat itemWidth;
@property CGFloat columnSpacing;
@property BOOL finishedLoading;
@property CGFloat scrollAccumulator;
@property NSTimeInterval lastPageChange;
@property BOOL pageTransitionInProgress;
@property BOOL isDismissing;
@property (strong) id keyMonitor;
@property (strong) id scrollMonitor;
@property (strong) id clickMonitor;
- (void)showPage:(NSInteger)page;
- (void)showPage:(NSInteger)page animated:(BOOL)animated;
- (void)showLauncher;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSArray<NSString *> *savedHiddenPaths = [NSUserDefaults.standardUserDefaults stringArrayForKey:@"HiddenApplicationPaths"] ?: @[];
    self.hiddenApplicationPaths = [NSMutableSet setWithArray:savedHiddenPaths];
    NSScreen *screen = NSScreen.mainScreen ?: NSScreen.screens.firstObject;
    NSRect frame = screen ? screen.frame : NSMakeRect(0, 0, 1440, 900);
    self.window = [[LauncherWindow alloc]
        initWithContentRect:frame
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    self.window.delegate = self;
    self.window.backgroundColor = NSColor.clearColor;
    self.window.opaque = NO;
    self.window.hasShadow = NO;
    self.window.level = NSNormalWindowLevel + 1;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces
        | NSWindowCollectionBehaviorFullScreenPrimary
        | NSWindowCollectionBehaviorStationary;
    [self buildInterfaceForScreen:screen frame:frame];
    self.window.alphaValue = 0.0;
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp setPresentationOptions:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.26;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        self.window.animator.alphaValue = 1.0;
    } completionHandler:nil];
    [self.window makeFirstResponder:self.searchField];
    [self installInputHandlers];
    [self startDiscoveringApplications];
}

- (void)buildInterfaceForScreen:(NSScreen *)screen frame:(NSRect)frame {
    LauncherWallpaperView *wallpaperView = [[LauncherWallpaperView alloc] initWithFrame:frame];
    wallpaperView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    NSURL *wallpaperURL = screen ? [NSWorkspace.sharedWorkspace desktopImageURLForScreen:screen] : nil;
    if (wallpaperURL != nil) wallpaperView.wallpaper = [[NSImage alloc] initWithContentsOfURL:wallpaperURL];
    self.window.contentView = wallpaperView;

    NSVisualEffectView *blurView = [[NSVisualEffectView alloc] initWithFrame:NSZeroRect];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    blurView.material = NSVisualEffectMaterialFullScreenUI;
    blurView.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    blurView.state = NSVisualEffectStateActive;
    [wallpaperView addSubview:blurView];

    LauncherTintView *tintView = [[LauncherTintView alloc] initWithFrame:NSZeroRect];
    tintView.translatesAutoresizingMaskIntoConstraints = NO;
    [wallpaperView addSubview:tintView];

    NSView *searchShadowView = [[NSView alloc] initWithFrame:NSZeroRect];
    searchShadowView.translatesAutoresizingMaskIntoConstraints = NO;
    searchShadowView.wantsLayer = YES;
    searchShadowView.layer.cornerRadius = 17.0;
    searchShadowView.layer.backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.16].CGColor;
    searchShadowView.layer.shadowColor = NSColor.blackColor.CGColor;
    searchShadowView.layer.shadowOpacity = 0.34;
    searchShadowView.layer.shadowRadius = 18.0;
    searchShadowView.layer.shadowOffset = NSMakeSize(0, -5.0);
    [wallpaperView addSubview:searchShadowView];

    self.searchPill = [[LauncherSearchPillView alloc] initWithFrame:NSZeroRect];
    self.searchPill.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchPill.material = NSVisualEffectMaterialHUDWindow;
    self.searchPill.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    self.searchPill.state = NSVisualEffectStateActive;
    self.searchPill.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    self.searchPill.wantsLayer = YES;
    self.searchPill.layer.cornerRadius = 17.0;
    self.searchPill.layer.masksToBounds = YES;
    self.searchPill.layer.borderWidth = 1.0;
    self.searchPill.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.18].CGColor;
    self.searchPill.layer.backgroundColor = [NSColor colorWithWhite:0.04 alpha:0.13].CGColor;
    [wallpaperView addSubview:self.searchPill];

    self.searchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
    self.searchField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchField.delegate = self;
    self.searchField.bezeled = NO;
    self.searchField.drawsBackground = NO;
    self.searchField.focusRingType = NSFocusRingTypeNone;
    self.searchField.font = [NSFont systemFontOfSize:17.0 weight:NSFontWeightRegular];
    self.searchField.textColor = [NSColor colorWithWhite:1.0 alpha:0.96];
    self.searchField.alignment = NSTextAlignmentLeft;
    self.searchField.controlSize = NSControlSizeLarge;
    NSSearchFieldCell *searchCell = (NSSearchFieldCell *)self.searchField.cell;
    searchCell.alignment = NSTextAlignmentLeft;
    searchCell.placeholderString = @"";
    searchCell.searchButtonCell = nil;
    [self.searchPill addSubview:self.searchField];
    ((LauncherSearchPillView *)self.searchPill).searchField = self.searchField;

    NSImage *settingsImage = [NSImage imageWithSystemSymbolName:@"gearshape.fill" accessibilityDescription:@"设置"];
    self.settingsButton = [NSButton buttonWithImage:settingsImage target:self action:@selector(openSettings:)];
    self.settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.settingsButton.bordered = NO;
    self.settingsButton.imageScaling = NSImageScaleProportionallyDown;
    self.settingsButton.contentTintColor = [NSColor colorWithWhite:1.0 alpha:0.86];
    self.settingsButton.toolTip = @"设置屏蔽的应用";
    self.settingsButton.enabled = NO;
    self.settingsButton.wantsLayer = YES;
    self.settingsButton.layer.cornerRadius = 22.0;
    self.settingsButton.layer.backgroundColor = [NSColor colorWithWhite:0.08 alpha:0.38].CGColor;
    self.settingsButton.layer.borderWidth = 1.0;
    self.settingsButton.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.18].CGColor;
    [wallpaperView addSubview:self.settingsButton];

    CGFloat itemWidth = 160.0;
    CGFloat itemHeight = 170.0;
    CGFloat columnSpacing = 54.0;
    CGFloat rowSpacing = 36.0;
    self.itemWidth = itemWidth;
    self.columnSpacing = columnSpacing;
    self.columns = MIN(8, MAX(5, (NSInteger)floor((frame.size.width - 180.0 + columnSpacing) / (itemWidth + columnSpacing))));
    self.rows = MIN(5, MAX(3, (NSInteger)floor((frame.size.height - 210.0 + rowSpacing) / (itemHeight + rowSpacing))));
    self.itemsPerPage = self.columns * self.rows;

    NSCollectionViewFlowLayout *layout = [[NSCollectionViewFlowLayout alloc] init];
    layout.itemSize = NSMakeSize(itemWidth, itemHeight);
    layout.minimumInteritemSpacing = columnSpacing;
    layout.minimumLineSpacing = rowSpacing;
    layout.sectionInset = NSEdgeInsetsZero;

    self.collectionView = [[NSCollectionView alloc] initWithFrame:NSZeroRect];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.selectable = YES;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.backgroundColors = @[NSColor.clearColor];
    self.collectionView.wantsLayer = YES;
    self.collectionView.layer.backgroundColor = NSColor.clearColor.CGColor;
    [self.collectionView registerClass:LauncherCollectionItem.class forItemWithIdentifier:LauncherItemIdentifier];
    [wallpaperView addSubview:self.collectionView];

    self.messageLabel = [NSTextField labelWithString:@"正在读取应用程序…"];
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageLabel.alignment = NSTextAlignmentCenter;
    self.messageLabel.font = [NSFont systemFontOfSize:16.0 weight:NSFontWeightMedium];
    self.messageLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.68];
    NSShadow *messageShadow = [[NSShadow alloc] init];
    messageShadow.shadowColor = [NSColor colorWithWhite:0.0 alpha:0.65];
    messageShadow.shadowBlurRadius = 4.0;
    messageShadow.shadowOffset = NSMakeSize(0, -1);
    self.messageLabel.shadow = messageShadow;
    [wallpaperView addSubview:self.messageLabel];

    self.pageDots = [[LauncherPageDotsView alloc] initWithFrame:NSZeroRect];
    self.pageDots.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageDots.hidden = YES;
    __weak typeof(self) weakSelf = self;
    self.pageDots.pageHandler = ^(NSInteger page) {
        [weakSelf showPage:page animated:YES];
    };
    [wallpaperView addSubview:self.pageDots];
    [self buildSettingsOverlayInView:wallpaperView frame:frame];

    CGFloat gridWidth = self.columns * itemWidth + (self.columns - 1) * columnSpacing;
    CGFloat gridHeight = self.rows * itemHeight + (self.rows - 1) * rowSpacing;
    [NSLayoutConstraint activateConstraints:@[
        [blurView.leadingAnchor constraintEqualToAnchor:wallpaperView.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:wallpaperView.trailingAnchor],
        [blurView.topAnchor constraintEqualToAnchor:wallpaperView.topAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:wallpaperView.bottomAnchor],
        [tintView.leadingAnchor constraintEqualToAnchor:wallpaperView.leadingAnchor],
        [tintView.trailingAnchor constraintEqualToAnchor:wallpaperView.trailingAnchor],
        [tintView.topAnchor constraintEqualToAnchor:wallpaperView.topAnchor],
        [tintView.bottomAnchor constraintEqualToAnchor:wallpaperView.bottomAnchor],
        [searchShadowView.centerXAnchor constraintEqualToAnchor:wallpaperView.centerXAnchor],
        [searchShadowView.centerYAnchor constraintEqualToAnchor:self.searchPill.centerYAnchor],
        [searchShadowView.widthAnchor constraintEqualToAnchor:self.searchPill.widthAnchor],
        [searchShadowView.heightAnchor constraintEqualToAnchor:self.searchPill.heightAnchor],
        [self.searchPill.topAnchor constraintEqualToAnchor:wallpaperView.topAnchor constant:54.0],
        [self.searchPill.centerXAnchor constraintEqualToAnchor:wallpaperView.centerXAnchor],
        [self.searchPill.widthAnchor constraintEqualToConstant:460.0],
        [self.searchPill.heightAnchor constraintEqualToConstant:52.0],
        [self.searchField.leadingAnchor constraintEqualToAnchor:self.searchPill.leadingAnchor constant:22.0],
        [self.searchField.trailingAnchor constraintEqualToAnchor:self.searchPill.trailingAnchor constant:-22.0],
        [self.searchField.centerYAnchor constraintEqualToAnchor:self.searchPill.centerYAnchor],
        [self.searchField.heightAnchor constraintEqualToConstant:26.0],
        [self.settingsButton.topAnchor constraintEqualToAnchor:wallpaperView.topAnchor constant:38.0],
        [self.settingsButton.trailingAnchor constraintEqualToAnchor:wallpaperView.trailingAnchor constant:-42.0],
        [self.settingsButton.widthAnchor constraintEqualToConstant:44.0],
        [self.settingsButton.heightAnchor constraintEqualToConstant:44.0],
        [self.collectionView.centerXAnchor constraintEqualToAnchor:wallpaperView.centerXAnchor],
        [self.collectionView.centerYAnchor constraintEqualToAnchor:wallpaperView.centerYAnchor constant:-5.0],
        [self.collectionView.widthAnchor constraintEqualToConstant:gridWidth],
        [self.collectionView.heightAnchor constraintEqualToConstant:gridHeight],
        [self.messageLabel.centerXAnchor constraintEqualToAnchor:wallpaperView.centerXAnchor],
        [self.messageLabel.centerYAnchor constraintEqualToAnchor:wallpaperView.centerYAnchor],
        [self.pageDots.centerXAnchor constraintEqualToAnchor:wallpaperView.centerXAnchor],
        [self.pageDots.bottomAnchor constraintEqualToAnchor:wallpaperView.bottomAnchor constant:-30.0],
        [self.pageDots.heightAnchor constraintEqualToConstant:18.0]
    ]];
}

- (void)showLauncher {
    if (self.isDismissing || self.window.isVisible) return;

    self.searchField.stringValue = @"";
    self.settingsBackdrop.hidden = YES;
    self.settingsSearchField.stringValue = @"";
    [self applyLauncherFilter];

    self.window.alphaValue = 0.0;
    [NSApp unhide:nil];
    [NSApp setPresentationOptions:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.26;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        self.window.animator.alphaValue = 1.0;
    } completionHandler:nil];
    [self.window makeFirstResponder:self.searchField];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!flag) [self showLauncher];
    return YES;
}

- (void)buildSettingsOverlayInView:(NSView *)rootView frame:(NSRect)frame {
    LauncherSettingsBackdropView *settingsBackdrop = [[LauncherSettingsBackdropView alloc] initWithFrame:NSZeroRect];
    self.settingsBackdrop = settingsBackdrop;
    self.settingsBackdrop.translatesAutoresizingMaskIntoConstraints = NO;
    self.settingsBackdrop.wantsLayer = YES;
    self.settingsBackdrop.layer.backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.38].CGColor;
    self.settingsBackdrop.hidden = YES;
    __weak typeof(self) weakSelf = self;
    settingsBackdrop.dismissHandler = ^{
        [weakSelf closeSettings:nil];
    };
    [rootView addSubview:self.settingsBackdrop];

    self.settingsPanel = [[NSVisualEffectView alloc] initWithFrame:NSZeroRect];
    NSVisualEffectView *panel = self.settingsPanel;
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.material = NSVisualEffectMaterialHUDWindow;
    panel.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    panel.state = NSVisualEffectStateActive;
    panel.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    panel.wantsLayer = YES;
    panel.layer.cornerRadius = 22.0;
    panel.layer.masksToBounds = YES;
    panel.layer.borderWidth = 1.0;
    panel.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.17].CGColor;
    [self.settingsBackdrop addSubview:panel];

    NSTextField *titleLabel = [NSTextField labelWithString:@"屏蔽应用"];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [NSFont systemFontOfSize:21.0 weight:NSFontWeightSemibold];
    titleLabel.textColor = NSColor.whiteColor;
    [panel addSubview:titleLabel];

    NSTextField *subtitleLabel = [NSTextField labelWithString:@"勾选要从启动器和搜索结果中隐藏的应用"];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightRegular];
    subtitleLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.55];
    [panel addSubview:subtitleLabel];

    self.settingsSummaryLabel = [NSTextField labelWithString:@"已屏蔽 0 个应用"];
    self.settingsSummaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.settingsSummaryLabel.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightMedium];
    self.settingsSummaryLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.62];
    self.settingsSummaryLabel.alignment = NSTextAlignmentRight;
    [panel addSubview:self.settingsSummaryLabel];

    self.settingsSearchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
    self.settingsSearchField.translatesAutoresizingMaskIntoConstraints = NO;
    self.settingsSearchField.placeholderString = @"搜索应用";
    self.settingsSearchField.delegate = self;
    self.settingsSearchField.controlSize = NSControlSizeLarge;
    self.settingsSearchField.font = [NSFont systemFontOfSize:14.0 weight:NSFontWeightRegular];
    [panel addSubview:self.settingsSearchField];

    NSTableColumn *applicationColumn = [[NSTableColumn alloc] initWithIdentifier:@"Application"];
    applicationColumn.resizingMask = NSTableColumnAutoresizingMask;
    self.settingsTableView = [[NSTableView alloc] initWithFrame:NSZeroRect];
    [self.settingsTableView addTableColumn:applicationColumn];
    self.settingsTableView.headerView = nil;
    self.settingsTableView.dataSource = self;
    self.settingsTableView.delegate = self;
    self.settingsTableView.rowHeight = 54.0;
    self.settingsTableView.intercellSpacing = NSMakeSize(0, 4.0);
    self.settingsTableView.backgroundColor = NSColor.clearColor;
    self.settingsTableView.gridStyleMask = NSTableViewGridNone;
    self.settingsTableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;

    NSScrollView *settingsScrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    settingsScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    settingsScrollView.documentView = self.settingsTableView;
    settingsScrollView.drawsBackground = NO;
    settingsScrollView.borderType = NSNoBorder;
    settingsScrollView.hasVerticalScroller = YES;
    settingsScrollView.autohidesScrollers = YES;
    [panel addSubview:settingsScrollView];

    NSButton *showAllButton = [NSButton buttonWithTitle:@"全部显示" target:self action:@selector(showAllApplications:)];
    showAllButton.translatesAutoresizingMaskIntoConstraints = NO;
    showAllButton.bezelStyle = NSBezelStyleRounded;
    [panel addSubview:showAllButton];

    NSButton *doneButton = [NSButton buttonWithTitle:@"完成" target:self action:@selector(closeSettings:)];
    doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    doneButton.bezelStyle = NSBezelStyleRounded;
    doneButton.keyEquivalent = @"\r";
    [panel addSubview:doneButton];

    CGFloat panelWidth = MIN(720.0, frame.size.width - 120.0);
    CGFloat panelHeight = MIN(680.0, frame.size.height - 100.0);
    [NSLayoutConstraint activateConstraints:@[
        [self.settingsBackdrop.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [self.settingsBackdrop.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
        [self.settingsBackdrop.topAnchor constraintEqualToAnchor:rootView.topAnchor],
        [self.settingsBackdrop.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor],
        [panel.centerXAnchor constraintEqualToAnchor:self.settingsBackdrop.centerXAnchor],
        [panel.centerYAnchor constraintEqualToAnchor:self.settingsBackdrop.centerYAnchor],
        [panel.widthAnchor constraintEqualToConstant:panelWidth],
        [panel.heightAnchor constraintEqualToConstant:panelHeight],
        [titleLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:26.0],
        [titleLabel.topAnchor constraintEqualToAnchor:panel.topAnchor constant:23.0],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:4.0],
        [self.settingsSummaryLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-26.0],
        [self.settingsSummaryLabel.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [self.settingsSummaryLabel.widthAnchor constraintEqualToConstant:170.0],
        [self.settingsSearchField.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:24.0],
        [self.settingsSearchField.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-24.0],
        [self.settingsSearchField.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:18.0],
        [self.settingsSearchField.heightAnchor constraintEqualToConstant:36.0],
        [settingsScrollView.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:20.0],
        [settingsScrollView.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-20.0],
        [settingsScrollView.topAnchor constraintEqualToAnchor:self.settingsSearchField.bottomAnchor constant:14.0],
        [settingsScrollView.bottomAnchor constraintEqualToAnchor:showAllButton.topAnchor constant:-18.0],
        [showAllButton.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:24.0],
        [showAllButton.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-22.0],
        [doneButton.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-24.0],
        [doneButton.centerYAnchor constraintEqualToAnchor:showAllButton.centerYAnchor],
        [doneButton.widthAnchor constraintEqualToConstant:86.0]
    ]];
}

- (void)startDiscoveringApplications {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray<NSURL *> *URLs = [self applicationURLs];
        NSMutableArray<LauncherApplication *> *applications = [NSMutableArray arrayWithCapacity:URLs.count];
        for (NSURL *URL in URLs) {
            @autoreleasepool {
                NSBundle *bundle = [NSBundle bundleWithURL:URL];
                NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                if (displayName.length == 0) displayName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
                if (displayName.length == 0) displayName = URL.lastPathComponent.stringByDeletingPathExtension;

                LauncherApplication *application = [[LauncherApplication alloc] init];
                application.URL = URL;
                application.name = displayName;
                NSString *bundleIdentifier = bundle.bundleIdentifier ?: @"";
                application.searchText = [NSString stringWithFormat:@"%@ %@ %@", displayName, bundleIdentifier, URL.path].lowercaseString;
                application.icon = [[NSWorkspace.sharedWorkspace iconForFile:URL.path] copy];
                [applications addObject:application];
            }
        }
        [applications sortUsingComparator:^NSComparisonResult(LauncherApplication *first, LauncherApplication *second) {
            return [first.name localizedStandardCompare:second.name];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *strongSelf = weakSelf;
            if (strongSelf == nil) return;
            strongSelf.allApplications = applications;
            strongSelf.finishedLoading = YES;
            strongSelf.messageLabel.hidden = YES;
            strongSelf.settingsButton.enabled = YES;
            [strongSelf applyLauncherFilter];
        });
    });
}

- (NSArray<NSURL *> *)applicationURLs {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSArray<NSURL *> *roots = @[
        [NSURL fileURLWithPath:@"/Applications" isDirectory:YES],
        [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Applications"] isDirectory:YES],
        [NSURL fileURLWithPath:@"/System/Applications" isDirectory:YES]
    ];
    NSMutableArray<NSURL *> *foundApplications = [NSMutableArray array];
    NSMutableSet<NSString *> *seenPaths = [NSMutableSet set];

    for (NSURL *root in roots) {
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:root.path isDirectory:&isDirectory] || !isDirectory) continue;
        NSDirectoryEnumerator<NSURL *> *enumerator = [fileManager
            enumeratorAtURL:root
            includingPropertiesForKeys:@[NSURLIsDirectoryKey]
            options:NSDirectoryEnumerationSkipsHiddenFiles
            errorHandler:^BOOL(NSURL *url, NSError *error) { return YES; }];
        for (NSURL *URL in enumerator) {
            if (![URL.pathExtension.lowercaseString isEqualToString:@"app"]) continue;
            NSNumber *isAppDirectory = nil;
            [URL getResourceValue:&isAppDirectory forKey:NSURLIsDirectoryKey error:nil];
            if (!isAppDirectory.boolValue) continue;
            [enumerator skipDescendants];

            NSURL *standardURL = URL.standardizedURL;
            if ([seenPaths containsObject:standardURL.path]) continue;
            if (![self isUserFacingApplicationAtURL:standardURL]) continue;
            [seenPaths addObject:standardURL.path];
            [foundApplications addObject:standardURL];
        }
    }
    return foundApplications;
}

- (BOOL)isUserFacingApplicationAtURL:(NSURL *)URL {
    NSURL *infoURL = [URL URLByAppendingPathComponent:@"Contents/Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:infoURL];
    if (info == nil) return NO;
    if ([info[@"LSUIElement"] boolValue] || [info[@"LSBackgroundOnly"] boolValue]) return NO;
    NSString *packageType = info[@"CFBundlePackageType"];
    if (packageType.length > 0 && ![packageType isEqualToString:@"APPL"]) return NO;
    return YES;
}

- (void)openSettings:(id)sender {
    if (!self.finishedLoading) return;
    self.settingsSearchField.stringValue = @"";
    self.settingsApplications = self.allApplications;
    [self.settingsTableView reloadData];
    [self updateSettingsSummary];
    self.settingsBackdrop.hidden = NO;
    [self.window makeFirstResponder:self.settingsSearchField];
}

- (void)closeSettings:(id)sender {
    self.settingsBackdrop.hidden = YES;
    self.settingsSearchField.stringValue = @"";
    [self applyLauncherFilter];
    [self.window makeFirstResponder:self.searchField];
}

- (void)showAllApplications:(id)sender {
    [self.hiddenApplicationPaths removeAllObjects];
    [self persistHiddenApplications];
    [self.settingsTableView reloadData];
    [self updateSettingsSummary];
}

- (void)settingsCheckboxChanged:(NSButton *)sender {
    NSInteger row = sender.tag;
    if (row < 0 || row >= self.settingsApplications.count) return;
    LauncherApplication *application = self.settingsApplications[row];
    if (sender.state == NSControlStateValueOn) {
        [self.hiddenApplicationPaths addObject:application.URL.path];
    } else {
        [self.hiddenApplicationPaths removeObject:application.URL.path];
    }
    [self persistHiddenApplications];
    [self updateSettingsSummary];
}

- (void)persistHiddenApplications {
    [NSUserDefaults.standardUserDefaults setObject:self.hiddenApplicationPaths.allObjects forKey:@"HiddenApplicationPaths"];
}

- (void)updateSettingsSummary {
    self.settingsSummaryLabel.stringValue = [NSString stringWithFormat:@"已屏蔽 %lu 个应用", (unsigned long)self.hiddenApplicationPaths.count];
}

- (void)updateSettingsSearch {
    NSString *query = [self.settingsSearchField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].lowercaseString;
    if (query.length == 0) {
        self.settingsApplications = self.allApplications;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(LauncherApplication *application, NSDictionary *bindings) {
            return [application.searchText containsString:query];
        }];
        self.settingsApplications = [self.allApplications filteredArrayUsingPredicate:predicate];
    }
    [self.settingsTableView reloadData];
}

- (void)applyLauncherFilter {
    NSString *query = [self.searchField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].lowercaseString;
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(LauncherApplication *application, NSDictionary *bindings) {
        BOOL isVisible = ![self.hiddenApplicationPaths containsObject:application.URL.path];
        BOOL matchesSearch = query.length == 0 || [application.searchText containsString:query];
        return isVisible && matchesSearch;
    }];
    self.filteredApplications = [self.allApplications filteredArrayUsingPredicate:predicate];
    [self showPage:0];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == self.settingsSearchField) {
        [self updateSettingsSearch];
        return;
    }
    [self applyLauncherFilter];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.settingsApplications.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    LauncherSettingsCellView *cell = [tableView makeViewWithIdentifier:SettingsCellIdentifier owner:self];
    if (cell == nil) {
        cell = [[LauncherSettingsCellView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, 54.0)];
    }
    LauncherApplication *application = self.settingsApplications[row];
    BOOL blocked = [self.hiddenApplicationPaths containsObject:application.URL.path];
    [cell configureWithApplication:application blocked:blocked];
    cell.blockedCheckbox.target = self;
    cell.blockedCheckbox.action = @selector(settingsCheckboxChanged:);
    cell.blockedCheckbox.tag = row;
    return cell;
}

- (NSImage *)snapshotOfCollectionView {
    NSRect bounds = self.collectionView.bounds;
    if (NSIsEmptyRect(bounds)) return nil;
    NSBitmapImageRep *representation = [self.collectionView bitmapImageRepForCachingDisplayInRect:bounds];
    if (representation == nil) return nil;
    [self.collectionView cacheDisplayInRect:bounds toBitmapImageRep:representation];
    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
    [image addRepresentation:representation];
    return image;
}

- (void)showPage:(NSInteger)page {
    [self showPage:page animated:NO];
}

- (void)showPage:(NSInteger)page animated:(BOOL)animated {
    NSInteger count = self.filteredApplications.count;
    NSInteger pageCount = count == 0 ? 0 : (NSInteger)ceil((double)count / (double)self.itemsPerPage);
    NSInteger targetPage = pageCount == 0 ? 0 : MAX(0, MIN(pageCount - 1, page));
    NSInteger direction = targetPage > self.currentPage ? 1 : (targetPage < self.currentPage ? -1 : 0);
    BOOL shouldAnimate = animated
        && direction != 0
        && !self.pageTransitionInProgress
        && self.pageApplications.count > 0
        && self.collectionView.window != nil;

    NSImageView *outgoingView = nil;
    if (shouldAnimate) {
        NSImage *snapshot = [self snapshotOfCollectionView];
        if (snapshot != nil) {
            outgoingView = [[NSImageView alloc] initWithFrame:self.collectionView.frame];
            outgoingView.image = snapshot;
            outgoingView.imageScaling = NSImageScaleAxesIndependently;
            outgoingView.wantsLayer = YES;
            [self.collectionView.superview addSubview:outgoingView
                                           positioned:NSWindowAbove
                                           relativeTo:self.collectionView];
            self.pageTransitionInProgress = YES;
        } else {
            shouldAnimate = NO;
        }
    }

    if (pageCount == 0) {
        self.currentPage = 0;
        self.pageApplications = @[];
    } else {
        self.currentPage = targetPage;
        NSInteger start = self.currentPage * self.itemsPerPage;
        NSInteger length = MIN(self.itemsPerPage, count - start);
        self.pageApplications = [self.filteredApplications subarrayWithRange:NSMakeRange(start, length)];
    }
    [self.collectionView reloadData];
    NSCollectionViewFlowLayout *layout = (NSCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    NSInteger firstRowCount = MIN(self.columns, self.pageApplications.count);
    CGFloat occupiedWidth = firstRowCount > 0
        ? firstRowCount * self.itemWidth + (firstRowCount - 1) * self.columnSpacing
        : 0;
    CGFloat gridWidth = self.columns * self.itemWidth + (self.columns - 1) * self.columnSpacing;
    CGFloat horizontalInset = self.pageApplications.count < self.columns
        ? MAX(0, (gridWidth - occupiedWidth) / 2.0)
        : 0;
    layout.sectionInset = NSEdgeInsetsMake(0, horizontalInset, 0, horizontalInset);
    [layout invalidateLayout];
    [self.pageDots updateWithPageCount:pageCount currentPage:self.currentPage];

    if (self.finishedLoading && count == 0) {
        self.messageLabel.stringValue = @"没有找到应用";
        self.messageLabel.hidden = NO;
    } else if (self.finishedLoading) {
        self.messageLabel.hidden = YES;
    }

    if (!shouldAnimate) return;

    [self.collectionView layoutSubtreeIfNeeded];
    [self.collectionView displayIfNeeded];
    NSImage *incomingSnapshot = [self snapshotOfCollectionView];
    if (incomingSnapshot == nil) {
        [outgoingView removeFromSuperview];
        self.pageTransitionInProgress = NO;
        return;
    }

    CGFloat travelDistance = self.collectionView.bounds.size.width + 90.0;
    NSRect restingFrame = self.collectionView.frame;
    NSRect incomingStartFrame = restingFrame;
    incomingStartFrame.origin.x += direction * travelDistance;
    NSRect outgoingEndFrame = restingFrame;
    outgoingEndFrame.origin.x -= direction * travelDistance;

    NSImageView *incomingView = [[NSImageView alloc] initWithFrame:incomingStartFrame];
    incomingView.image = incomingSnapshot;
    incomingView.imageScaling = NSImageScaleAxesIndependently;
    incomingView.alphaValue = 0.58;
    incomingView.wantsLayer = YES;
    [self.collectionView.superview addSubview:incomingView
                                   positioned:NSWindowAbove
                                   relativeTo:outgoingView];
    self.collectionView.alphaValue = 0.0;

    __weak typeof(self) weakSelf = self;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.42;
        context.timingFunction =
            [CAMediaTimingFunction functionWithControlPoints:0.22 :0.72 :0.18 :1.0];
        outgoingView.animator.frame = outgoingEndFrame;
        outgoingView.animator.alphaValue = 0.18;
        incomingView.animator.frame = restingFrame;
        incomingView.animator.alphaValue = 1.0;
    } completionHandler:^{
        AppDelegate *strongSelf = weakSelf;
        strongSelf.collectionView.alphaValue = 1.0;
        [outgoingView removeFromSuperview];
        [incomingView removeFromSuperview];
        strongSelf.pageTransitionInProgress = NO;
    }];
}

- (void)showAdjacentPage:(NSInteger)direction {
    NSInteger count = self.filteredApplications.count;
    NSInteger pageCount = count == 0 ? 0 : (NSInteger)ceil((double)count / (double)self.itemsPerPage);
    NSInteger nextPage = self.currentPage + direction;
    if (nextPage < 0 || nextPage >= pageCount) return;
    [self showPage:nextPage animated:YES];
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.pageApplications.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    LauncherCollectionItem *item = (LauncherCollectionItem *)[collectionView makeItemWithIdentifier:LauncherItemIdentifier forIndexPath:indexPath];
    [item configureWithApplication:self.pageApplications[indexPath.item]];
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSIndexPath *indexPath = indexPaths.anyObject;
    if (indexPath == nil || indexPath.item >= self.pageApplications.count) return;
    [self launchApplication:self.pageApplications[indexPath.item]];
}

- (void)launchApplication:(LauncherApplication *)application {
    NSWorkspaceOpenConfiguration *configuration = NSWorkspaceOpenConfiguration.configuration;
    configuration.activates = YES;
    [NSWorkspace.sharedWorkspace
        openApplicationAtURL:application.URL
        configuration:configuration
        completionHandler:^(NSRunningApplication *runningApplication, NSError *error) {
            if (runningApplication != nil && error == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissLauncher];
                });
            }
        }];
}

- (void)installInputHandlers {
    __weak typeof(self) weakSelf = self;
    self.keyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
        AppDelegate *strongSelf = weakSelf;
        if (strongSelf == nil) return event;
        if (strongSelf.isDismissing) return nil;
        if (event.keyCode == 53) {
            if (!strongSelf.settingsBackdrop.hidden) {
                [strongSelf closeSettings:nil];
            } else {
                [strongSelf dismissLauncher];
            }
            return nil;
        }
        NSString *characters = event.charactersIgnoringModifiers.lowercaseString;
        if ((event.modifierFlags & NSEventModifierFlagCommand) && [characters isEqualToString:@"q"]) {
            [NSApp terminate:nil];
            return nil;
        }
        if ((event.modifierFlags & NSEventModifierFlagCommand) && [characters isEqualToString:@"k"]) {
            [strongSelf.window makeFirstResponder:strongSelf.settingsBackdrop.hidden ? strongSelf.searchField : strongSelf.settingsSearchField];
            return nil;
        }
        if (event.keyCode == 116) {
            [strongSelf showAdjacentPage:-1];
            return nil;
        }
        if (event.keyCode == 121) {
            [strongSelf showAdjacentPage:1];
            return nil;
        }
        return event;
    }];

    self.scrollMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskScrollWheel handler:^NSEvent *(NSEvent *event) {
        AppDelegate *strongSelf = weakSelf;
        if (strongSelf == nil) return event;
        if (strongSelf.isDismissing) return nil;
        if (!strongSelf.settingsBackdrop.hidden) return event;
        CGFloat horizontalDelta = event.scrollingDeltaX;
        CGFloat verticalDelta = event.scrollingDeltaY;
        CGFloat pageDelta = fabs(horizontalDelta) > fabs(verticalDelta) ? horizontalDelta : verticalDelta;
        if (fabs(pageDelta) < 0.01) return event;

        NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
        if (!event.hasPreciseScrollingDeltas) {
            if (now - strongSelf.lastPageChange > 0.35) {
                [strongSelf showAdjacentPage:pageDelta < 0 ? 1 : -1];
                strongSelf.lastPageChange = now;
            }
            return nil;
        }

        strongSelf.scrollAccumulator += pageDelta;
        if (fabs(strongSelf.scrollAccumulator) >= 70.0 && now - strongSelf.lastPageChange > 0.35) {
            [strongSelf showAdjacentPage:strongSelf.scrollAccumulator < 0 ? 1 : -1];
            strongSelf.lastPageChange = now;
            strongSelf.scrollAccumulator = 0;
        }
        if (event.phase == NSEventPhaseEnded || event.phase == NSEventPhaseCancelled) {
            strongSelf.scrollAccumulator = 0;
        }
        return nil;
    }];

    self.clickMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown handler:^NSEvent *(NSEvent *event) {
        AppDelegate *strongSelf = weakSelf;
        if (strongSelf == nil || event.window != strongSelf.window) return event;
        if (strongSelf.isDismissing) return nil;
        if (strongSelf.pageTransitionInProgress) return nil;

        NSView *contentView = strongSelf.window.contentView;
        NSPoint point = [contentView convertPoint:event.locationInWindow fromView:nil];
        NSView *hitView = [contentView hitTest:point];

        if (!strongSelf.settingsBackdrop.hidden) return event;

        if (hitView == strongSelf.searchPill || [hitView isDescendantOf:strongSelf.searchPill]
            || hitView == strongSelf.settingsButton || [hitView isDescendantOf:strongSelf.settingsButton]
            || hitView == strongSelf.pageDots || [hitView isDescendantOf:strongSelf.pageDots]) {
            return event;
        }

        for (NSCollectionViewItem *item in strongSelf.collectionView.visibleItems) {
            if (hitView == item.view || [hitView isDescendantOf:item.view]) {
                return event;
            }
        }

        [strongSelf dismissLauncher];
        return nil;
    }];
}

- (void)dismissLauncher {
    if (self.isDismissing) return;
    self.isDismissing = YES;
    __weak typeof(self) weakSelf = self;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.22;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        self.window.animator.alphaValue = 0.0;
    } completionHandler:^{
        AppDelegate *strongSelf = weakSelf;
        [NSApp setPresentationOptions:NSApplicationPresentationDefault];
        [strongSelf.window orderOut:nil];
        strongSelf.window.alphaValue = 1.0;
        strongSelf.isDismissing = NO;
        [NSApp hide:nil];
    }];
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp setPresentationOptions:NSApplicationPresentationDefault];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (self.keyMonitor != nil) [NSEvent removeMonitor:self.keyMonitor];
    if (self.scrollMonitor != nil) [NSEvent removeMonitor:self.scrollMonitor];
    if (self.clickMonitor != nil) [NSEvent removeMonitor:self.clickMonitor];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        [application run];
    }
    return 0;
}
