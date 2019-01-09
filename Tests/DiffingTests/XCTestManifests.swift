import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BidirectionalCollectionTests.allTests),
        testCase(OrderedCollectionDifferenceTests.allTests),
        testCase(RangeReplaceableCollectionTests.allTests),
    ]
}
#endif
