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

    private var ratio: Double {
        session.total == 0 ? 0 : Double(session.correctCount) / Double(session.total)
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: symbolName)
                .font(.system(size: 72))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, value: session.id)

            Text("結果発表")
                .font(.title.bold())
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("\(session.correctCount) / \(session.total) 問正解")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(comment)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))

            Spacer()

            Button {
                onExit()
            } label: {
                Label("もう一度チャレンジ", systemImage: "arrow.counterclockwise")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(.white)
            .foregroundStyle(.indigo)
        }
        .padding(24)
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
