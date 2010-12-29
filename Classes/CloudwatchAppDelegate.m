//
//  CloudwatchAppDelegate.m
//  Cloudwatch
//
//  Created by Dmitri Goutnik on 21/12/2010.
//  Copyright 2010 Tundra Bot. All rights reserved.
//

#import "CloudwatchAppDelegate.h"
#import "DataSource.h"
#import "ChartView.h"
#import "Preferences.h"

@interface CloudwatchAppDelegate ()
- (void)loadPreferences;
- (void)resetMenu;
- (void)refreshMenu:(NSNotification *)notification;
- (NSMenuItem *)titleItemWithTitle:(NSString *)title;
- (NSMenuItem *)instanceItemWithInstance:(EC2Instance *)instance;
- (NSMenuItem *)chartItemWithRange:(NSUInteger)range datapoints:(NSArray *)datapoints;
- (NSMenuItem *)infoItemWithLabel:(NSString *)label info:(NSString *)info action:(SEL)action tooltip:(NSString *)tooltip;
- (NSMenuItem *)actionItemWithLabel:(NSString *)label action:(SEL)action;
- (NSMenu *)submenuForInstance:(EC2Instance *)instance;
- (void)refreshSubmenu:(NSMenu *)menu forInstance:(EC2Instance *)instance;
- (void)refresh:(NSString *)instanceId;
- (void)refreshCompleted:(NSNotification *)notification;
- (void)preferencesDidChange:(NSNotification *)notification;
- (void)quitAction:(id)sender;
- (void)editPreferencesAction:(id)sender;
- (void)copyToPasteboardAction:(id)sender;
- (void)connectToInstanceAction:(id)sender;
@end

@implementation CloudwatchAppDelegate

static NSColor *_titleColor;
static NSColor *_taggedInstanceColor;
static NSColor *_untaggedInstanceColor;
static NSColor *_actionItemColor;
static NSColor *_labelColumnColor;
static NSColor *_infoColumnColor;

static NSFont *_titleFont;
static NSFont *_taggedInstanceFont;
static NSFont *_untaggedInstanceFont;
static NSFont *_actionItemFont;
static NSFont *_labelColumnFont;
static NSFont *_infoColumnFont;

static NSDictionary *_titleAttributes;
static NSDictionary *_taggedInstanceAttributes;
static NSDictionary *_untaggedInstanceAttributes;
static NSDictionary *_actionItemAttributes;
static NSDictionary *_labelColumnAttributes;
static NSDictionary *_infoColumnAttributes;

