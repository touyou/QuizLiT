//
//  ResultView.swift
//  Quiz
//
//  正解数と評価コメントを表示する結果画面。
//

import SwiftUI

struct ResultView: View {
    let session: QuizSession
    let onExit: () -> Void

    var body: some View {
        // 折りたたみ時や横向きなど縦の高さが足りないときだけスクロールに切り替える。
        // 外周の余白は、スクロール時だけ contentMargins にしてスクロール領域を端まで広げる。
        ViewThatFits(in: .vertical) {
            ResultContent(session: session, onExit: onExit).padding(24)
            ScrollView { ResultContent(session: session, onExit: onExit) }
                .contentMargins(24, for: .scrollContent)
        }
    }
}

private struct ResultContent: View {
    let session: QuizSession
    let onExit: () -> Void
    // 大きな飾りと点数も文字サイズの設定に合わせて伸ばす。
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 72
    @ScaledMetric(relativeTo: .largeTitle) private var scoreSize: CGFloat = 40

    private var ratio: Double {
        session.total == 0 ? 0 : Double(session.correctCount) / Double(session.total)
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: symbolName)
                .font(.system(size: symbolSize))
                .foregroundStyle(.indigo)
                .symbolEffect(.bounce, value: session.id)

            Text("結果発表")
                .font(.title.bold())
                .foregroundStyle(.primary)
                .accessibilityIdentifier("resultTitle")

            VStack(spacing: 8) {
                Text("\(session.correctCount) / \(session.total) 問正解")
                    .font(.system(size: scoreSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text(comment)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 28))

            Spacer()

            VStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) { session.restart() }
                } label: {
                    Label("もう一度チャレンジ", systemImage: "arrow.counterclockwise")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.indigo)
                .foregroundStyle(.white)

                Button {
                    onExit()
                } label: {
                    Text("ホームに戻る")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .readableWidth()
    }

    private var symbolName: String {
        switch ratio {
        case 1: "crown.fill"
        case 0.7...: "star.fill"
        case 0.4...: "hand.thumbsup.fill"
        default: "bolt.heart.fill"
        }
    }

    private var comment: String {
        switch ratio {
        case 1: "パーフェクト！あなたはプログラミング博士だ！"
        case 0.7...: "お見事！かなりの実力者です。"
        case 0.4...: "いい調子！もう一歩でマスター。"
        default: "これから伸びしろたっぷり！復習してみよう。"
        }
    }
}
