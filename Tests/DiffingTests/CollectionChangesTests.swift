import XCTest
@testable import Diffing

class CollectionChangesTests : XCTestCase {
    let tests = [
        // empty
        (source: "", target: "",
         changeCount: 0, matchCount: 0, segmentCount: 0),

        // all inserts
        (source: "", target: "ABC",
         changeCount: 3, matchCount: 0, segmentCount: 1),

        // all removes
        (source: "ABC", target: "",
         changeCount: 3, matchCount: 0, segmentCount: 1),

        // all matches
        (source: "ABC", target: "ABC",
         changeCount: 0, matchCount: 3, segmentCount: 1),

        // all removes and inserts
        (source: "ABCD", target: "EFG",
         changeCount: 7, matchCount: 0, segmentCount: 2),

        // myers
        (source: "ABCABBA", target: "CBABAC",
         changeCount: 5, matchCount: 4, segmentCount: 7),

        // myers swapped
        (source: "CBABAC", target: "ABCABBA",
         changeCount: 5, matchCount: 4, segmentCount: 8),

        // myers even delta
        (source: "ABCABBAA", target: "CBABAC",
         changeCount: 6, matchCount: 4, segmentCount: 8),

        // odd delta
        (source: "XYABYX", target: "YBY",
         changeCount: 3, matchCount: 3, segmentCount: 5),

        // even delta
        (source: "XYABYX", target: "YBCY",
         changeCount: 4, matchCount: 3, segmentCount: 7),

        // d = 1
        (source: "XABX", target: "XBX",
         changeCount: 1, matchCount: 3, segmentCount: 3),

        // delta 0
        (source: "BA", target: "AC",
         changeCount: 2, matchCount: 1, segmentCount: 3),

        (source: "AC", target: "BA",
         changeCount: 2, matchCount: 1, segmentCount: 3),

        // delta 1
        (source: "AB", target: "A",
         changeCount: 1, matchCount: 1, segmentCount: 2),

        (source: "AB", target: "B",
         changeCount: 1, matchCount: 1, segmentCount: 2),

        (source: "A", target: "AB",
         changeCount: 1, matchCount: 1, segmentCount: 2),

        (source: "B", target: "AB",
         changeCount: 1, matchCount: 1, segmentCount: 2),

        // delta 2
        (source: "ABC", target: "A",
         changeCount: 2, matchCount: 1, segmentCount: 2),

        (source: "ABC", target: "B",
         changeCount: 2, matchCount: 1, segmentCount: 3),

        (source: "ABC", target: "C",
         changeCount: 2, matchCount: 1, segmentCount: 2),

        (source: "ABCD", target: "AB",
         changeCount: 2, matchCount: 2, segmentCount: 2),

        (source: "ABCD", target: "CD",
         changeCount: 2, matchCount: 2, segmentCount: 2),

        (source: "XABCD", target: "XCD",
         changeCount: 2, matchCount: 3, segmentCount: 3),
    ]

    func testChanges() {
        func checkChanges<C1 : OrderedCollection, C2 : OrderedCollection>(
            from source: C1,
            to target: C2,
            changeCount expectedChangeCount: Int,
            matchCount expectedMatchCount: Int,
            segmentCount expectedSegmentCount: Int
        ) where C1.Element == C2.Element, C1.Element : Equatable {
            let m = " from: \(source) to: \(target)"

            var changeCount = 0
            var matchCount = 0
            var segmentCount = 0
            for segment in CollectionChanges(from: source, to: target, by: ==) {
                switch segment {
                case let .removed(x):
                    changeCount += source[x].count
                case let .inserted(y):
                    changeCount += target[y].count
                case let .matched(x, y):
                    XCTAssert(
                        source[x].elementsEqual(target[y]), "elementsEqual" + m)
                    matchCount += source[x].count
                }
                segmentCount += 1
            }

            XCTAssertEqual(
                changeCount, expectedChangeCount, "changeCount" + m)
            XCTAssertEqual(
                matchCount, expectedMatchCount, "matchCount" + m)
            XCTAssertEqual(
                segmentCount, expectedSegmentCount, "segmentCount" + m)
        }

        // array
        for (source, target, changeCount, matchCount, segmentCount) in tests {
            checkChanges(
                from: Array(source),
                to: Array(target),
                changeCount: changeCount,
                matchCount: matchCount,
                segmentCount: segmentCount)
        }

        // string
        for (source, target, changeCount, matchCount, segmentCount) in tests {
            checkChanges(
                from: source,
                to: target,
                changeCount: changeCount,
                matchCount: matchCount,
                segmentCount: segmentCount)
        }
    }

    func testFormChanges() {
        func checkFormChanges<C1 : OrderedCollection, C2 : OrderedCollection>(
            _ difference: inout CollectionChanges<C1.Index, C2.Index>,
            from source: C1,
            to target: C2,
            changeCount expectedChangeCount: Int,
            matchCount expectedMatchCount: Int,
            segmentCount expectedSegmentCount: Int
        ) where C1.Element == C2.Element, C1.Element : Equatable {
            let m = " from: \(source) to: \(target)"

            var changeCount = 0
            var matchCount = 0
            var segmentCount = 0
            difference.formChanges(from: source, to: target, by: ==)
            for segment in difference {
                switch segment {
                case let .removed(x):
                    changeCount += source[x].count
                case let .inserted(y):
                    changeCount += target[y].count
                case let .matched(x, y):
                    XCTAssert(
                        source[x].elementsEqual(target[y]), "elementsEqual" + m)
                    matchCount += source[x].count
                }
                segmentCount += 1
            }

            XCTAssertEqual(
                changeCount, expectedChangeCount, "changeCount" + m)
            XCTAssertEqual(
                matchCount, expectedMatchCount, "matchCount" + m)
            XCTAssertEqual(
                segmentCount, expectedSegmentCount, "segmentCount" + m)
        }

        // array
        var difference = CollectionChanges<Int, Int>()
        for (source, target, changeCount, matchCount, segmentCount) in tests {
            checkFormChanges(
                &difference,
                from: Array(source),
                to: Array(target),
                changeCount: changeCount,
                matchCount: matchCount,
                segmentCount: segmentCount)
        }

        // string
        var difference2 = CollectionChanges<String.Index, String.Index>()
        for (source, target, changeCount, matchCount, segmentCount) in tests {
            checkFormChanges(
                &difference2,
                from: source,
                to: target,
                changeCount: changeCount,
                matchCount: matchCount,
                segmentCount: segmentCount)
        }
    }

    static var allTests = [
        ("testChanges", testChanges),
        ("testFormChanges", testFormChanges),
    ]
}
