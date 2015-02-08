
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

@interface PGTabViewController ()

@end

@implementation PGTabViewController


////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
    self = [super initWithNibName:@"PGTabView" bundle:[NSBundle bundleForClass:[self class]]];
	if(self) {
		_views = [NSMutableDictionary new];
		NSParameterAssert(_views);
	}
	return self;
}

-(void)awakeFromNib {
	// do things here
}


////////////////////////////////////////////////////////////////////////////////
// private methods

+(id)keyForTag:(NSInteger)tag {
	return [NSNumber numberWithInteger:tag];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(NSViewController* )viewWithTag:(NSInteger)tag {
	id key = [PGTabViewController keyForTag:tag];
	NSParameterAssert(key);
	NSViewController* view = [_views objectForKey:key];
	if(view==nil && [[self delegate] respondsToSelector:@selector(tabView:newViewForTag:)]) {
		view = [[self delegate] tabView:self newViewForTag:tag];
		if(view) {
			[_views setObject:view forKey:key];
		}
	}
	return view;
}

@end