+ (void)initialize
{
	if (!_titleColor)				_titleColor = [[NSColor colorWithDeviceRed:(0.f/255.f) green:(112.f/255.f) blue:(180.f/255.f) alpha:1.f] retain];
	if (!_taggedInstanceColor)		_taggedInstanceColor = [[NSColor blackColor] retain];
	if (!_untaggedInstanceColor)	_untaggedInstanceColor = [[NSColor blackColor] retain];
	if (!_actionItemColor)			_actionItemColor = [[NSColor blackColor] retain];
	if (!_labelColumnColor)			_labelColumnColor = [[NSColor blackColor] retain];
	if (!_infoColumnColor)			_infoColumnColor = [[NSColor blackColor] retain];
		
	if (!_titleFont)				_titleFont = [[NSFont boldSystemFontOfSize:10.0f] retain];
	if (!_taggedInstanceFont)		_taggedInstanceFont = [[NSFont boldSystemFontOfSize:13.0f] retain];
	if (!_untaggedInstanceFont)		_untaggedInstanceFont = [[NSFont systemFontOfSize:13.0f] retain];
	if (!_actionItemFont)			_actionItemFont = [[NSFont boldSystemFontOfSize:11.0f] retain];
	if (!_labelColumnFont)			_labelColumnFont = [[NSFont systemFontOfSize:11.0f] retain];
	if (!_infoColumnFont)			_infoColumnFont = [[NSFont boldSystemFontOfSize:11.0f] retain];

	if (!_titleAttributes)
		_titleAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
							 _titleColor, NSForegroundColorAttributeName,
							 _titleFont, NSFontAttributeName,
							 [NSNumber numberWithFloat:8.f], NSBaselineOffsetAttributeName,
							 nil] retain];
	
	if (!_taggedInstanceAttributes)
		_taggedInstanceAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
									  _taggedInstanceColor, NSForegroundColorAttributeName,
									  _taggedInstanceFont, NSFontAttributeName,
									  nil] retain];

	if (!_taggedInstanceAttributes)
		_untaggedInstanceAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
										_untaggedInstanceColor, NSForegroundColorAttributeName,
										_untaggedInstanceFont, NSFontAttributeName,
										nil] retain];

	if (!_actionItemAttributes)
		_actionItemAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
								  _actionItemColor, NSForegroundColorAttributeName,
								  _actionItemFont, NSFontAttributeName,
								  nil] retain];

	if (!_labelColumnAttributes)
		_labelColumnAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
								   _labelColumnColor, NSForegroundColorAttributeName,
								   _labelColumnFont, NSFontAttributeName,
								   //labelParagraphStyle, NSParagraphStyleAttributeName,
								   nil] retain];
	if (!_infoColumnAttributes)
		_infoColumnAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
								  _infoColumnColor, NSForegroundColorAttributeName,
								  _infoColumnFont, NSFontAttributeName,
								  //infoParagraphStyle, NSParagraphStyleAttributeName,
								  nil] retain];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// register preferences set through Preferences helper app
	[[NSUserDefaults standardUserDefaults] addSuiteNamed:@"com.tundrabot.CloudwatchPreferences"];
	
	// observe notifications from Preferences app
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(preferencesDidChange:)
															name:kPreferencesDidChangeNotification
														  object:nil];
	
	// load current preferences
	[self loadPreferences];
	
	// set up status item menu
	_statusMenu = [[NSMenu alloc] initWithTitle:@""];
	[_statusMenu setShowsStateColumn:NO];
	[_statusMenu setDelegate:self];
	[self resetMenu];
	
	// set up status item
	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:30.f] retain];
	[_statusItem setImage:[NSImage imageNamed:@"StatusItem.png"]];
	[_statusItem setMenu:_statusMenu];
	
	// set up pasteboard
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	// subscribe to data source notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(refreshCompleted:)
												 name:kDataSourceRefreshCompletedNotification
											   object:[DataSource sharedInstance]];

	// perform initial refresh
	[self refresh:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// unsubscribe from notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
	TBRelease(_statusItem);
	TBRelease(_statusMenu);
	TBRelease(_preferencesController);
	[super dealloc];
}

#pragma mark -
#pragma mark Status menu

- (void)resetMenu
{
	[_statusMenu removeAllItems];
	
//	[_statusMenu addItem:[self actionItemWithLabel:@"Refresh" action:@selector(refreshAction:)]];
	[_statusMenu addItem:[NSMenuItem separatorItem]];
	[_statusMenu addItem:[self actionItemWithLabel:@"Preferences..." action:@selector(editPreferencesAction:)]];
	[_statusMenu addItem:[self actionItemWithLabel:@"Quit Cloudwatch" action:@selector(quitAction:)]];
}

