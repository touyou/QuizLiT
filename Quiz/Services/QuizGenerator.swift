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
            あなたはプログラミングに詳しいクイズ作家です。
            出題する問題は日本語で、選択肢はちょうど3つ、正解は必ず1つだけにしてください。
            事実にもとづき、答えの根拠が明確な問題を作ってください。
            選択肢は紛らわしすぎず、簡潔にしてください。
            """)

        let prompt = "「\(subject)」に関するプログラミングクイズを\(count)問作ってください。"
        let response = try await session.respond(to: prompt, generating: GeneratedQuiz.self)

        return response.content.questions.compactMap { Question(generated: $0, topic: subject) }
    }
}
