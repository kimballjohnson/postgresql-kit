//
//  PGServerKit_testcases.m
//  PGServerKit_testcases
//
//  Created by David Thorpe on 04/01/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

@interface PGServerKit_testcases : XCTestCase

@end

@implementation PGServerKit_testcases

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
