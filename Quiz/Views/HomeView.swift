//
//  HomeView.swift
//  Quiz
//
//  出題カテゴリを選んでクイズを開始するトップ画面。
//

import SwiftUI

struct HomeView: View {
    @State private var selection: Set<QuizCategory> = []
    @State private var session: QuizSession?
    @State private var generator = QuizGenerator()
    @State private var aiTheme: String = ""
    @State private var genError: String?
    @State private var adLoaded = false
    @FocusState private var themeFocused: Bool

    private let launcher = QuizLauncher.shared

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    VStack(spacing: 16) {
                        ForEach(QuizCategory.allCases) { category in
                            CategoryCard(
                                category: category,
                                isSelected: selection.contains(category)
                            ) {
                                toggle(category)
                            }
                        }
                    }

                    startButton

                    aiSection
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                AdBannerView(adUnitID: AdUnit.homeBanner) { loaded in
                    withAnimation(.easeInOut) { adLoaded = loaded }
                }
                .frame(height: adLoaded ? 50 : 0)
                .frame(maxWidth: .infinity)
                .opacity(adLoaded ? 1 : 0)
                .clipped()
            }
        }
        .overlay {
            if generator.isGenerating {
                loadingOverlay
            }
        }
        .fullScreenCover(item: $session) { session in
            GameView(session: session) { self.session = nil }
        }
        .task { handleLaunch(launcher.pending) }
        .onChange(of: launcher.pending) { _, request in
            handleLaunch(request)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 12) {
            Image("programming_quiz")
                .resizable()
                .scaledToFit()
                .frame(height: 96)
                .padding(.top, 24)

            Text("挑戦するジャンルを選んでスタート")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var startButton: some View {
        Button {
            start()
        } label: {
            Label("スタート", systemImage: "play.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(.indigo)
        .foregroundStyle(.white)
        .disabled(selection.isEmpty)
        .opacity(selection.isEmpty ? 0.5 : 1)
        .animation(.easeInOut, value: selection.isEmpty)
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AIにおまかせ出題", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.primary)

            if QuizGenerator.isAvailable {
                Text("テーマを入力すると、オンデバイスAIがオリジナル問題を作ります。問題文・選択肢・正誤は自動生成のため誤りを含むことがあり、正しさは保証されません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("例: SwiftUI、再帰、正規表現", text: $aiTheme)
                    .focused($themeFocused)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                    .submitLabel(.go)
                    .onSubmit { Task { await startAI() } }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button {
                                Task { await startAI() }
                            } label: {
                                Label("問題を作る", systemImage: "wand.and.stars")
                            }
                            .disabled(generator.isGenerating)
                        }
                    }

                Button {
                    Task { await startAI() }
                } label: {
                    Label("AIで問題を作る", systemImage: "wand.and.stars")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.purple)
                .foregroundStyle(.white)
                .disabled(generator.isGenerating)
            } else {
                Text("この端末では AI 出題を利用できません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let genError {
                Text(genError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("AIが問題を作成中…")
                    .font(.headline)
            }
            .padding(32)
            .background(.regularMaterial, in: .rect(cornerRadius: 24))
        }
    }

    // MARK: - Actions

    private func toggle(_ category: QuizCategory) {
        withAnimation(.snappy) {
            if selection.contains(category) {
                selection.remove(category)
            } else {
                selection.insert(category)
            }
        }
    }

    private func start() {
        let questions = QuizData.questions(for: selection)
        guard !questions.isEmpty else { return }
        session = QuizSession(questions: questions)
    }

    private func startAI() async {
        guard !generator.isGenerating else { return }
        themeFocused = false
        genError = nil
        do {
            let questions = try await generator.makeQuestions(theme: aiTheme)
            guard !questions.isEmpty else {
                genError = "問題を生成できませんでした。もう一度お試しください。"
                return
            }
            session = QuizSession(questions: questions)
        } catch {
            genError = "生成に失敗しました。しばらくして再度お試しください。"
        }
    }

    /// App Intents（Siri / Spotlight）からの起動要求を処理する。
    private func handleLaunch(_ request: QuizLauncher.Request?) {
        guard let request else { return }
        launcher.pending = nil
        switch request {
        case .category(let category):
            selection = [category]
            start()
        case .ai:
            Task { await startAI() }
        }
    }
}

/// カテゴリ選択カード。選択状態は枠線とチェックで表現する。
private struct CategoryCard: View {
    let category: QuizCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: category.systemImage)
                    .font(.title2)
                    .foregroundStyle(category.tint)
                    .frame(width: 36)

                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? category.tint : .secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(category.tint, lineWidth: isSelected ? 2 : 0)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
