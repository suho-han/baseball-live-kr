import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var statusText = "꺼짐"
    @Published private(set) var detailText = "Mac에 로그인하면 Baseball LIVE KR을 자동으로 엽니다."

    private let service = SMAppService.mainApp

    init() {
        refresh()
    }

    func refresh() {
        apply(Self.presentation(for: service.status.launchAtLoginStatus))
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            isEnabled = service.status.launchAtLoginStatus.isRegistered
            statusText = "실패"
            detailText = error.localizedDescription
            return
        }

        refresh()
    }

    static func presentation(for status: LaunchAtLoginServiceStatus) -> LaunchAtLoginPresentation {
        switch status {
        case .enabled:
            LaunchAtLoginPresentation(
                isEnabled: true,
                statusText: "켜짐",
                detailText: "Mac 로그인 시 Baseball LIVE KR이 자동으로 열립니다."
            )
        case .requiresApproval:
            LaunchAtLoginPresentation(
                isEnabled: true,
                statusText: "승인 필요",
                detailText: "시스템 설정의 로그인 항목에서 Baseball LIVE KR을 허용해야 합니다. 끄면 로그인 항목에서 제거합니다."
            )
        case .notFound:
            LaunchAtLoginPresentation(
                isEnabled: true,
                statusText: "앱 확인 필요",
                detailText: "등록 기록은 남아 있지만 앱 번들을 확인할 수 없습니다. 끄면 로그인 항목에서 제거를 다시 시도합니다."
            )
        case .notRegistered:
            LaunchAtLoginPresentation(
                isEnabled: false,
                statusText: "꺼짐",
                detailText: "Mac에 로그인하면 Baseball LIVE KR을 자동으로 엽니다."
            )
        }
    }

    private func apply(_ presentation: LaunchAtLoginPresentation) {
        isEnabled = presentation.isEnabled
        statusText = presentation.statusText
        detailText = presentation.detailText
    }
}

struct LaunchAtLoginPresentation: Equatable {
    let isEnabled: Bool
    let statusText: String
    let detailText: String
}

enum LaunchAtLoginServiceStatus {
    case enabled
    case requiresApproval
    case notFound
    case notRegistered
}

private extension LaunchAtLoginServiceStatus {
    var isRegistered: Bool {
        switch self {
        case .enabled, .requiresApproval, .notFound:
            return true
        case .notRegistered:
            return false
        }
    }
}

private extension SMAppService.Status {
    var launchAtLoginStatus: LaunchAtLoginServiceStatus {
        switch self {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        case .notRegistered:
            return .notRegistered
        @unknown default:
            return .notFound
        }
    }
}
