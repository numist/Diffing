import XCTest
@testable import Diffing

final class OrderedCollectionDifferenceTests: XCTestCase {
    func testEmpty() {
        guard let diff = OrderedCollectionDifference<String>([]) else {
            XCTFail()
            return
        }
        XCTAssertEqual(0, diff.insertions.count)
        XCTAssertEqual(0, diff.removals.count)
        XCTAssertEqual(true, diff.isEmpty)

        var c = 0
        diff.forEach({ _ in c += 1 })
        XCTAssertEqual(0, c)
    }

    // Create diffs with 100 changes ranging from 0 inserts and 100 removes to
    // 100 inserts and 0 removes and verify that the counts are accurate.
    func testInsertionCounts() {
        for i in 0..<100 {
            var c = [OrderedCollectionDifference<Int>.Change]()

            var insertions = 0
            for insertIndex in 0..<i {
                c.append(.insert(offset:insertIndex, element: 42, associatedWith: nil))
                insertions += 1
            }

            var removals = 0
            for removeIndex in i..<100 {
                c.append(.remove(offset: removeIndex, element: 42, associatedWith: nil))
                removals += 1
            }

            guard let diff = OrderedCollectionDifference<Int>(c) else {
                XCTFail()
                return
            }

            XCTAssertEqual(insertions, diff.insertions.count)
            XCTAssertEqual(removals, diff.removals.count)
        }
    }

