import XCTest
@testable import e2e_test

final class GeneratedEnumsTests: XCTestCase {
    func testUnknownValueKindIsUnknown() {
        XCTAssertEqual(Enums_skir.Weekday.unknownValue.kind, .unknown)
    }

    func testWeekdayDescriptionUsesReadableJson() {
        let description = Enums_skir.Weekday.monday.description
        XCTAssertTrue(description.contains("MONDAY") || description.contains("monday"))
    }

    func testWrapperEnumDescriptionContainsKindAndValue() {
        let value = Enums_skir.JsonValue.boolean(true)
        let description = value.description

        XCTAssertTrue(description.contains("\"kind\""))
        XCTAssertTrue(description.contains("\"value\""))
    }
}
