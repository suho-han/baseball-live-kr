import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(BaseballLiveKRDesignSystem)
import BaseballLiveKRDesignSystem
#endif
#if canImport(BaseballLiveKRFeatures)
import BaseballLiveKRFeatures
#endif

#if canImport(AppKit)
@MainActor
final class MenuBarStatusItemController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var viewModel: TodayGamesViewModel?
    private weak var navigationModel: AppNavigationModel?
    private var fontScale = KboFontScale.defaultValue
    private var colorScheme: ColorScheme?
    private var openMainWindow: (() -> Void)?

    func update(
        isEnabled: Bool,
        viewModel: TodayGamesViewModel,
        navigationModel: AppNavigationModel,
        fontScale: CGFloat,
        colorScheme: ColorScheme?,
        openMainWindow: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.navigationModel = navigationModel
        self.fontScale = KboFontScale.clamped(fontScale)
        self.colorScheme = colorScheme
        self.openMainWindow = openMainWindow

        if isEnabled {
            ensureStatusItem()
            updatePopoverContent()
        } else {
            removeStatusItem()
        }
    }

    private func ensureStatusItem() {
        guard statusItem == nil else { return }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = BaseballLiveKRmacOSApp.menuBarItemAutosaveName
        statusItem.behavior = [.removalAllowed]
        configureButton(statusItem.button)
        self.statusItem = statusItem
    }

    private func configureButton(_ button: NSStatusBarButton?) {
        guard let button else { return }

        button.image = NSImage(
            systemSymbolName: BaseballLiveKRmacOSApp.menuBarItemSystemImage,
            accessibilityDescription: BaseballLiveKRmacOSApp.menuBarItemTitle
        )
        button.imagePosition = .imageOnly
        button.toolTip = BaseballLiveKRmacOSApp.menuBarItemTitle
        button.setAccessibilityLabel(BaseballLiveKRmacOSApp.menuBarItemTitle)
        button.identifier = NSUserInterfaceItemIdentifier(BaseballLiveKRmacOSApp.menuBarItemAccessibilityIdentifier)
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func updatePopoverContent() {
        guard let viewModel, let navigationModel else { return }

        let rootView = MenuBarDashboardView(
            viewModel: viewModel,
            navigationModel: navigationModel,
            openMainWindow: { [weak self] in
                self?.closePopover()
                self?.openMainWindow?()
            }
        )
        .environment(\.kboFontScale, fontScale)
        .preferredColorScheme(colorScheme)

        let hostingController = NSHostingController(rootView: AnyView(rootView))

        if let popover {
            popover.contentViewController = hostingController
        } else {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentViewController = hostingController
            self.popover = popover
        }
    }

    private func removeStatusItem() {
        closePopover()

        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }

        statusItem = nil
        popover = nil
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }

        if popover?.isShown == true {
            closePopover()
        } else {
            updatePopoverContent()
            NSApp.activate(ignoringOtherApps: true)
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }
}
#endif
