//
//  GeneratedQuiz.swift
//  Quiz
//
//  Foundation Models の guided generation で受け取るクイズのスキーマ。
//

import FoundationModels

/// AI が生成する一問分のクイズ。
@Generable
struct GeneratedQuestion {
    @Guide(description: "プログラミングに関するクイズの問題文。日本語で簡潔に。")
    let text: String

    @Guide(description: "3つの選択肢。ちょうど1つだけが正解になるようにする。", .count(3))
    let choices: [String]

    @Guide(description: "choices のうち正解の選択肢の番号。0, 1, 2 のいずれか。")
    let answerIndex: Int
}

/// AI が生成するクイズ一式。
@Generable
struct GeneratedQuiz {
    @Guide(description: "生成したクイズ問題の配列。")
    let questions: [GeneratedQuestion]
}

extension Question {
    /// AI 生成問題を既存のクイズモデルへ変換する。妥当でない場合は nil。
    init?(generated: GeneratedQuestion, topic: String) {
        guard generated.choices.count == 3,
              generated.choices.indices.contains(generated.answerIndex) else {
            return nil
        }
        self.init(text: generated.text,
                  choices: generated.choices,
                  answerIndex: generated.answerIndex,
                  category: nil,
                  topicTitle: "AI出題・\(topic)",
                  topicSymbol: "sparkles")
    }
}
