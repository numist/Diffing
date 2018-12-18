import XCTest
import Diffing

class RangeReplaceableCollectionTests : XCTestCase {

    func testBoundaryConditions() {
        let a = [1, 2, 3, 4, 5, 6, 7, 8]
        for removeMiddle in [false, true] {
        for insertMiddle in [false, true] {
        for removeLast in [false, true] {
        for insertLast in [false, true] {
        for removeFirst in [false, true] {
        for insertFirst in [false, true] {
            var b = a

            // Prepare b
            if removeMiddle { b.remove(at: 4) }
            if insertMiddle { b.insert(10, at: 4) }
            if removeLast   { b.removeLast() }
            if insertLast   { b.append(11) }
            if removeFirst  { b.removeFirst() }
            if insertFirst  { b.insert(12, at: 0) }

            // Generate diff
            let diff = b.difference(from: a)

            // Validate application
            XCTAssertEqual(b, a.applying(diff)!)
        }}}}}}
    }

    func testFuzzer() {
        func makeArray() -> [UInt32] {
            var arr = [UInt32]()
            for _ in 0..<arc4random_uniform(10) {
                arr.append(arc4random_uniform(20))
            }
            return arr
        }
        for _ in 0..<1000 {
            let a = makeArray()
            let b = makeArray()
            let d = b.difference(from: a)
            XCTAssertEqual(b, a.applying(d)!)
            if self.testRun!.failureCount > 0 {
                print("""
                    // repro:
                    let a = \(a)
                    let b = \(b)
                    let d = b.difference(from: a)
                    XCTAssertEqual(b, a.applying(d))
                """)
                break
            }
        }
    }

    static var allTests = [
        ("testBoundaryConditions", testBoundaryConditions),
        ("testFuzzer", testFuzzer),
    ]
}
