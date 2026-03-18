import CoreGraphics

enum WidgetPositioning {
    static func initialOrigin(
        savedOrigin: CGPoint?,
        windowSize: CGSize,
        availableFrames: [CGRect],
        fallbackFrame: CGRect
    ) -> CGPoint {
        guard let savedOrigin else {
            return centeredOrigin(windowSize: windowSize, in: fallbackFrame)
        }

        let savedRect = CGRect(origin: savedOrigin, size: windowSize)

        if let visibleFrame = availableFrames.first(where: { $0.intersects(savedRect) }) {
            return clamp(origin: savedOrigin, windowSize: windowSize, to: visibleFrame)
        }

        return centeredOrigin(windowSize: windowSize, in: fallbackFrame)
    }

    static func centeredOrigin(windowSize: CGSize, in frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.midX - windowSize.width / 2,
            y: frame.midY - windowSize.height / 2
        )
    }

    static func clamp(origin: CGPoint, windowSize: CGSize, to frame: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(origin.x, frame.minX - windowSize.width + 20), frame.maxX - 20),
            y: min(max(origin.y, frame.minY - windowSize.height + 20), frame.maxY - 20)
        )
    }
}
