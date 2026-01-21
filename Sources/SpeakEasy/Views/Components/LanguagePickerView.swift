import AppKit
import SwiftUI

struct LanguageSearchField: View {
    @Binding var selectedLanguage: WhisperLanguage
    @State private var isShowingPopover: Bool = false

    var body: some View {
        Button(action: {
            self.isShowingPopover.toggle()
        }) {
            HStack(spacing: 8) {
                Text(self.selectedLanguage.flag)
                    .font(.title3)

                Text(self.selectedLanguage.name)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(self.isShowingPopover ? 180 : 0))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(width: 220)
        .popover(isPresented: self.$isShowingPopover, arrowEdge: .bottom) {
            LanguagePickerPopover(
                selectedLanguage: self.$selectedLanguage,
                isPresented: self.$isShowingPopover)
        }
    }
}

struct LanguagePickerPopover: View {
    @Binding var selectedLanguage: WhisperLanguage
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    @State private var highlightedIndex: Int = 0
    @State private var displayedLanguages: [WhisperLanguage] = []
    @FocusState private var isSearchFocused: Bool

    private static let allOptions: [WhisperLanguage] = [WhisperLanguage.autoDetect] + WhisperLanguage.allLanguages

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search language...", text: self.$searchText)
                    .textFieldStyle(.plain)
                    .focused(self.$isSearchFocused)
                    .onSubmit {
                        self.selectHighlightedLanguage()
                    }
                if !self.searchText.isEmpty {
                    Button(action: {
                        self.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(self.displayedLanguages.enumerated()), id: \.element.id) { index, language in
                            Button(action: {
                                self.selectLanguage(language)
                            }) {
                                HStack(spacing: 8) {
                                    Text(language.flag)
                                    Text(language.name)
                                        .lineLimit(1)
                                    Spacer()
                                    if language.id == self.selectedLanguage.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    index == self.highlightedIndex ? Color.accentColor.opacity(0.2) : Color
                                        .clear)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                }
                .onChange(of: self.highlightedIndex) {
                    withAnimation {
                        proxy.scrollTo(self.highlightedIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 240, height: 280)
        .onAppear {
            self.displayedLanguages = Self.allOptions
            self.isSearchFocused = true
        }
        .onChange(of: self.searchText) { _, newValue in
            self.filterLanguages(query: newValue)
        }
        .onKeyPress(.downArrow) {
            self.moveHighlight(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            self.moveHighlight(by: -1)
            return .handled
        }
        .onKeyPress(.escape) {
            self.isPresented = false
            return .handled
        }
    }

    private func filterLanguages(query: String) {
        self.highlightedIndex = 0
        if query.isEmpty {
            self.displayedLanguages = Self.allOptions
        } else {
            let lowercased = query.lowercased()
            self.displayedLanguages = Self.allOptions.filter { lang in
                lang.name.lowercased().contains(lowercased) || lang.id.lowercased().contains(lowercased)
            }
        }
    }

    private func moveHighlight(by offset: Int) {
        let newIndex = self.highlightedIndex + offset
        if newIndex >= 0, newIndex < self.displayedLanguages.count {
            self.highlightedIndex = newIndex
        }
    }

    private func selectHighlightedLanguage() {
        guard self.highlightedIndex < self.displayedLanguages.count else { return }
        self.selectLanguage(self.displayedLanguages[self.highlightedIndex])
    }

    private func selectLanguage(_ language: WhisperLanguage) {
        self.selectedLanguage = language
        self.isPresented = false
    }
}