- (void)refreshMenu:(NSNotification *)notification
{
	DataSource *dataSource = [DataSource sharedInstance];
	
	if ([dataSource.instances count] > 0) {
		NSError *error = [[notification userInfo] objectForKey:kDataSourceErrorInfoKey];
		NSString *instanceId = [[notification userInfo] objectForKey:kDataSourceInstanceIdInfoKey];
		
		if (error) {
			// TODO: handle error notification
		}
		else {
			if ([instanceId length] > 0) {
				TBTrace(@"refreshCompleted: %@", instanceId);
				
				NSUInteger instanceIdx = [dataSource.instances indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
					*stop = [[obj instanceId] isEqualToString:instanceId];
					return *stop;
				}];
				
				NSUInteger menuItemIdx = [[_statusMenu itemArray] indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
					*stop = [obj hasSubmenu] && [[[obj submenu] title] isEqualToString:instanceId];
					return *stop;
				}];
				
				if (instanceIdx != NSNotFound && menuItemIdx != NSNotFound) {
					EC2Instance *instance = [dataSource.instances objectAtIndex:instanceIdx];
					NSMenu *instanceSubmenu = [[[_statusMenu itemArray] objectAtIndex:menuItemIdx] submenu];
					
					[self refreshSubmenu:instanceSubmenu forInstance:instance];
				}
			}
			else {
				TBTrace(@"refreshCompleted:");
				
				[_statusMenu removeAllItems];
				
				[_statusMenu addItem:[self titleItemWithTitle:@"INSTANCES"]];
				for (EC2Instance *instance in dataSource.instances) {
					[_statusMenu addItem:[self instanceItemWithInstance:instance]];
				}
				
				// Add chart
				[_statusMenu addItem:[NSMenuItem separatorItem]];
				[_statusMenu addItem:[self titleItemWithTitle:@"CPU UTILIZATION"]];
				[_statusMenu addItem:[self chartItemWithRange:kAWSLastHourRange datapoints:[dataSource statisticsForMetric:kAWSCPUUtilizationMetric]]];
				
				CGFloat maxCPUUtilization = [dataSource maximumValueForMetric:kAWSCPUUtilizationMetric forRange:kAWSLastHourRange];
				CGFloat minCPUUtilization = [dataSource minimumValueForMetric:kAWSCPUUtilizationMetric forRange:kAWSLastHourRange];
				CGFloat avgCPUUtilization = [dataSource averageValueForMetric:kAWSCPUUtilizationMetric forRange:kAWSLastHourRange];
				
				[_statusMenu addItem:[self infoItemWithLabel:@"Maximum" info:[NSString stringWithFormat:@"%.1f%%", maxCPUUtilization] action:NULL tooltip:nil]];
				[_statusMenu addItem:[self infoItemWithLabel:@"Minimum" info:[NSString stringWithFormat:@"%.1f%%", minCPUUtilization] action:NULL tooltip:nil]];
				[_statusMenu addItem:[self infoItemWithLabel:@"Average" info:[NSString stringWithFormat:@"%.1f%%", avgCPUUtilization] action:NULL tooltip:nil]];
				
				// Add action menu items
				//			[_statusMenu addItem:[NSMenuItem separatorItem]];
				//			[_statusMenu addItem:[self actionItemWithLabel:@"Refresh" action:@selector(refreshAction:)]];
				[_statusMenu addItem:[NSMenuItem separatorItem]];
				[_statusMenu addItem:[self actionItemWithLabel:@"Preferences..." action:@selector(editPreferencesAction:)]];
				[_statusMenu addItem:[self actionItemWithLabel:@"Quit Cloudwatch" action:@selector(quitAction:)]];
			}
		}
	}
	else {
		[self resetMenu];
	}
}

- (NSMenuItem *)titleItemWithTitle:(NSString *)title
{
	NSMutableAttributedString *attributedTitle = [[[NSMutableAttributedString alloc] initWithString:title
																						 attributes:_titleAttributes] autorelease];
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setMinimumLineHeight:20.f];
	
	[attributedTitle addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attributedTitle length])];
	
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""] autorelease];
	[menuItem setIndentationLevel:1];
	[menuItem setAttributedTitle:attributedTitle];
	[menuItem setEnabled:NO];
	
	return menuItem;
}

