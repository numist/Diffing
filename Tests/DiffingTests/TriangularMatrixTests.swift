import XCTest
@testable import Diffing

class TriangularMatrixTests : XCTestCase {
    func testLowerTriangularMatrix() {
        var m = LowerTriangularMatrix<Int>()
        m.appendRow(repeating: 1)
        m.appendRow(repeating: 2)
        m.appendRow(repeating: 3)
        m.appendRow(repeating: 4)

        XCTAssertEqual(Array(m.rowMajorOrder), [
            1,
            2, 2,
            3, 3, 3,
            4, 4, 4, 4
        ])

        for i in 0..<4 {
            XCTAssertEqual(m[i, 0], i + 1)
            XCTAssertEqual(m[i, i], i + 1)
        }
    }

    static var allTests = [
        ("testLowerTriangularMatrix", testLowerTriangularMatrix),
    ]
}
