import XCTest

import DiffingTests

var tests = [XCTestCaseEntry]()
tests += DiffingTests.allTests()
XCTMain(tests)