- (NSMenuItem *)instanceItemWithInstance:(EC2Instance *)instance
{
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""] autorelease];
	[menuItem setIndentationLevel:1];
	
	NSString *nameTag = instance.nameTag;
	NSAttributedString *attributedTitle = nil;

	// Set item title to Name tag if present, otherwise to Instance ID
	if (nameTag)
		attributedTitle = [[[NSAttributedString alloc] initWithString:nameTag attributes:_taggedInstanceAttributes] autorelease];
	else
		attributedTitle = [[[NSAttributedString alloc] initWithString:instance.instanceId attributes:_untaggedInstanceAttributes] autorelease];
	
	menuItem.attributedTitle = attributedTitle;
	
	// Set item image according to instance state
	switch (instance.instanceState.code) {
		case EC2_INSTANCE_STATE_RUNNING:
			menuItem.image = [NSImage imageNamed:@"InstanceStateRunning.png"];
			break;
		case EC2_INSTANCE_STATE_STOPPED:
			menuItem.image = [NSImage imageNamed:@"InstanceStateStopped.png"];
			break;
		case EC2_INSTANCE_STATE_TERMINATED:
			menuItem.image = [NSImage imageNamed:@"InstanceStateTerminated.png"];
			break;
		default:
			menuItem.image = [NSImage imageNamed:@"InstanceStateOther.png"];
			break;
	}
	
	// Set item submenu
	menuItem.submenu = [self submenuForInstance:instance];
	
	return menuItem;
	
}

- (NSMenuItem *)chartItemWithRange:(NSUInteger)range datapoints:(NSArray *)datapoints
{
	ChartView *chartView = [[[ChartView alloc] initWithRange:range datapoints:datapoints] autorelease];

	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""] autorelease];
	[menuItem setIndentationLevel:1];
	[menuItem setView:chartView];
	
	return menuItem;
}

#define TABLE_WIDTH				220.f
#define LABEL_COLUMN_WIDTH		90.f

- (NSMenuItem *)infoItemWithLabel:(NSString *)label info:(NSString *)info action:(SEL)action tooltip:(NSString *)tooltip
{
	NSTextTable *table = [[[NSTextTable alloc] init] autorelease];
	[table setNumberOfColumns:2];
	[table setLayoutAlgorithm:NSTextTableAutomaticLayoutAlgorithm];
	[table setContentWidth:TABLE_WIDTH type:NSTextBlockAbsoluteValueType];
	[table setHidesEmptyCells:NO];
	
	NSTextTableBlock *labelBlock = [[NSTextTableBlock alloc] initWithTable:table startingRow:0 rowSpan:1 startingColumn:0 columnSpan:1];
	[labelBlock setContentWidth:LABEL_COLUMN_WIDTH type:NSTextBlockAbsoluteValueType];
	
	NSTextTableBlock *infoBlock = [[NSTextTableBlock alloc] initWithTable:table startingRow:0 rowSpan:1 startingColumn:1 columnSpan:1];
	
	NSMutableParagraphStyle *labelParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[labelParagraphStyle setAlignment:NSLeftTextAlignment];
	[labelParagraphStyle setTextBlocks:[NSArray arrayWithObject:labelBlock]];
	
	NSMutableParagraphStyle *infoParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[infoParagraphStyle setAlignment:NSRightTextAlignment];
	[infoParagraphStyle setTextBlocks:[NSArray arrayWithObject:infoBlock]];
	
	NSMutableAttributedString *attributedTitle = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	
	NSUInteger textLength = [attributedTitle length];
	[attributedTitle replaceCharactersInRange:NSMakeRange(textLength, 0) withString:[NSString stringWithFormat:@"%@\n", (label ? label : @" ")]];
	[attributedTitle setAttributes:_labelColumnAttributes range:NSMakeRange(textLength, [attributedTitle length] - textLength)];
	[attributedTitle addAttribute:NSParagraphStyleAttributeName value:labelParagraphStyle range:NSMakeRange(textLength, [attributedTitle length] - textLength)];
	
	textLength = [attributedTitle length];
	[attributedTitle replaceCharactersInRange:NSMakeRange(textLength, 0) withString:[NSString stringWithFormat:@"%@", (info ? info : @" ")]];
	[attributedTitle setAttributes:_infoColumnAttributes range:NSMakeRange(textLength, [attributedTitle length] - textLength)];
	[attributedTitle addAttribute:NSParagraphStyleAttributeName value:infoParagraphStyle range:NSMakeRange(textLength, [attributedTitle length] - textLength)];
	
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:action keyEquivalent:@""] autorelease];
	
	[menuItem setIndentationLevel:1];
	[menuItem setAttributedTitle:attributedTitle];
	[menuItem setTarget:self];
	[menuItem setToolTip:tooltip];
	[menuItem setEnabled:action != NULL];
	
	return menuItem;
}