    func testValidChanges() {
        // Base case: one insert and one remove with legal offsets
        XCTAssertNotNil(OrderedCollectionDifference<Int>.init([
            .insert(offset: 0, element: 0, associatedWith: nil),
            .remove(offset: 0, element: 0, associatedWith: nil)
        ]))

        // Code coverage:
        // • non-first change .remove has legal associated offset
        // • non-first change .insert has legal associated offset
        XCTAssertNotNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 1, element: 0, associatedWith: 0),
            .remove(offset: 0, element: 0, associatedWith: 1),
            .insert(offset: 0, element: 0, associatedWith: 1),
            .insert(offset: 1, element: 0, associatedWith: 0)
        ]))
    }

    func testInvalidChanges() {
        // Base case: two inserts sharing the same offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .insert(offset: 0, element: 0, associatedWith: nil),
            .insert(offset: 0, element: 0, associatedWith: nil)
        ]))

        // Base case: two removes sharing the same offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 0, element: 0, associatedWith: nil),
            .remove(offset: 0, element: 0, associatedWith: nil)
        ]))

        // Base case: illegal insertion offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .insert(offset: -1, element: 0, associatedWith: nil)
        ]))

        // Base case: illegal remove offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: -1, element: 0, associatedWith: nil)
        ]))

        // Base case: two inserts sharing same associated offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .insert(offset: 0, element: 0, associatedWith: 0),
            .insert(offset: 1, element: 0, associatedWith: 0)
        ]))

        // Base case: two removes sharing same associated offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 0, element: 0, associatedWith: 0),
            .remove(offset: 1, element: 0, associatedWith: 0)
        ]))

        // Base case: insert with illegal associated offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .insert(offset: 0, element: 0, associatedWith: -1)
        ]))

        // Base case: remove with illegal associated offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 1, element: 0, associatedWith: -1)
        ]))

        // Code coverage: non-first change has illegal offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 0, element: 0, associatedWith: nil),
            .insert(offset: -1, element: 0, associatedWith: nil)
        ]))

        // Code coverage: non-first change has illegal associated offset
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 0, element: 0, associatedWith: nil),
            .insert(offset: 0, element: 0, associatedWith: -1)
        ]))
    }

    func testForEachOrder() {
        let safelyOrderedChanges: [OrderedCollectionDifference<Int>.Change] = [
            .remove(offset: 2, element: 0, associatedWith: nil),
            .remove(offset: 1, element: 0, associatedWith: 0),
            .remove(offset: 0, element: 0, associatedWith: 1),
            .insert(offset: 0, element: 0, associatedWith: 1),
            .insert(offset: 1, element: 0, associatedWith: 0),
            .insert(offset: 2, element: 0, associatedWith: nil),
        ]
        let diff = OrderedCollectionDifference<Int>.init(safelyOrderedChanges)!
        var enumerationOrderedChanges = [OrderedCollectionDifference<Int>.Change]()
        diff.forEach { c in
            enumerationOrderedChanges.append(c)
        }
        XCTAssert(safelyOrderedChanges == enumerationOrderedChanges)
    }

    func testBadAssociations() {
        // .remove(1) → .insert(1)
        //     ↑            ↓
        // .insert(0) ← .remove(0)
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 1, element: 0, associatedWith: 1),
            .remove(offset: 0, element: 0, associatedWith: 0),
            .insert(offset: 0, element: 0, associatedWith: 1),
            .insert(offset: 1, element: 0, associatedWith: 0)
        ]))

        // Coverage: duplicate remove offsets both with assocs
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .remove(offset: 0, element: 0, associatedWith: 1),
            .remove(offset: 0, element: 0, associatedWith: 0),
        ]))

        // Coverage: duplicate insert assocs
        XCTAssertNil(OrderedCollectionDifference<Int>.init([
            .insert(offset: 0, element: 0, associatedWith: 1),
            .insert(offset: 1, element: 0, associatedWith: 1),
        ]))
    }

    // Full-coverage test for OrderedCollectionDifference.Change.==()
    func testChangeEquality() {
        // Differs by type:
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.insert(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.remove(offset: 0, element: 0, associatedWith: 0)
        )

        // Differs by type in the other direction:
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.remove(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.insert(offset: 0, element: 0, associatedWith: 0)
        )

        // Insert differs by offset
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.insert(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.insert(offset: 1, element: 0, associatedWith: 0)
        )

        // Insert differs by element
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.insert(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.insert(offset: 0, element: 1, associatedWith: 0)
        )

        // Insert differs by association
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.insert(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.insert(offset: 0, element: 0, associatedWith: 1)
        )

        // Remove differs by offset
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.remove(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.remove(offset: 1, element: 0, associatedWith: 0)
        )

        // Remove differs by element
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.remove(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.remove(offset: 0, element: 1, associatedWith: 0)
        )

        // Remove differs by association
        XCTAssertFalse(
            OrderedCollectionDifference<Int>.Change.remove(offset: 0, element: 0, associatedWith: 0) ==
            OrderedCollectionDifference<Int>.Change.remove(offset: 0, element: 0, associatedWith: 1)
        )
    }

    func testHashableConformance() {
        let _ = Set<OrderedCollectionDifference<String>>();
    }
    
    func testMoveInference() {
        let n = OrderedCollectionDifference<String>.init([
            .insert(offset: 3, element: "Sike", associatedWith: nil),
            .insert(offset: 4, element: "Sike", associatedWith: nil),
            .insert(offset: 2, element: "Hello", associatedWith: nil),
            .remove(offset: 6, element: "Hello", associatedWith: nil),
            .remove(offset: 8, element: "Goodbye", associatedWith: nil),
            .remove(offset: 9, element: "Sike", associatedWith: nil),
        ])
        let w = OrderedCollectionDifference<String>.init([
            .insert(offset: 3, element: "Sike", associatedWith: nil),
            .insert(offset: 4, element: "Sike", associatedWith: nil),
            .insert(offset: 2, element: "Hello", associatedWith: 6),
            .remove(offset: 6, element: "Hello", associatedWith: 2),
            .remove(offset: 8, element: "Goodbye", associatedWith: nil),
            .remove(offset: 9, element: "Sike", associatedWith: nil),
        ])
        XCTAssertEqual(w, n?.inferringMoves())
    }
    
    func testDemo3Way() {
        let base = "Is\nit\ntime\nalready?"
        let theirs = "Hi\nthere\nis\nit\ntime\nalready?"
        let mine = "Is\nit\nreview\ntime\nalready?"
        
        // Split the contents of the sources into lines
        let baseLines = base.components(separatedBy: "\n")
        let theirLines = theirs.components(separatedBy: "\n")
        let myLines = mine.components(separatedBy: "\n")
        
        // Create a difference from base to theirs
        let diff = theirLines.shortestEditScript(from:baseLines)
        
        // Apply it to mine, if possible
        guard let patchedLines = myLines.applying(diff) else {
            print("Merge conflict applying patch, manual merge required")
            return
        }
        
        // Reassemble the result
        let patched = patchedLines.joined(separator: "\n")
        XCTAssertEqual(patched, "Hi\nthere\nis\nit\nreview\ntime\nalready?")
        print(patched)
    }
    
    func testDemoReverse() {
        let diff = OrderedCollectionDifference<Int>([])!
        let reversed = OrderedCollectionDifference<Int>(
            diff.map({(change) -> OrderedCollectionDifference<Int>.Change in
                switch change {
                case .insert(offset: let o, element: let e, associatedWith: let a):
                    return .remove(offset: o, element: e, associatedWith: a)
                case .remove(offset: let o, element: let e, associatedWith: let a):
                    return .insert(offset: o, element: e, associatedWith: a)
                }
            })
        )!
        print(reversed)
    }
    
    func testApplyByEnumeration() {
        let base = "Is\nit\ntime\nalready?"
        let theirs = "Hi\nthere\nis\nit\ntime\nalready?"
        
        // Split the contents of the sources into lines
        var arr = base.components(separatedBy: "\n")
        let theirLines = theirs.components(separatedBy: "\n")
        
        // Create a difference from base to theirs
        let diff = theirLines.shortestEditScript(from:arr)
        
        for c in diff {
            switch c {
            case .remove(offset: let o, element: _, associatedWith: _):
                arr.remove(at: o)
            case .insert(offset: let o, element: let e, associatedWith: _):
                arr.insert(e, at: o)
            }
        }
        
        XCTAssertEqual(arr, theirLines)
    }

    static var allTests = [
        ("testEmpty", testEmpty),
        ("testInsertionCounts", testInsertionCounts),
        ("testValidChanges", testValidChanges),
        ("testInvalidChanges", testInvalidChanges),
        ("testForEachOrder", testForEachOrder),
        ("testBadAssociations", testBadAssociations),
        ("testChangeEquality", testChangeEquality),
        ("testHashableConformance", testHashableConformance),
        ("testMoveInference", testMoveInference),
        ("testDemo3Way", testDemo3Way),
        ("testDemoReverse", testDemoReverse),
        ("testApplyByEnumeration", testApplyByEnumeration),
    ]
}
