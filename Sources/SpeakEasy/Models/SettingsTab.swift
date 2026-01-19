enum SettingsTab: String, CaseIterable {
    case general = "General"
    case snippets = "Snippets"
    case providers = "Providers"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .snippets: "text.badge.plus"
        case .providers: "server.rack"
        case .about: "info.circle"
        }
    }
}
