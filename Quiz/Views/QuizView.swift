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
        arrangedContent
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
                // iPhone Duo などステータスバーが上辺にない端末では上の安全領域が 0 になるため、
                // 画面端に貼り付かないよう最低限の余白を確保する。
                .padding(.top, 8)
            }
    }

    // MARK: - Layout

    /// iOS 27.1 以降は ArrangementView で問題（primary）と選択肢（secondary）を分け、
    /// 広い画面では左右、縦長の画面では上下に並べる。それ以前は従来の縦積みレイアウト。
    @ViewBuilder
    private var arrangedContent: some View {
        if #available(iOS 27.1, *) {
            ArrangementView {
                scrollableIfNeeded { questionPane }
                    // 上下に並ぶときは問題側を内容の高さに留め、残りを選択肢側に回す。
                    .splitArrangementFixedLayoutSize(horizontal: false, vertical: true)
            } secondary: {
                scrollableIfNeeded { answerPane }
            }
            .arrangementViewStyle(.split)
        } else {
            scrollableIfNeeded { stackedContent }
        }
    }

    /// 折りたたみ時や横向きなど縦の高さが足りないときだけスクロールに切り替える。
    /// 収まる場合は Spacer で回答ボタンを下端に寄せたまま表示する。
    private func scrollableIfNeeded(@ViewBuilder _ content: () -> some View) -> some View {
        let content = content()
        return ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
    }

    /// iOS 27.1 未満向けの縦積みレイアウト。
    private var stackedContent: some View {
        VStack(spacing: 24) {
            progress
            questionCard
            answerControls
        }
        .padding(24)
        .readableWidth()
    }

    private var questionPane: some View {
        VStack(spacing: 24) {
            progress
            questionCard
            Spacer(minLength: 0)
        }
        .padding(24)
        .readableWidth()
    }

    private var answerPane: some View {
        answerControls
            .padding(24)
            .readableWidth()
    }

    // MARK: - Subviews

    /// 選択肢と、回答後に出る「次の問題へ」ボタン。
    private var answerControls: some View {
        VStack(spacing: 12) {
            ForEach(Array(session.current.choices.enumerated()), id: \.offset) { index, choice in
                choiceButton(index: index, text: choice)
            }

            Spacer(minLength: 12)

            // 回答の前後で高さが変わるとスクロール有無の判定が切り替わってレイアウトが跳ねるため、
            // ボタンの領域は常に確保しておき、回答後にフェードインさせる。
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
            .opacity(isAnswered ? 1 : 0)
            .offset(y: isAnswered ? 0 : 16)
            .disabled(!isAnswered)
            .accessibilityHidden(!isAnswered)
        }
    }

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
                // 回答後に行の高さが変わらないよう、アイコン分の領域は常に確保する。
                Image(systemName: resultIcon(for: index) ?? "circle")
                    .font(.title3)
                    .opacity(resultIcon(for: index) == nil ? 0 : 1)
                    .accessibilityHidden(resultIcon(for: index) == nil)
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

#Preview("縦向き") {
    GameView(session: QuizSession(questions: QuizData.allQuestions), onExit: {})
}

#Preview("横向き", traits: .landscapeLeft) {
    GameView(session: QuizSession(questions: QuizData.allQuestions), onExit: {})
}

#Preview("回答後") {
    let session = QuizSession(questions: QuizData.allQuestions)
    session.answer(1)
    return GameView(session: session, onExit: {})
}
