//
//  QuizSession.swift
//  Quiz
//
//  出題〜採点の進行状態を保持する Observable モデル。
//

import Foundation
import Observation

@Observable
final class QuizSession: Identifiable {
    let id = UUID()
    let questions: [Question]
    private(set) var index = 0
    private(set) var correctCount = 0
    /// 直近に選んだ選択肢のインデックス（回答演出用）。未回答は nil。
    private(set) var selectedChoice: Int?

    init(questions: [Question]) {
        self.questions = questions
    }

    /// 現在の問題。進行が末尾を越えた場合（結果画面への遷移アニメーション中など）は
    /// 範囲外アクセスを避けるため末尾の問題を返す。
    var current: Question { questions[min(index, questions.count - 1)] }
    var total: Int { questions.count }
    /// 1 始まりの現在の問題番号。
    var questionNumber: Int { index + 1 }
    var isFinished: Bool { index >= questions.count }

    /// 選択肢を回答として確定する。正解なら正解数を加算する。
    func answer(_ choice: Int) {
        guard selectedChoice == nil else { return }
        selectedChoice = choice
        if choice == current.answerIndex {
            correctCount += 1
        }
    }

    /// 次の問題へ進む。
    func advance() {
        selectedChoice = nil
        index += 1
    }

    /// 同じ問題セットで最初からやり直す。
    func restart() {
        index = 0
        correctCount = 0
        selectedChoice = nil
    }
}
