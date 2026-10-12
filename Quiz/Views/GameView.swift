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
        // 閉じるボタンを自作の bar ではなくツールバーに載せるための NavigationStack。
        // iPhone Duo ではツールバーの項目が画面端の縦のバーへ自動で移る。
        NavigationStack {
            ZStack {
                BackgroundView()

                if session.isFinished {
                    ResultView(session: session, onExit: onExit)
                } else {
                    QuizView(session: session)
                }
            }
            .toolbar {
                // 結果画面は本文の「ホームに戻る」で抜けるため、出題中だけ表示する。
                if !session.isFinished {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる", systemImage: "xmark", role: .close, action: onExit)
                    }
                }
            }
            .toolbarVisibility(session.isFinished ? .hidden : .automatic, for: .navigationBar)
        }
    }
}
