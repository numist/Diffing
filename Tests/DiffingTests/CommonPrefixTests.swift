import XCTest
@testable import Diffing

class MismatchTests : XCTestCase {
    func testCommonPrefix() {
        func checkCommonPrefix<
            C1 : OrderedCollection, C2 : OrderedCollection, Expect : Sequence
        >(_ c1: C1, _ c2: C2, expect: Expect)
            where C1.Element == C2.Element,
                C1.Element == Expect.Element,
                C1.Element : Equatable
        {
            let p1 = c1.commonPrefix(with: c2, by: ==)
            let p2 = c2.commonPrefix(with: c1, by: ==)
            XCTAssert(p1.0.elementsEqual(p1.1))
            XCTAssert(p2.0.elementsEqual(p2.1))
            XCTAssert(p1.0.elementsEqual(p2.0))
            XCTAssert(p1.0.elementsEqual(expect))
        }

        checkCommonPrefix("", "", expect: "")
        checkCommonPrefix("abc", "abc", expect: "abc")
        checkCommonPrefix("abc", "ab", expect: "ab")
        checkCommonPrefix("abc", "abde", expect: "ab")
        checkCommonPrefix("xabc".dropFirst(), "abde", expect: "ab")
    }

    static var allTests = [
        ("testCommonPrefix", testCommonPrefix),
    ]
}
