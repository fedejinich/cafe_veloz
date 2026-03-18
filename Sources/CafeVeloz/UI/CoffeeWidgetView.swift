import AppKit
import SwiftUI

extension Notification.Name {
    static let cafeVelozHideWidget = Notification.Name("cafeVelozHideWidget")
}

struct CoffeeWidgetView: View {
    @ObservedObject var controller: CaffeinateController
    @State private var window: NSWindow?
    @State private var dragStartMouse: CGPoint?
    @State private var dragStartOrigin: CGPoint?

    private let widgetSize = CGSize(width: 180, height: 180)

    private var coffeeCupImage: NSImage? {
        guard let url = coffeeCupImageURL(),
              let img = NSImage(contentsOf: url) else {
            return nil
        }
        img.size = NSSize(width: 180, height: 180)
        return img
    }

    private func coffeeCupImageURL() -> URL? {
        if let mainResourceURL = Bundle.main.resourceURL?.appendingPathComponent("coffee_cup@2x.png"),
           FileManager.default.fileExists(atPath: mainResourceURL.path) {
            return mainResourceURL
        }

        return Bundle.module.url(forResource: "coffee_cup@2x", withExtension: "png")
    }

    var body: some View {
        ZStack {
            coffeeCupView
                .saturation(controller.isRunning ? 1.0 : 0.3)
                .brightness(controller.isRunning ? 0 : -0.08)
                .opacity(controller.isRunning ? 1.0 : 0.4)

            // Timer badge
            if controller.autoOffTimer.isActive {
                Text(controller.autoOffTimer.formattedRemaining)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.85)))
                    .offset(y: widgetSize.height * 0.42)
            }
        }
        .frame(width: widgetSize.width, height: widgetSize.height)
        .animation(.easeInOut(duration: 0.35), value: controller.isRunning)
        .contentShape(Rectangle())
        .background(WindowAccessor(window: $window))
        .gesture(dragGesture)
        .onTapGesture(count: 2) {
            NotificationCenter.default.post(name: .cafeVelozHideWidget, object: nil)
        }
        .onTapGesture(count: 1) {
            controller.toggle()
        }
    }

    @ViewBuilder
    private var coffeeCupView: some View {
        if let nsImage = coffeeCupImage {
            Image(nsImage: nsImage)
                .frame(width: widgetSize.width, height: widgetSize.height)
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { _ in
                guard let window else { return }
                let mouse = NSEvent.mouseLocation
                if dragStartMouse == nil {
                    dragStartMouse = mouse
                    dragStartOrigin = window.frame.origin
                }
                guard let startMouse = dragStartMouse,
                      let startOrigin = dragStartOrigin else { return }
                let unclampedOrigin = CGPoint(
                    x: startOrigin.x + (mouse.x - startMouse.x),
                    y: startOrigin.y + (mouse.y - startMouse.y)
                )
                var newOrigin = unclampedOrigin
                if let screen = window.screen ?? NSScreen.main {
                    newOrigin = WidgetPositioning.clamp(
                        origin: unclampedOrigin,
                        windowSize: window.frame.size,
                        to: screen.visibleFrame
                    )
                }
                window.setFrameOrigin(newOrigin)
            }
            .onEnded { _ in
                dragStartMouse = nil
                dragStartOrigin = nil
                if let frame = window?.frame {
                    UserDefaults.standard.set(frame.origin.x, forKey: "widgetX")
                    UserDefaults.standard.set(frame.origin.y, forKey: "widgetY")
                }
            }
    }
}
