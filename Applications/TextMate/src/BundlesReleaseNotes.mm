#import "BundlesReleaseNotes.h"
#import <OakFoundation/NSString Additions.h>
#import <updater/updater.h>

@interface BundlesReleaseNotes ()
@property (nonatomic, assign) WebView* webView;
@end

@implementation BundlesReleaseNotes
- (id)init
{
	NSRect visibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect rect = NSMakeRect(0, 0, std::min<CGFloat>(700, NSWidth(visibleRect)), std::min<CGFloat>(800, NSHeight(visibleRect)));

	CGFloat dy = NSHeight(visibleRect) - NSHeight(rect);

	rect.origin.y = round(NSMinY(visibleRect) + dy*3/4);
	rect.origin.x = NSMaxY(visibleRect) - NSMaxY(rect);

	NSWindow* win = [[[NSWindow alloc] initWithContentRect:rect styleMask:(NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask|NSMiniaturizableWindowMask) backing:NSBackingStoreBuffered defer:NO] autorelease];
	if((self = [super initWithWindow:win]))
	{
		NSView* contentView = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
		[win setContentView:contentView];
		[win setFrameAutosaveName:@"BundlesReleaseNotes"];
		[win setDelegate:self];
		[win setAutorecalculatesKeyViewLoop:YES];
		[win setReleasedWhenClosed:NO];

		WebView* webView = [[[WebView alloc] initWithFrame:[contentView bounds]] autorelease];
		self.webView = webView;
		webView.translatesAutoresizingMaskIntoConstraints = NO;
		webView.frameLoadDelegate = self;
		[contentView addSubview:webView];

		NSDictionary* views = NSDictionaryOfVariableBindings(webView);
		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView(>=200)]|" options:NSLayoutFormatAlignAllTop     metrics:nil views:views]];
		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView(>=200)]|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];

		[self retain];
	}
	return self;
}

- (void)dealloc
{
	[self.webView setFrameLoadDelegate:nil];
	[[self.webView mainFrame] stopLoading];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification*)aNotification
{
	[self autorelease];
}

+ (void)installReleaseNotesMenuItem:(id)sender
{
	for(NSMenuItem* item in [[[NSApp mainMenu] itemArray] reverseObjectEnumerator])
	{
		if([[item submenu] indexOfItemWithTarget:nil andAction:@selector(showHelp:)] != -1)
		{
			[[[item submenu] addItemWithTitle:@"Bundles Release Notes" action:@selector(showBundlesReleaseNotes:) keyEquivalent:@""] setTarget:self];
			break;
		}
	}
}

+ (void)showBundlesReleaseNotes:(id)sender
{
	BundlesReleaseNotes* obj = [[[self alloc] init] autorelease];

	NSURL* bundlesReleaseNotesURL = [[NSBundle mainBundle] URLForResource:@"bundle_release_notes" withExtension:@"html"];
	[[obj.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:bundlesReleaseNotesURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60]];

	[obj.window makeKeyAndOrderFront:self];
}

- (void)webView:(WebView*)aWebView didFinishLoadForFrame:(WebFrame*)aFrame
{
	WebScriptObject* scriptObject = [aWebView windowScriptObject];
	[scriptObject callWebScriptMethod:@"setJSON" withArguments:@[ [NSString stringWithCxxString:bundles_db::changes_as_json()] ]];
}
@end