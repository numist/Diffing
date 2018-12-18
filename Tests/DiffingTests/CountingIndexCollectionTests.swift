import XCTest
@testable import Diffing

class CountingIndexCollectionTests : XCTestCase {
    func testCountingIndexCollection() {
        let empty = CountingIndexCollection([])
        XCTAssertEqual(Array(empty.indices), [])
        XCTAssertEqual(empty.startIndex, CountingIndex(base: 0, offset: nil))
        XCTAssertEqual(empty.endIndex, CountingIndex(base: 0, offset: nil))

        let abc = CountingIndexCollection(["A", "B", "C"])
        XCTAssertEqual(
            Array(abc.indices),
            [
                CountingIndex(base: 0, offset: 0),
                CountingIndex(base: 1, offset: 1),
                CountingIndex(base: 2, offset: 2)
            ]
        )
        XCTAssertEqual(abc.startIndex, CountingIndex(base: 0, offset: 0))
        XCTAssertEqual(abc.endIndex, CountingIndex(base: 3, offset: nil))

        let cba = CountingIndexCollection(["A", "B", "C"].reversed())
        XCTAssertEqual(
            Array(cba.indices),
            [
                CountingIndex(base: ReversedCollection.Index(3), offset: 0),
                CountingIndex(base: ReversedCollection.Index(2), offset: 1),
                CountingIndex(base: ReversedCollection.Index(1), offset: 2)
            ]
        )
        XCTAssertEqual(cba.startIndex, CountingIndex(base: ReversedCollection.Index(3), offset: 0))
        XCTAssertEqual(cba.endIndex, CountingIndex(base: ReversedCollection.Index(0), offset: nil))
    }

    static var allTests = [
        ("testCountingIndexCollection", testCountingIndexCollection),
    ]
}