//
//  QuizView.swift
//  Quiz
//
//  問題文と3択を表示し、回答を受け付ける画面。
//

import SwiftUI

struct QuizView: View {
    let session: QuizSession

    /// 問題側ペインの内容を、実際の幅で折り返したときの高さ。
    @State private var questionPaneHeight: CGFloat?

    /// iOS 27.1 以降は ArrangementView で問題（primary）と選択肢（secondary）を分け、
    /// 広い画面では左右、縦長の画面では上下に並べる。それ以前は従来の縦積みレイアウト。
    var body: some View {
        if #available(iOS 27.1, *) {
            ArrangementView {
                ScrollableIfNeeded { QuestionPane(session: session) }
                    // 固定サイズの見積もりは折り返し前の幅で行われ、問題文が複数行になると高さが足りなくなる。
                    // 実際の幅で折り返した高さを測り、それを ideal の高さとして渡す。
                    .frame(idealHeight: questionPaneHeight)
                    .background(alignment: .top) {
                        QuestionPane(session: session)
                            .readableWidth()
                            .padding(24)
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { questionPaneHeight = $0 }
                    }
                    // 上下に並ぶときは問題側を内容の高さに留め、残りを選択肢側に回す。
                    .splitArrangementFixedLayoutSize(horizontal: false, vertical: true)
            } secondary: {
                ScrollableIfNeeded { AnswerControls(session: session) }
            }
            .arrangementViewStyle(.split)
        } else {
            // iOS 27.1 未満向けの縦積みレイアウト。
            ScrollableIfNeeded {
                VStack(spacing: 24) {
                    QuizProgressHeader(session: session)
                    QuestionCard(text: session.current.text)
                    AnswerControls(session: session)
                }
            }
        }
    }
}

/// 折りたたみ時や横向きなど縦の高さが足りないときだけスクロールに切り替える。
/// 収まる場合は Spacer で回答ボタンを下端に寄せたまま表示する。
/// 外周の余白もここで付ける。スクロール時は contentMargins にして、スクロール領域自体は端まで広げる。
private struct ScrollableIfNeeded<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            content.readableWidth().padding(24)
            ScrollView { content.readableWidth() }
                .contentMargins(24, for: .scrollContent)
        }
    }
}

private struct QuestionPane: View {
    let session: QuizSession

    var body: some View {
        VStack(spacing: 24) {
            QuizProgressHeader(session: session)
            QuestionCard(text: session.current.text)
            Spacer(minLength: 0)
        }
    }
}

/// 選択肢と、回答後に出る「次の問題へ」ボタン。
private struct AnswerControls: View {
    let session: QuizSession

    private var isAnswered: Bool { session.selectedChoice != nil }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(session.current.choices.enumerated()), id: \.offset) { index, choice in
                ChoiceButton(session: session, index: index, text: choice)
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
            .accessibilityIdentifier("nextButton")
            .opacity(isAnswered ? 1 : 0)
            .offset(y: isAnswered ? 0 : 16)
            .disabled(!isAnswered)
            .accessibilityHidden(!isAnswered)
        }
    }
}

private struct QuizProgressHeader: View {
    let session: QuizSession

    var body: some View {
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
}

private struct QuestionCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
    }
}

private struct ChoiceButton: View {
    let session: QuizSession
    let index: Int
    let text: String

    private var isAnswered: Bool { session.selectedChoice != nil }

    var body: some View {
        Button {
            withAnimation(.snappy) { session.answer(index) }
        } label: {
            HStack(spacing: 12) {
                Text(text)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Spacer()
                // 回答後に行の高さが変わらないよう、アイコン分の領域は常に確保する。
                Image(systemName: resultIcon ?? "circle")
                    .font(.title3)
                    .opacity(resultIcon == nil ? 0 : 1)
                    .accessibilityHidden(resultIcon == nil)
            }
            .foregroundStyle(tint ?? .primary)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint?.opacity(0.18) ?? Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
            .overlay {
                if let tint {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(tint, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
        .accessibilityIdentifier(identifier)
    }

    /// 選択肢の accessibility identifier。
    /// スクリーンショット撮影中だけ、UI テストが正解を選べるよう正解の選択肢に印を付ける。
    private var identifier: String {
        if ScreenshotFixture.isActive && index == session.current.answerIndex {
            return "choice-correct"
        }
        return "choice-\(index)"
    }

    /// 回答後の選択肢の色付け。正解=緑、誤答（選択したもの）=赤。
    private var tint: Color? {
        guard let selected = session.selectedChoice else { return nil }
        if index == session.current.answerIndex { return .green }
        if index == selected { return .red }
        return nil
    }

    private var resultIcon: String? {
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
