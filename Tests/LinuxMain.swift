import XCTest

import NIOAPNSJWTTests
import NIOAPNSTests

var tests = [XCTestCaseEntry]()
tests += NIOAPNSJWTTests.allTests()
tests += NIOAPNSTests.allTests()

XCTMain(tests)
