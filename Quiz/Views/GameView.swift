//
//  GameView.swift
//  Quiz
//
//  出題中と結果表示を切り替えるコンテナ。
//

import SwiftUI

struct GameView: View {
    let session: QuizSession
    /// ホームに戻るためのクロージャ。
    let onExit: () -> Void

    var body: some View {
        ZStack {
            BackgroundView()

            if session.isFinished {
                ResultView(session: session, onExit: onExit)
            } else {
                QuizView(session: session, onQuit: onExit)
            }
        }
    }
}
