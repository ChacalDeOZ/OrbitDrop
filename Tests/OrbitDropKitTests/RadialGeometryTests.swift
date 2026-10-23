import XCTest
import CoreGraphics
@testable import OrbitDropKit

final class RadialGeometryTests: XCTestCase {
    let center = CGPoint(x: 200, y: 200)
    let innerRadius: CGFloat = 28
    let outerRadius: CGFloat = 90

    func testAngleCalculationClockwiseFromTop() {
        // Top (0 / 360 deg)
        let topPoint = CGPoint(x: 200, y: 250)
        let angleTop = RadialGeometry.angle(from: center, to: topPoint)
        XCTAssertEqual(angleTop, 0, accuracy: 0.001)

        // Right (90 deg)
        let rightPoint = CGPoint(x: 250, y: 200)
        let angleRight = RadialGeometry.angle(from: center, to: rightPoint)
        XCTAssertEqual(angleRight, 90, accuracy: 0.001)

        // Bottom (180 deg)
        let bottomPoint = CGPoint(x: 200, y: 150)
        let angleBottom = RadialGeometry.angle(from: center, to: bottomPoint)
        XCTAssertEqual(angleBottom, 180, accuracy: 0.001)

        // Left (270 deg)
        let leftPoint = CGPoint(x: 150, y: 200)
        let angleLeft = RadialGeometry.angle(from: center, to: leftPoint)
        XCTAssertEqual(angleLeft, 270, accuracy: 0.001)
    }

    func testDeadZoneRejection() {
        // Point very close to center (distance = 10 < 28)
        let nearCenter = CGPoint(x: 205, y: 205)
        let sector = RadialGeometry.sectorIndex(
            at: nearCenter,
            center: center,
            sectorCount: 4,
            innerRadius: innerRadius,
            outerRadius: outerRadius
        )
        XCTAssertNil(sector, "Point inside inner radius should be ignored")
    }

    func testOutsideOuterRadiusRejection() {
        // Point far outside (distance = 120 > 90)
        let farPoint = CGPoint(x: 200, y: 320)
        let sector = RadialGeometry.sectorIndex(
            at: farPoint,
            center: center,
            sectorCount: 4,
            innerRadius: innerRadius,
            outerRadius: outerRadius
        )
        XCTAssertNil(sector, "Point outside outer radius should be ignored")
    }

    func testSectorIndexIdentificationFourSectors() {
        // 4 sectors:
        // Sector 0: 315° to 45° (Top)
        // Sector 1: 45° to 135° (Right)
        // Sector 2: 135° to 225° (Bottom)
        // Sector 3: 225° to 315° (Left)

        let top = CGPoint(x: 200, y: 260)     // angle = 0°
        let right = CGPoint(x: 260, y: 200)   // angle = 90°
        let bottom = CGPoint(x: 200, y: 140)  // angle = 180°
        let left = CGPoint(x: 140, y: 200)    // angle = 270°

        XCTAssertEqual(RadialGeometry.sectorIndex(at: top, center: center, sectorCount: 4, innerRadius: innerRadius, outerRadius: outerRadius), 0)
        XCTAssertEqual(RadialGeometry.sectorIndex(at: right, center: center, sectorCount: 4, innerRadius: innerRadius, outerRadius: outerRadius), 1)
        XCTAssertEqual(RadialGeometry.sectorIndex(at: bottom, center: center, sectorCount: 4, innerRadius: innerRadius, outerRadius: outerRadius), 2)
        XCTAssertEqual(RadialGeometry.sectorIndex(at: left, center: center, sectorCount: 4, innerRadius: innerRadius, outerRadius: outerRadius), 3)
    }

    func testScreenEdgeClamping() {
        let screenSize = CGSize(width: 1920, height: 1080)
        let wheelRadius: CGFloat = 100
        let margin: CGFloat = 20

        // Near top-left (x=10, y=10)
        let clampedMin = RadialGeometry.clampedCenter(
            cursor: CGPoint(x: 10, y: 10),
            screenSize: screenSize,
            wheelRadius: wheelRadius,
            margin: margin
        )
        XCTAssertEqual(clampedMin.x, 120) // margin + radius = 20 + 100
        XCTAssertEqual(clampedMin.y, 120)

        // Near bottom-right (x=1910, y=1070)
        let clampedMax = RadialGeometry.clampedCenter(
            cursor: CGPoint(x: 1910, y: 1070),
            screenSize: screenSize,
            wheelRadius: wheelRadius,
            margin: margin
        )
        XCTAssertEqual(clampedMax.x, 1800) // 1920 - 120
        XCTAssertEqual(clampedMax.y, 960)  // 1080 - 120
    }

    func testMultiMonitorScreenEdgeClamping() {
        let secondaryScreen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let wheelRadius: CGFloat = 100
        let margin: CGFloat = 20

        let clampedSecondary = RadialGeometry.clampedCenter(
            cursor: CGPoint(x: 1930, y: 10),
            screenFrame: secondaryScreen,
            wheelRadius: wheelRadius,
            margin: margin
        )

        XCTAssertEqual(clampedSecondary.x, 2040) // 1920 + 20 + 100
        XCTAssertEqual(clampedSecondary.y, 120)  // 0 + 20 + 100
    }
}
