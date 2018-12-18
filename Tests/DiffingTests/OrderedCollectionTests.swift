import XCTest
@testable import Diffing

final class OrderedCollectionTests: XCTestCase {
    func testEmpty() {
        let a = [Int]()
        let b = [Int]()
        let diff = b.difference(from: a)

        XCTAssertEqual(diff, a.difference(from: a))
        XCTAssertEqual(true, diff.isEmpty)
    }

    func testDifference() {
        let expectedChanges: [(
            source: [String],
            target: [String],
            changes: [OrderedCollectionDifference<String>.Change],
            line: UInt
        )] = [
            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             changes: [],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Presents",
                 "New Years", "Champagne"],
             changes: [
                .remove(offset: 5, element: "Lights", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel", "Gelt",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             changes: [
                 .insert(offset: 3, element: "Gelt", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Presents", "Tree", "Lights",
                 "New Years", "Champagne"],
             changes: [
                 .remove(offset: 6, element: "Presents", associatedWith: 4),
                 .insert(offset: 4, element: "Presents", associatedWith: 6)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Lights", "Presents", "Tree",
                 "New Years", "Champagne"],
             changes: [
                 .remove(offset: 4, element: "Tree", associatedWith: 6),
                 .insert(offset: 6, element: "Tree", associatedWith: 4)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel", "Presents",
                 "Xmas", "Tree", "Lights",
                 "New Years", "Champagne"],
             changes: [
                 .remove(offset: 6, element: "Presents", associatedWith: 3),
                 .insert(offset: 3, element: "Presents", associatedWith: 6)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights",
                 "New Years", "Champagne", "Presents"],
             changes: [
                 .remove(offset: 6, element: "Presents", associatedWith: 8),
                 .insert(offset: 8, element: "Presents", associatedWith: 6)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             changes: [
                 .remove(offset: 2, element: "Dreidel", associatedWith: nil),
                 .remove(offset: 1, element: "Menorah", associatedWith: nil),
                 .remove(offset: 0, element: "Hannukah", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             changes: [
                 .insert(offset: 7, element: "New Years", associatedWith: nil),
                 .insert(offset: 8, element: "Champagne", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["New Years", "Champagne",
                 "Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents"],
             changes: [
                 .remove(offset: 8, element: "Champagne", associatedWith: 1),
                 .remove(offset: 7, element: "New Years", associatedWith: 0),
                 .insert(offset: 0, element: "New Years", associatedWith: 7),
                 .insert(offset: 1, element: "Champagne", associatedWith: 8)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne",
                 "Hannukah", "Menorah", "Dreidel"],
             changes: [
                 .remove(offset: 2, element: "Dreidel", associatedWith: 8),
                 .remove(offset: 1, element: "Menorah", associatedWith: 7),
                 .remove(offset: 0, element: "Hannukah", associatedWith: 6),
                 .insert(offset: 6, element: "Hannukah", associatedWith: 0),
                 .insert(offset: 7, element: "Menorah", associatedWith: 1),
                 .insert(offset: 8, element: "Dreidel", associatedWith: 2)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel", "Presents",
                 "Xmas", "Tree", "Lights",
                 "New Years", "Champagne"],
             source:
                ["Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             changes: [
                 .remove(offset: 3, element: "Presents", associatedWith: 3),
                 .remove(offset: 2, element: "Dreidel", associatedWith: nil),
                 .remove(offset: 1, element: "Menorah", associatedWith: nil),
                 .remove(offset: 0, element: "Hannukah", associatedWith: nil),
                 .insert(offset: 3, element: "Presents", associatedWith: 3)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Presents",
                 "New Years", "Champagne", "Lights"],
             changes: [
                 .remove(offset: 5, element: "Lights", associatedWith: 8),
                 .insert(offset: 6, element: "New Years", associatedWith: nil),
                 .insert(offset: 7, element: "Champagne", associatedWith: nil),
                 .insert(offset: 8, element: "Lights", associatedWith: 5)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years"],
             changes: [
                 .remove(offset: 8, element: "Champagne", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel", "Presents",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne", "Presents"],
             source:
                ["Hannukah", "Menorah", "Dreidel", "Presents",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne", "Presents"],
             changes: [],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel", "Presents",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne", "Presents"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights",
                 "New Years", "Champagne", "Presents"],
             changes: [
                 .remove(offset: 7, element: "Presents", associatedWith: nil),
                 .remove(offset: 3, element: "Presents", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights",
                 "New Years", "Champagne", "Presents"],
             source:
                ["Hannukah", "Menorah", "Dreidel", "Presents",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne", "Presents"],
             changes: [
                 .insert(offset: 3, element: "Presents", associatedWith: nil),
                 .insert(offset: 7, element: "Presents", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah", "Dreidel", "Presents",
                 "Xmas", "Tree", "Lights",
                 "New Years", "Champagne", "Presents"],
             source:
                ["Hannukah", "Menorah", "Dreidel",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne", "Presents"],
             changes: [
                 .remove(offset: 3, element: "Presents", associatedWith: 6),
                 .insert(offset: 6, element: "Presents", associatedWith: 3)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne",
                 "Hannukah", "Dreidel"],
             source:
                ["Hannukah", "Menorah",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne",
                 "Hannukah", "Dreidel"],
             changes: [],
             line: #line),

            (target:
                ["Hannukah", "Menorah",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne",
                 "Hannukah", "Dreidel"],
             source:
                ["Hannukah", "Menorah",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             changes: [
                 .remove(offset: 9, element: "Dreidel", associatedWith: nil),
                 .remove(offset: 8, element: "Hannukah", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne"],
             source:
                ["Hannukah", "Menorah",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne",
                 "Hannukah", "Dreidel"],
             changes: [
                 .insert(offset: 8, element: "Hannukah", associatedWith: nil),
                 .insert(offset: 9, element: "Dreidel", associatedWith: nil)
             ],
             line: #line),

            (target:
                ["Hannukah", "Menorah",
                 "Xmas", "Tree", "Lights", "Presents",
                 "New Years", "Champagne",
                 "Hannukah", "Dreidel"],
             source:
                ["Xmas", "Tree", "Lights", "Presents",
                 "Hannukah", "Menorah",
                 "New Years", "Champagne",
                 "Hannukah", "Dreidel"],
             changes: [
                 .remove(offset: 1, element: "Menorah", associatedWith: 5),
                 .remove(offset: 0, element: "Hannukah", associatedWith: 4),
                 .insert(offset: 4, element: "Hannukah", associatedWith: 0),
                 .insert(offset: 5, element: "Menorah", associatedWith: 1)
             ],
             line: #line),
        ]

        for (source, target, expected, line) in expectedChanges {
            let actual = source.difference(from: target).inferringMoves()
            XCTAssert(
                actual == OrderedCollectionDifference(expected),
                "\(actual) != \(expected)",
                line: line)
        }
    }

    static var allTests = [
        ("testEmpty", testEmpty),
        ("testDifference", testDifference),
    ]
}
