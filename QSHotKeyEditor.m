

NSString * stringForModifiers( unsigned int aModifierFlags );

#import "QSHotKeyEditor.h"

#import "NDHotKeyEvent.h"
#import "NDHotKeyEvent_QSMods.h"

@implementation QSHotKeyCell
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj{
	NSLog(@"set up editor %@",textObj);
	id instance=[QSHotKeyFieldEditor sharedInstance];
	[super setUpFieldEditorAttributes:instance];
	return instance;
}
- (id) init {
	self = [super init];
	if (self != nil) {
		[self setEditable:YES];
		[self setSelectable:YES];
		[self setBezeled:YES];
	}
	return self;
}

- (void)validateEditing{
	NSLog(@"validate");
}



@end

@implementation QSHotKeyControl
+ (Class)cellClass{
	return [QSHotKeyCell class];
}
- (void)awakeFromNib{
	[self setCell:[[[QSHotKeyCell alloc]init]autorelease]];
}
- (void)textDidEndEditing:(NSNotification*)aNotification{
	NSLog(@"notif %@",aNotification);
}
- (void)setStringValue:(NSString *)string{
	NSLog(@"string %@",string);
	//if ([thisTrigger objectForKey:@"keyCode"] &&[thisTrigger objectForKey:@"modifiers"]){
	//		QSHotKeyEvent *activationKey=(QSHotKeyEvent *)[QSHotKeyEvent getHotKeyForKeyCode:[[thisTrigger objectForKey:@"keyCode"] shortValue]
	//																			   character:0
	//																	   safeModifierFlags:[[thisTrigger objectForKey:@"modifiers"] intValue]];
	//		return [activationKey stringValue];
	//		return @"nil";
	
	
	
	//	return [ KeyCombo keyComboWithKeyCode:[[thisTrigger objectForKey:@"keyCode"]shortValue]
	//							 andModifiers:[[thisTrigger objectForKey:@"modifiers"]longValue]];
	[super setStringValue:string];
	
	
	}
@end




//#import "KeyCombo.h"
typedef int CGSConnection;
typedef enum {
    CGSGlobalHotKeyEnable = 0,
    CGSGlobalHotKeyDisable = 1,
} CGSGlobalHotKeyOperatingMode;

extern CGSConnection _CGSDefaultConnection(void);

extern CGError CGSGetGlobalHotKeyOperatingMode(
                                               CGSConnection connection, CGSGlobalHotKeyOperatingMode *mode);

extern CGError CGSSetGlobalHotKeyOperatingMode(CGSConnection connection, 
                                               CGSGlobalHotKeyOperatingMode mode);




@implementation QSHotKeyFieldEditor
+ (id)sharedInstance{
	static NSWindowController *_sharedInstance = nil;
    if (!_sharedInstance)
        _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

- (void)_disableHotKeyOperationMode{
    CGSConnection conn = _CGSDefaultConnection();
    CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
	[NSApp setGlobalKeyEquivalentTarget:self];
}
- (void)_restoreHotKeyOperationMode{
    CGSConnection conn = _CGSDefaultConnection();
    CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
	[NSApp setGlobalKeyEquivalentTarget:nil];
}

- (void)_windowDidBecomeKeyNotification:(id)fp8{
	[self _disableHotKeyOperationMode];
}
- (void)_windowDidResignKeyNotification:(id)fp8{
    [self _restoreHotKeyOperationMode];
}

- (id)init{
    if (self=[super init]){
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:NSApplicationWillResignActiveNotification object:nil];
		//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:NSWindowDidResignKeyNotification object:nil];
		[self setFieldEditor:YES];
		[self alignCenter:nil];
		//NSButton *cancelButton=[[NSButton alloc]initWithFrame:NSMakeRect(0,0,16,16)];
		
		//[self addSubview:cancelButton];
		[self setSelectable:NO];
		[cancelButton setAutoresizingMask:NSViewMinXMargin];
		[cancelButton setTarget:self];
		[cancelButton setAction:@selector(clear:)];
		[cancelButton setTitle:@"x"];
	}
    return self;
}
- (void)viewDidMoveToWindow{
	//	[cancelButton setBounds:NSMakeRect(NSWidth([self bounds])-16,0,16,16)];
}

- (void)clear:(id)sender{
}
- (void)dealloc{
    [super dealloc];
}
- (BOOL)shouldSendEvent:(NSEvent *)event{
	if([event type]==NSKeyDown){
		[self keyDown:event];
		return NO;
	}
	return YES;
}
//- (void)setString:(NSString *)string{
//	[super setString:string];
//	[self setSelectedRange:NSMakeRange(0,[string length])];
//}
- (void)setSelectedRange:(NSRange)charRange{
	//NSLog(@"select %d %d '%@'",charRange.location,charRange.length,[self string]);	
	[super setSelectedRange:charRange];
}
- (BOOL)becomeFirstResponder{
	defaultString=[[self string]copy];
	
	BOOL status=[super becomeFirstResponder];
    validCombo=NO;
	[NSApp addEventDelegate:self];
	//	
    [self _disableHotKeyOperationMode];
	[self setSelectedRange:NSMakeRange(0,[[self string] length])];
	return status;
}
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity{
	return NSMakeRange(0,[[super string]length]);
}

