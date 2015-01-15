
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

#import "PGConnectionWindowFormatter.h"

@implementation PGConnectionWindowFormatter

-(void)awakeFromNib {
	if(!_cs) {
		_cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
	}
}

-(NSNumber* )numericValueForString:(NSString* )string {
	NSParameterAssert(_cs);
	if([string length]==0) {
		return nil;
	}
	NSString* string2 = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSRange range = [string2 rangeOfCharacterFromSet:_cs];
	if(range.location != NSNotFound) {
		return nil;
	}
	return [NSDecimalNumber decimalNumberWithString:string];
}


-(NSString* )stringForObjectValue:(id)anObject {
	return [NSString stringWithFormat:@"%@",anObject];
}

-(BOOL)getObjectValue:(id* )anObject forString:(NSString* )string errorDescription:(NSString** )anError {
	NSParameterAssert(anObject);
	NSParameterAssert(string);
	BOOL returnValue = YES;
	NSNumber* port = [self numericValueForString:string];
	NSString* error = nil;
	if(port==nil) {
		error = @"Invalid value";
		returnValue = NO;
	} else {
		*anObject = port;
	}
	if(anError) {
		*anError = error;
	}
	return returnValue;
}
@end
