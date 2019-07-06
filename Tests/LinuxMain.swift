import XCTest

import APNSwiftJWTTests
import APNSwiftTests

var tests = [XCTestCaseEntry]()
tests += APNSwiftJWTTests.allTests()
tests += APNSwiftTests.allTests()

XCTMain(tests)
