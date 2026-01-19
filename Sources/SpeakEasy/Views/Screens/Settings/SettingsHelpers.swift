import SwiftUI

struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(self.title)
                .font(.headline)

            VStack(spacing: 12) {
                self.content
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(10)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let description: String
    let content: Content

    init(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content)
    {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.body)
                Text(self.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            self.content
        }
    }
}