- (NSMenuItem *)actionItemWithLabel:(NSString *)label action:(SEL)action
{
	NSMutableAttributedString *attributedTitle = [[[NSMutableAttributedString alloc] initWithString:label
																						 attributes:_actionItemAttributes] autorelease];
	
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:action keyEquivalent:@""] autorelease];
	[menuItem setIndentationLevel:1];
	[menuItem setAttributedTitle:attributedTitle];
	[menuItem setTarget:self];
	
	return menuItem;
}

#pragma mark -
#pragma mark Submenu

- (NSMenu *)submenuForInstance:(EC2Instance *)instance
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[menu setDelegate:self];
	[menu setTitle:instance.instanceId];
	[menu setShowsStateColumn:NO];
	
	[self refreshSubmenu:menu forInstance:instance];

	return menu;
}

- (void)refreshSubmenu:(NSMenu *)menu forInstance:(EC2Instance *)instance
{
	DataSource *dataSource = [DataSource sharedInstance];
	
	[menu removeAllItems];
	
	[menu addItem:[self titleItemWithTitle:@"INSTANCE DETAILS"]];
	[menu addItem:[self infoItemWithLabel:@"Instance ID" info:instance.instanceId action:@selector(copyToPasteboardAction:) tooltip:@"Copy Instance ID"]];
	[menu addItem:[self infoItemWithLabel:@"Image ID" info:instance.imageId action:@selector(copyToPasteboardAction:) tooltip:@"Copy Image ID"]];
	[menu addItem:[self infoItemWithLabel:@"State" info:instance.instanceState.name action:NULL tooltip:nil]];
	[menu addItem:[self infoItemWithLabel:@"Launched At" info:[instance.launchTime localizedString] action:NULL tooltip:nil]];
	[menu addItem:[self infoItemWithLabel:@"Monitoring" info:instance.monitoring.monitoringType action:NULL tooltip:nil]];
	
	if ([instance.ipAddress length] > 0) {
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItem:[self titleItemWithTitle:@"NETWORKING"]];
		[menu addItem:[self infoItemWithLabel:@"Public IP" info:instance.ipAddress action:@selector(copyToPasteboardAction:) tooltip:@"Copy Public IP"]];
		[menu addItem:[self infoItemWithLabel:@"Private IP" info:instance.privateIpAddress action:@selector(copyToPasteboardAction:) tooltip:@"Copy Private IP"]];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[self titleItemWithTitle:@"CPU UTILIZATION"]];
	[menu addItem:[self chartItemWithRange:kAWSLastHourRange datapoints:[dataSource statisticsForMetric:kAWSCPUUtilizationMetric forInstance:instance.instanceId]]];

	if ([[dataSource statisticsForMetric:kAWSCPUUtilizationMetric forInstance:instance.instanceId] count] > 0) {
		CGFloat maxCPUUtilization = [dataSource maximumValueForMetric:kAWSCPUUtilizationMetric forInstance:instance.instanceId forRange:kAWSLastHourRange];
		CGFloat minCPUUtilization = [dataSource minimumValueForMetric:kAWSCPUUtilizationMetric forInstance:instance.instanceId forRange:kAWSLastHourRange];
		CGFloat avgCPUUtilization = [dataSource averageValueForMetric:kAWSCPUUtilizationMetric forInstance:instance.instanceId forRange:kAWSLastHourRange];
		
		[menu addItem:[self infoItemWithLabel:@"Maximum" info:[NSString stringWithFormat:@"%.1f%%", maxCPUUtilization] action:NULL tooltip:nil]];
		[menu addItem:[self infoItemWithLabel:@"Minimum" info:[NSString stringWithFormat:@"%.1f%%", minCPUUtilization] action:NULL tooltip:nil]];
		[menu addItem:[self infoItemWithLabel:@"Average" info:[NSString stringWithFormat:@"%.1f%%", avgCPUUtilization] action:NULL tooltip:nil]];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[self actionItemWithLabel:@"Connect..." action:@selector(connectToInstanceAction:)]];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[self actionItemWithLabel:@"Restart..." action:@selector(connectToInstanceAction:)]];
	[menu addItem:[self actionItemWithLabel:@"Terminate..." action:@selector(connectToInstanceAction:)]];
}