- (BOOL)resignFirstResponder{
	[defaultString release];
	defaultString=nil;
	[NSApp removeEventDelegate:self];
    [self _restoreHotKeyOperationMode];
    return [super resignFirstResponder];
}
- (void)cancel{
	if ([[self window]firstResponder]==self){
		[[self window] makeFirstResponder:[self delegate]];   
	}
}


- (void)flagsChanged:(NSEvent *)theEvent{
	NSString *newString=stringForModifiers([theEvent modifierFlags]);
	[self setString:[newString length]?newString:defaultString];	
	//[self setSelectedRange:NSMakeRange(0,[[self string] length])];
	//[self setDelegate:nil];
}


- (void)setDictionaryStringWithEvent:(NSEvent *)theEvent{
	unsigned int modifiers=[theEvent modifierFlags];
	unsigned short keyCode=[theEvent keyCode];
	NSString *characters=[theEvent charactersIgnoringModifiers];
	if (keyCode == 48){
		characters=@"\t";
	}
	//	NSLog(@"event %@",theEvent);
    if ([theEvent modifierFlags] & (NSCommandKeyMask|NSFunctionKeyMask|NSControlKeyMask|NSAlternateKeyMask)){
       	NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:modifiers],@"modifiers",
			[NSNumber numberWithUnsignedShort:keyCode],@"keyCode",
			characters,@"character",
			nil];
		
		validCombo=YES;
		NSString *string=[[[NSString alloc]initWithData:[NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:nil]
											   encoding:NSUTF8StringEncoding]autorelease];
		
		[self setString:string];
		//NSLog(@"event %@ %x",theEvent,[theEvent modifierFlags] & (NSCommandKeyMask|NSFunctionKeyMask|NSControlKeyMask|NSAlternateKeyMask));
		
	}else  if ([theEvent keyCode] == 53){
        //if (VERBOSE) NSLog(@"Cancelling");
		
		[self setString:@"Old"];
	}else  if ([theEvent keyCode] == 48){ //Tab
										  //[super sendEvent:theEvent];
		
	}else  if ([theEvent keyCode] == 51){ //Delete
		validCombo=YES;
		NSString *string=[[[NSString alloc]initWithData:[NSPropertyListSerialization dataFromPropertyList:[NSDictionary dictionary] format:NSPropertyListXMLFormat_v1_0 errorDescription:nil]
											   encoding:NSUTF8StringEncoding]autorelease];
		
		[self setString:string];
    }else{
        NSBeep();
	}
	//[[self delegate]endEditing];
	[[self window] makeFirstResponder:nil];//[self delegate]];
}

- (void)keyDown:(NSEvent *)theEvent;
{[self setDictionaryStringWithEvent:theEvent];
}
- (BOOL)performKeyEquivalent:(id)theEvent;
{
	[self setDictionaryStringWithEvent:theEvent];
	return YES;}


- (NSString *)string{
    if (validCombo) return [super string];
    return @"Old";
}
@end


@implementation QSHotKeyField
+ (void)initialize{
	[self exposeBinding:@"hotKey"];	
	//[self exposeBinding:@"value"];	
	//[self setKeys:[NSArray arrayWithObject:@"hotKey"] triggerChangeNotificationsForDependentKey:@"value"];
}
/*
 * -initWithFrame:
 */
- (id)initWithFrame:(NSRect)aFrame
{
    if ( self = [super initWithFrame:aFrame] )
	{
		[self setEditable:NO];
    }
    return self;
}

/*
 * -initWithCoder:
 */
- (id)initWithCoder:(NSCoder *)aCoder
{
	if ( self = [super initWithCoder:aCoder] )
	{
		[self setEditable:NO];
	}
	return self;
}

- (void)awakeFromNib{
	
	// Remap value binding to hotKey dictionary
	NSDictionary *binding=[self infoForBinding:@"value"];
	[self unbind:@"value"];
	[self bind:@"hotKey" toObject:[binding objectForKey:NSObservedObjectKey]
   withKeyPath:[binding objectForKey:NSObservedKeyPathKey]
	   options:[binding objectForKey:NSOptionsKey]];

		//NSLog(@"binding %@ %@",[self infoForBinding:@"hotKey"],[[NSUserDefaultsController sharedUserDefaultsController]infoForBinding:@"values.QSActivationHotKey"]);
	
		
//	[[[NSUserDefaultsController sharedUserDefaultsController]values]
//bind:@"QSActivationHotKey"
//		toObject:self
//		withKeyPath:@"hotKey"
//		options:nil];
}

