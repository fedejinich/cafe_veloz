import AppKit
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = CaffeinateController.shared
    private var statusItem: NSStatusItem?
    private var toggleMenuItem: NSMenuItem?
    private var visibilityMenuItem: NSMenuItem?
    private var autoOffMenu: NSMenu?
    private var stateCancellable: AnyCancellable?
    private var timerCancellable: AnyCancellable?
    private var hideObserver: Any?
    private var coffeeWindow: NSWindow?
    private var isCoffeeVisible = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusBar()
        configureCoffeeWindow()
        bindStateUpdates()
        bindTimerUpdates()
        bindHideNotification()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.stopOnAppTerminate()
        if let hideObserver { NotificationCenter.default.removeObserver(hideObserver) }
    }

    private func configureStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: "",
            action: #selector(toggleCaffeinate),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        let visibilityItem = NSMenuItem(
            title: "",
            action: #selector(toggleCoffeeVisibility),
            keyEquivalent: "h"
        )
        visibilityItem.target = self
        menu.addItem(visibilityItem)

        menu.addItem(.separator())

        // Auto-off submenu
        let autoOffItem = NSMenuItem(title: "Auto-off", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for hours in AutoOffTimer.presetHours {
            let title = hours == 0 ? "Disabled" : "\(hours)h"
            let menuItem = NSMenuItem(
                title: title,
                action: #selector(selectAutoOff(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.tag = hours
            submenu.addItem(menuItem)
        }
        autoOffItem.submenu = submenu
        autoOffMenu = submenu
        menu.addItem(autoOffItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLoginItem(_:)),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu

        statusItem = item
        toggleMenuItem = toggleItem
        visibilityMenuItem = visibilityItem
        refreshStatusUI()
    }

    private func configureCoffeeWindow() {
        let windowSize = NSSize(width: 180, height: 180)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(origin: .zero, size: windowSize)
        let origin: CGPoint
        if let x = UserDefaults.standard.object(forKey: "widgetX") as? CGFloat,
           let y = UserDefaults.standard.object(forKey: "widgetY") as? CGFloat {
            origin = CGPoint(x: x, y: y)
        } else {
            origin = CGPoint(x: screenFrame.midX - windowSize.width / 2,
                             y: screenFrame.midY - windowSize.height / 2)
        }

        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: CoffeeWidgetView(controller: controller))
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        coffeeWindow = window
    }

    private func bindHideNotification() {
        hideObserver = NotificationCenter.default.addObserver(
            forName: .cafeVelozHideWidget,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.toggleCoffeeVisibility()
            }
        }
    }

    private func bindStateUpdates() {
        stateCancellable = controller.$isRunning
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatusUI()
            }
    }

    private func bindTimerUpdates() {
        timerCancellable = controller.autoOffTimer.$remainingSeconds
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatusBarTitle()
                self?.refreshAutoOffChecks()
            }
    }

    private func refreshStatusUI() {
        statusItem?.button?.image = NSImage(
            systemSymbolName: controller.isRunning ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: "Cafe Veloz"
        )
        statusItem?.button?.imagePosition = controller.autoOffTimer.isActive ? .imageLeading : .imageOnly
        toggleMenuItem?.title = controller.isRunning ? "Turn Off Cafe Veloz" : "Turn On Cafe Veloz"
        visibilityMenuItem?.title = isCoffeeVisible ? "Hide Coffee" : "Show Coffee"
        refreshStatusBarTitle()
        refreshAutoOffChecks()
    }

    private func refreshStatusBarTitle() {
        if controller.autoOffTimer.isActive {
            statusItem?.button?.title = " \(controller.autoOffTimer.formattedRemaining)"
            statusItem?.button?.imagePosition = .imageLeading
        } else {
            statusItem?.button?.title = ""
            statusItem?.button?.imagePosition = .imageOnly
        }
    }

    private func refreshAutoOffChecks() {
        guard let autoOffMenu else { return }
        let selectedHours = controller.autoOffTimer.isActive ? controller.autoOffTimer.selectedHours : 0
        for item in autoOffMenu.items {
            item.state = item.tag == selectedHours ? .on : .off
        }
    }

    @objc
    private func toggleCaffeinate() {
        controller.toggle()
    }

    @objc
    private func selectAutoOff(_ sender: NSMenuItem) {
        let hours = sender.tag
        if hours == 0 {
            controller.autoOffTimer.stop()
        } else {
            controller.startAutoOff(hours: hours)
        }
        refreshAutoOffChecks()
        refreshStatusBarTitle()
    }

    @objc
    private func toggleCoffeeVisibility() {
        guard let coffeeWindow else { return }

        if isCoffeeVisible {
            coffeeWindow.orderOut(nil)
        } else {
            coffeeWindow.makeKeyAndOrderFront(nil)
            coffeeWindow.orderFrontRegardless()
        }

        isCoffeeVisible.toggle()
        refreshStatusUI()
    }

    @objc
    private func toggleLoginItem(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            NSLog("CafeVeloz: login item error: \(error.localizedDescription)")
        }
    }

    @objc
    private func quitApp() {
        controller.stopOnAppTerminate()
        NSApp.terminate(nil)
    }
}
