import XCTest
@testable import e2e_test

final class GeneratedStructsTests: XCTestCase {
    func testDefaultValueHasExpectedZeros() {
        let point = Structs_skir.Point.defaultValue
        XCTAssertEqual(point.x, 0)
        XCTAssertEqual(point.y, 0)
    }

    func testPartialFactorySetsProvidedFieldsOnly() {
        let point = Structs_skir.Point.partial(x: 12)
        XCTAssertEqual(point.x, 12)
        XCTAssertEqual(point.y, 0)
    }

    func testCopyKeepsAndSetsFields() {
        let original = FullName_skir.FullName.partial(firstName: "Ada", lastName: "Lovelace")
        let updated = original.copy(lastName: .set("Byron"))

        XCTAssertEqual(updated.firstName, "Ada")
        XCTAssertEqual(updated.lastName, "Byron")
    }

    func testDescriptionUsesReadableJson() {
        let point = Structs_skir.Point.partial(x: 1, y: 2)
        let description = point.description

        XCTAssertTrue(description.contains("\n"))
        XCTAssertTrue(description.contains("\"x\""))
        XCTAssertTrue(description.contains("\"y\""))
    }
}
