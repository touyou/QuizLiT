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

    var body: some View {
        ZStack {
            BackgroundView()

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

                Spacer(minLength: 0)

                AdBannerView(adUnitID: AdUnit.homeBanner)
                    .frame(height: 50)
            }
            .padding(24)
        }
        .fullScreenCover(item: $session) { session in
            GameView(session: session) { self.session = nil }
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
