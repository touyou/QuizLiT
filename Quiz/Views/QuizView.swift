//
//  QuizView.swift
//  Quiz
//
//  問題文と3択を表示し、回答を受け付ける画面。
//

import SwiftUI

struct QuizView: View {
    let session: QuizSession
    let onQuit: () -> Void

    private var isAnswered: Bool { session.selectedChoice != nil }

    var body: some View {
        VStack(spacing: 24) {
            progress

            questionCard

            VStack(spacing: 12) {
                ForEach(Array(session.current.choices.enumerated()), id: \.offset) { index, choice in
                    choiceButton(index: index, text: choice)
                }
            }

            Spacer(minLength: 0)

            if isAnswered {
                Button {
                    withAnimation(.snappy) { session.advance() }
                } label: {
                    Label(session.questionNumber == session.total ? "結果を見る" : "次の問題へ",
                          systemImage: "arrow.right")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.indigo)
                .foregroundStyle(.white)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
        .readableWidth()
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    onQuit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding(10)
                }
                .buttonStyle(.glass)
                .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Subviews

    private var progress: some View {
        VStack(spacing: 8) {
            HStack {
                Label(session.current.topicTitle, systemImage: session.current.topicSymbol)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("第 \(session.questionNumber) 問 / \(session.total) 問")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(session.questionNumber), total: Double(session.total))
                .tint(.indigo)

            if session.current.category == nil {
                Text("AI生成のため、内容に誤りを含む場合があります。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var questionCard: some View {
        Text(session.current.text)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
    }

    private func choiceButton(index: Int, text: String) -> some View {
        Button {
            withAnimation(.snappy) { session.answer(index) }
        } label: {
            HStack(spacing: 12) {
                Text(text)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Spacer()
                if let icon = resultIcon(for: index) {
                    Image(systemName: icon)
                        .font(.title3)
                }
            }
            .foregroundStyle(foreground(for: index))
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background(for: index), in: .rect(cornerRadius: 18))
            .overlay {
                if let tint = tint(for: index) {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(tint, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
    }

    // MARK: - Feedback helpers

    /// 回答後の選択肢の色付け。正解=緑、誤答（選択したもの）=赤。
    private func tint(for index: Int) -> Color? {
        guard let selected = session.selectedChoice else { return nil }
        if index == session.current.answerIndex { return .green }
        if index == selected { return .red }
        return nil
    }

    private func background(for index: Int) -> Color {
        if let tint = tint(for: index) {
            return tint.opacity(0.18)
        }
        return Color(.secondarySystemGroupedBackground)
    }

    private func foreground(for index: Int) -> Color {
        tint(for: index) ?? .primary
    }

    private func resultIcon(for index: Int) -> String? {
        guard let selected = session.selectedChoice else { return nil }
        if index == session.current.answerIndex { return "checkmark.circle.fill" }
        if index == selected { return "xmark.circle.fill" }
        return nil
    }
}