- (NSDictionary *)hotKeyDictForEvent:(NSEvent *)event{
	unsigned int modifiers=[event modifierFlags];
	unsigned short keyCode=[event keyCode];
	NSString *character=[event charactersIgnoringModifiers];
	if (keyCode == 48){
		character=@"\t";
	}
	
	NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt:modifiers],@"modifiers",
		[NSNumber numberWithUnsignedShort:keyCode],@"keyCode",
		//character,@"character",
		nil];
	return dict;
}

- (NSDictionary *)hotKey { return [[hotKey retain] autorelease]; }
- (void)setHotKey:(NSDictionary *)newHotKey
{
	//NSLog(@"setHotKey: %@",newHotKey);
    if (hotKey != newHotKey) {
		//[self willChangeValueForKey:@"value"];
        [hotKey release];
        hotKey = [newHotKey retain];
		//[self didChangeValueForKey:@"value"];
		NSDictionary *binding=[self infoForBinding:@"hotKey"];
		if (binding)
			[[binding objectForKey:NSObservedObjectKey] setValue:hotKey forKeyPath:[binding objectForKey:NSObservedKeyPathKey]];
	
		[self updateStringForHotKey];
    }
}

- (void)updateStringForHotKey{
	if ([hotKey isKindOfClass:[NSDictionary class]]){
		NSString *descrip=[[QSHotKeyEvent hotKeyWithDictionary:hotKey] stringValue];
		[self setStringValue:descrip?descrip:@""];
	}else if (hotKey){
		[self setStringValue:@"invalid"];
	}else{ 
		[self setStringValue:@""];
	}
}
- (IBAction)set:(id)sender{
	[self absorbEvents];
}

- (void)mouseDown:(NSEvent *)event{
	
	[self absorbEvents];
}


- (void)timerFire:(NSTimer *)timer{
//	NSLog(@"fire");	
	NSTimeInterval t=[[NSDate date]timeIntervalSinceReferenceDate];
	t=fmod(t,1.0);
	t=(sin(t*M_PI*2)+1)/2;
	
	NSColor *newColor=[[NSColor textBackgroundColor] blendedColorWithFraction:t
																	  ofColor:[NSColor selectedTextBackgroundColor]];
	
		[self setBackgroundColor:newColor];
	//	[self setNeedsDisplay:YES];
}
- (void)absorbEvents{
	[[self window]makeFirstResponder:self];
	NSTimer *timer=[[NSTimer alloc]initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1] interval:0.1 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
	//	[timer fire]; 
	
//	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	[self setBackgroundColor:[NSColor selectedTextBackgroundColor]];
	[setButton setState:NSOnState];
	[[self cell]setPlaceholderString:[self stringValue]];
	[self setStringValue:@"Set Keys"];
	[[self window]display];
	NSEvent *theEvent=nil;
	
	CGSConnection conn = _CGSDefaultConnection();
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
	BOOL collectEvents=YES;
	while(collectEvents){
		theEvent=[NSApp nextEventMatchingMask:NSKeyDownMask|NSFlagsChangedMask|NSLeftMouseDownMask|NSAppKitDefinedMask|NSSystemDefinedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:10.0] inMode:NSDefaultRunLoopMode dequeue:YES];
		switch ([theEvent type]){
			case NSKeyDown:
				{
				//	unsigned int modifiers=[theEvent modifierFlags];
					unsigned short keyCode=[theEvent keyCode];
					NSString *characters=[theEvent charactersIgnoringModifiers];
					if (keyCode == 48) characters=@"\t";
					
					if ([theEvent modifierFlags] & (NSCommandKeyMask|NSFunctionKeyMask|NSControlKeyMask|NSAlternateKeyMask)){
						//[self setObjectValue:[self hotKeyDictForEvent:theEvent]];
	
						[self setHotKey:[self hotKeyDictForEvent:theEvent]];
						collectEvents=NO; 
					}else  if ([theEvent keyCode] == 53){ //Escape
						collectEvents=NO; 
					}else  if ([theEvent keyCode] == 48){ //Tab
						[[self window]makeFirstResponder:[self nextKeyView]];
						collectEvents=NO;
					}else  if ([theEvent keyCode] == 51){ //Delete
						[self setHotKey:nil];
						collectEvents=NO; 
					}else{
						NSBeep();
					}
				}					
					break;
			case NSFlagsChanged:
			{
				NSString *newString=stringForModifiers([theEvent modifierFlags]);
				NSLog(newString);
				[self setStringValue:[newString length]?newString:@""];	
				[self display];
				[setButton display];
				break;
			}
			case NSSystemDefinedMask:
			case NSAppKitDefinedMask:
			case NSLeftMouseDown:
				if (![self containsEvent:theEvent] && ![setButton containsEvent:theEvent]){
					//Absorb events on self or setButton
					[NSApp postEvent:theEvent atStart:YES];
				}
					
					
			
				collectEvents=NO;
			default:
				break;
		}
	}
	[timer invalidate];
	[timer release];
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
	[self updateStringForHotKey];
	[self setBackgroundColor:[NSColor textBackgroundColor]];
	[setButton setState:NSOffState];

}


@end
