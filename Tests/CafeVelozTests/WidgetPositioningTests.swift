import XCTest
@testable import CafeVeloz

final class WidgetPositioningTests: XCTestCase {
    func testInitialOriginUsesSavedPositionWhenStillVisible() {
        let origin = WidgetPositioning.initialOrigin(
            savedOrigin: CGPoint(x: 250, y: 140),
            windowSize: CGSize(width: 180, height: 180),
            availableFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)],
            fallbackFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        XCTAssertEqual(origin.x, 250, accuracy: 0.001)
        XCTAssertEqual(origin.y, 140, accuracy: 0.001)
    }

    func testInitialOriginRecentersWhenSavedPositionIsOffScreen() {
        let origin = WidgetPositioning.initialOrigin(
            savedOrigin: CGPoint(x: 4_000, y: 4_000),
            windowSize: CGSize(width: 180, height: 180),
            availableFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)],
            fallbackFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        XCTAssertEqual(origin.x, 630, accuracy: 0.001)
        XCTAssertEqual(origin.y, 360, accuracy: 0.001)
    }

    func testClampKeepsWidgetInsideVisibleFrameMargins() {
        let origin = WidgetPositioning.clamp(
            origin: CGPoint(x: 2_000, y: -300),
            windowSize: CGSize(width: 180, height: 180),
            to: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        XCTAssertEqual(origin.x, 1_420, accuracy: 0.001)
        XCTAssertEqual(origin.y, -160, accuracy: 0.001)
    }
}
