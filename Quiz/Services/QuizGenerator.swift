//
//  QuizGenerator.swift
//  Quiz
//
//  Foundation Models（オンデバイス）でクイズを生成するサービス。
//

import Foundation
import FoundationModels

@MainActor
@Observable
final class QuizGenerator {
    /// この端末で AI 出題が利用可能か。
    static var isAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available: true
        default: false
        }
    }

    /// 生成中かどうか。ローディング表示に使う。
    private(set) var isGenerating = false

    /// 指定テーマのクイズを生成し、既存の Question 配列に変換して返す。
    func makeQuestions(theme: String, count: Int = 5) async throws -> [Question] {
        isGenerating = true
        defer { isGenerating = false }

        let trimmed = theme.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = trimmed.isEmpty ? "プログラミング全般" : trimmed

        let session = LanguageModelSession(instructions: """
            あなたはプログラミングに詳しいクイズ作家です。次の条件を厳密に守って作問してください。
            - すべて日本語で書く。
            - 事実として検証可能で、答えが一意に定まる問題だけを作る。意見・主観・曖昧なもの、最新情報に依存するものは避ける。
            - 選択肢はちょうど3つ。正解は必ず1つだけ。残り2つは、もっともらしいが明確に誤りである選択肢にする。
            - 選択肢どうしを同義・重複させない。「すべて正しい」「どれも正しくない」のような選択肢は使わない。
            - answerIndex は choices の中で正解が置かれている位置（0始まり）を正確に指す。作問後に問題文・正解・誤答の整合を必ず自己確認する。
            - 選択肢は簡潔にする。
            """)

        let prompt = "「\(subject)」に関するプログラミングの3択クイズを\(count)問、重複しないように作成してください。難易度は初級〜中級。"
        let options = GenerationOptions(temperature: 0.3)
        let response = try await session.respond(to: prompt, generating: GeneratedQuiz.self, options: options)

        return response.content.questions.compactMap { Question(generated: $0, topic: subject) }
    }
}