#pragma mark -
#pragma mark DataSource operations and notifications

- (void)refresh:(NSString *)instanceId
{
	if ([instanceId length] > 0) {
		// Refresh monitoring data for a single instance
		[[DataSource sharedInstance] refreshInstance:instanceId];
	}
	else {
		// Refresh instances and composite monitoring data for all instances
		[[DataSource sharedInstance] refresh];
	}
}

- (void)refreshCompleted:(NSNotification *)notification
{
	[self performSelector:@selector(refreshMenu:)
			   withObject:notification
			   afterDelay:0.
				  inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil]];
//	[self performSelectorOnMainThread:@selector(refreshMenu:) withObject:notification waitUntilDone:NO];
//	[self performSelectorOnMainThread:@selector(refreshMenu:) withObject:notification waitUntilDone:NO modes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
//	[self refreshMenu:notification];
}

#pragma mark -
#pragma mark Menu delegate

- (void)menuWillOpen:(NSMenu *)menu
{
	[self refresh:[menu title]];
}

#pragma mark -
#pragma mark User Defaults

- (void)loadPreferences
{
	TBTrace(@" reloading");
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults synchronize];

	// set AWS credentials and region
	NSString *awsAccessKeyId = [userDefaults stringForKey:kPreferencesAWSAccessKeyIdKey];
	NSString *awsSecretAccessKey = [userDefaults stringForKey:kPreferencesAWSSecretAccessKeyKey];
	
	NSString *awsRegion = kAWSUSEastRegion;
	switch ([userDefaults integerForKey:kPreferencesAWSRegionKey]) {
		case kPreferencesAWSUSEastRegion:
			awsRegion = kAWSUSEastRegion;
			break;
		case kPreferencesAWSUSWestRegion:
			awsRegion = kAWSUSWestRegion;
			break;
		case kPreferencesAWSEURegion:
			awsRegion = kAWSEURegion;
			break;
		case kPreferencesAWSAsiaPacificRegion:
			awsRegion = kAWSAsiaPacificRegion;
			break;
	}
	
	[DataSource setDefaultRequestOptions:[NSDictionary dictionaryWithObjectsAndKeys:
										  awsAccessKeyId, kAWSAccessKeyIdOption,
										  awsSecretAccessKey, kAWSSecretAccessKeyOption,
										  awsRegion, kAWSRegionOption,
										  nil]];
}

- (void)preferencesDidChange:(NSNotification *)notification
{
	TBTrace(@"preferencesDidChange: %@", notification);
	[self loadPreferences];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	TBTrace(@"observeValueForKeyPath: %@", keyPath);
}

#pragma mark -
#pragma mark Actions

- (void)quitAction:(id)sender
{
	[[NSApplication sharedApplication] terminate:self];
}

- (void)editPreferencesAction:(id)sender
{
	NSString *preferencesBundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Helpers/CloudwatchPreferences.app"];
	[[NSWorkspace sharedWorkspace] launchApplication:preferencesBundlePath];
}

- (void)copyToPasteboardAction:(id)sender
{
}

- (void)connectToInstanceAction:(id)sender
{
}

@end
