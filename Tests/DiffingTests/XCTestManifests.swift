import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CollectionChangesTests.allTests),
        testCase(CommonPrefixTests.allTests),
        testCase(OrderedCollectionDifferenceTests.allTests),
        testCase(OrderedCollectionTests.allTests),
        testCase(RangeReplaceableCollectionTests.allTests),
        testCase(TriangularMatrixTests.allTests),
    ]
}
#endif
