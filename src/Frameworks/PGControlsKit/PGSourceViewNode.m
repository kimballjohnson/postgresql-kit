
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <PGControlsKit/PGControlsKit.h>
#import "PGSourceViewHeading.h"
#import "PGSourceViewConnection.h"

@interface PGSourceViewNode ()
// private definitions here
@end

@implementation PGSourceViewNode

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithName:(NSString* )name {
	self = [super init];
	if(self) {
		_name = name;
	}
	return self;
}

+(PGSourceViewNode* )headingWithName:(NSString* )name {
	return [[PGSourceViewHeading alloc] initWithName:name];
}

+(PGSourceViewNode* )connectionWithURL:(NSURL* )url {
	NSString* name = [NSString stringWithFormat:@"%@@%@",[url user],[url path]];
	return [[PGSourceViewConnection alloc] initWithName:name];
}

+(PGSourceViewNode* )nodeFromDictionary:(NSDictionary* )dictionary {
	NSString* className = [dictionary objectForKey:@"class"];
	NSString* name = [dictionary objectForKey:@"name"];
	if(className==nil || name==nil) {
		return nil;
	}
	Class c = NSClassFromString(className);
	if(c==nil || [c isSubclassOfClass:[PGSourceViewNode class]]==NO) {
		return nil;
	}
	PGSourceViewNode* node = (PGSourceViewNode* )[[c alloc] initWithName:name];
	// set other properties for node
	return node;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize name = _name;
@dynamic isGroupItem;
@dynamic shouldSelectItem;

-(BOOL)isGroupItem {
	return YES;
}

-(BOOL)shouldSelectItem {
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ %@>",NSStringFromClass([self class]),[self name]];
}

-(NSDictionary* )dictionaryWithKey:(id)key {
	NSMutableDictionary* defaults = [NSMutableDictionary new];
	[defaults setObject:key forKey:@"key"];
	[defaults setObject:[self name] forKey:@"name"];
	[defaults setObject:NSStringFromClass([self class]) forKey:@"class"];
	return defaults;
}

-(NSTableCellView* )cellViewForOutlineView:(NSOutlineView* )outlineView tableColumn:(NSTableColumn* )tableColumn owner:(id)owner {
	NSTableCellView* cellView = nil;
	if([self isGroupItem]) {
		cellView = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:owner];
	} else {
		cellView = [outlineView makeViewWithIdentifier:@"DataCell" owner:owner];
	}	
	[[cellView textField] setStringValue:[self name]];
	return cellView;
}




@end
