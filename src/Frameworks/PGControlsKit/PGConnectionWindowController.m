
#import <PGClientKit/PGClientKit.h>
#import "PGControlsKit.h"

////////////////////////////////////////////////////////////////////////////////

@interface PGConnectionWindowController ()

// properties
@property (weak,nonatomic) IBOutlet NSWindow* ibPasswordWindow;
@property BOOL isDefaultPort;
@property BOOL isUseKeychain;
@property (readonly) NSMutableDictionary* params;
@property (readonly) NSString* username;

// ibactions
-(IBAction)ibButtonClicked:(id)sender;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnectionWindowController

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_password = [PGPasswordStore new];
		_connection = [PGConnection new];
		_params = [NSMutableDictionary new];
		NSParameterAssert(_password && _connection && _params);
		[_connection setDelegate:self];
	}
	return self;
}

-(NSString* )windowNibName {
	return @"PGConnectionWindow";
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize password = _password;
@synthesize params = _params;
@synthesize ibPasswordWindow;
@synthesize isDefaultPort;
@synthesize isUseKeychain;
@dynamic url;

-(NSURL* )url {
	return [NSURL URLWithPostgresqlParams:[self params]];
}

-(void)setUrl:(NSURL* )url {
	NSParameterAssert(url);
	NSDictionary* params = [url postgresqlParameters];
	if(params) {
		[_params removeAllObjects];
		[_params setDictionary:params];
	} else {
		NSLog(@"Error: setUrl: Unable to set parameters from URL: %@",url);
	}
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)windowDidLoad {
    [super windowDidLoad];
	// set some defaults
	[self setIsDefaultPort:YES];
}

-(void)_setDefaultValues {
	// set user
	NSString* user = [[self params] objectForKey:@"user"];
	if([user length]==0) {
		user = NSUserName();
		[self willChangeValueForKey:@"params.user"];
		[[self params] setObject:user forKey:@"user"];
		[self didChangeValueForKey:@"params.user"];
	}
	NSParameterAssert([user isKindOfClass:[NSString class]]);

	// set dbname
	NSString* dbname = [[self params] objectForKey:@"dbname"];
	if([dbname length]==0) {
		dbname = user;
		[self willChangeValueForKey:@"params.dname"];
		[[self params] setObject:dbname forKey:@"dbname"];
		[self didChangeValueForKey:@"params.dbname"];
	}
	NSParameterAssert([dbname isKindOfClass:[NSString class]]);

	// set host
	NSString* host = [[self params] objectForKey:@"host"];
	if([host length]==0) {
		host = @"localhost";
		[self willChangeValueForKey:@"params.host"];
		[[self params] setObject:host forKey:@"host"];
		[self didChangeValueForKey:@"params.host"];
	}
	
	// set port
	NSNumber* defaultPort = [NSNumber numberWithInteger:PGClientDefaultPort];
	if([self isDefaultPort] && [[[self params] objectForKey:@"port"] isNotEqualTo:defaultPort]) {
		[self willChangeValueForKey:@"params.port"];
		[[self params] setObject:defaultPort forKey:@"port"];
		[self didChangeValueForKey:@"params.port"];
	}
}

////////////////////////////////////////////////////////////////////////////////
// private methods - key-value observing

-(void)_registerAsObserver {
	for(NSString* keyPath in @[ @"isDefaultPort",@"params.host", @"params.ssl", @"params.user", @"params.dbname", @"params.port" ]) {
		[self addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}

-(void)_deregisterAsObserver {
	for(NSString* keyPath in @[ @"params.host", @"params.ssl", @"params.user", @"params.dbname", @"params.port" ]) {
		[self removeObserver:self forKeyPath:keyPath];
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	NSLog(@"%@ => %@",keyPath,change);
	[self _setDefaultValues];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow {
	// register as observer
	[self _registerAsObserver];

	// set parameters
	[self _setDefaultValues];
	
	// start sheet
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)beginPasswordSheetForParentWindow:(NSWindow* )parentWindow {
	// TODO: set password

	// start sheet
	[NSApp beginSheet:[self ibPasswordWindow] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)endSheet:(NSWindow* )theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	// remove sheet
	[theSheet orderOut:self];

	// remove observer
	[self _deregisterAsObserver];
	
	// determine return status
	PGConnectionWindowStatus status = PGConnectionWindowStatusOK;
	
	// if cancel button is pressed
	if(returnCode==NSModalResponseCancel) {
		status = PGConnectionWindowStatusCancel;
	} else if (returnCode==NSModalResponseOK && [self url]==nil) {
		status = PGConnectionWindowStatusBadParameters;
	} else {
		status = PGConnectionWindowStatusOK;
	}

	// send message to delegate
	[[self delegate] connectionWindow:self status:status];
}

-(void)connect {
	if([self url]==nil) {
		[[self delegate] connectionWindow:self status:PGConnectionWindowStatusBadParameters];
		return;
	}
	[[self connection] connectInBackgroundWithURL:[self url] whenDone:^(NSError* error){
		if([error code]==PGClientErrorNeedsPassword) {
			[[self delegate] connectionWindow:self status:PGConnectionWindowStatusNeedsPassword];
		}
	}];
}

-(void)disconnect {
	if([[self connection] status]==PGConnectionStatusConnected) {
		[[self connection] disconnect];
	}
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibButtonClicked:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed, immediately quit
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSModalResponseCancel];
	} else {
		// Do something here
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSModalResponseOK];
	}
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate delegate implementation

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {
	// store and retrieve password
	NSParameterAssert([self password]);
	NSError* error = nil;
	if([dictionary objectForKey:@"password"]) {
		NSError* error = nil;
		[[self password] setPassword:[dictionary objectForKey:@"password"] forURL:[self url] saveToKeychain:YES error:&error];
	} else {
		NSString* password = [[self password] passwordForURL:[self url] error:&error];
		if(password) {
			[dictionary setObject:password forKey:@"password"];
		}
	}
	if(error) {
		[self connection:connection error:error];
	}
}

-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status {
	NSLog(@"status change=%d",status);
}

/*
	// disconnected
	if([self stopping] && status==PGConnectionStatusDisconnected) {
		// indicate server connection has been shutdown
		[self stoppedWithReturnValue:0];
		return;
	}
	
	// connected
	//if(status==PGConnectionStatusConnected && [self shouldStorePassword] && [self temporaryPassword]) {
	//	PGPasswordStore* store = [PGPasswordStore new];
	//	NSLog(@"TODO: Store password: %@",[self temporaryPassword]);
	//}
	
}
*/

-(void)connection:(PGConnection* )connection error:(NSError* )theError {
	if([[self delegate] respondsToSelector:@selector(connectionWindow:error:)]) {
		[[self delegate] connectionWindow:self error:theError];
	} else {
		NSLog(@"Connection Error: %@",theError);
	}
}

@end
