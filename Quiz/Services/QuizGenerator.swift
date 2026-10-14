//
//  QuizGenerator.swift
//  Quiz
//
//  Foundation Models でクイズを生成するサービス。
//  iOS 27 以降は Private Cloud Compute のモデルを優先し、使えないときはオンデバイスに戻る。
//

import Foundation
import FoundationModels

@MainActor
@Observable
final class QuizGenerator {
    /// この端末で AI 出題が利用可能か。
    static var isAvailable: Bool {
        isPrivateCloudAvailable || isOnDeviceAvailable
    }

    private static var isOnDeviceAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available: true
        default: false
        }
    }

    private static var isPrivateCloudAvailable: Bool {
        guard #available(iOS 27.0, *) else { return false }
        switch PrivateCloudComputeLanguageModel().availability {
        case .available: return true
        default: return false
        }
    }

    /// 生成中かどうか。ローディング表示に使う。
    private(set) var isGenerating = false

    private static let instructions = """
        あなたはプログラミングに詳しいクイズ作家です。次の条件を厳密に守って作問してください。
        - すべて日本語で書く。
        - 事実として検証可能で、答えが一意に定まる問題だけを作る。意見・主観・曖昧なもの、最新情報に依存するものは避ける。
        - 選択肢はちょうど3つ。正解は必ず1つだけ。残り2つは、もっともらしいが明確に誤りである選択肢にする。
        - 選択肢どうしを同義・重複させない。「すべて正しい」「どれも正しくない」のような選択肢は使わない。
        - answerIndex は choices の中で正解が置かれている位置（0始まり）を正確に指す。作問後に問題文・正解・誤答の整合を必ず自己確認する。
        - 選択肢は簡潔にする。
        """

    /// 指定テーマのクイズを生成し、既存の Question 配列に変換して返す。
    func makeQuestions(theme: String, count: Int = 5) async throws -> [Question] {
        isGenerating = true
        defer { isGenerating = false }

        let trimmed = theme.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = trimmed.isEmpty ? "プログラミング全般" : trimmed
        let prompt = "「\(subject)」に関するプログラミングの3択クイズを\(count)問、重複しないように作成してください。難易度は初級〜中級。"

        let quiz: GeneratedQuiz
        if #available(iOS 27.0, *), Self.isPrivateCloudAvailable {
            do {
                let session = LanguageModelSession(
                    model: PrivateCloudComputeLanguageModel(),
                    instructions: Instructions(Self.instructions))
                quiz = try await Self.respond(session, to: prompt)
            } catch where Self.isOnDeviceAvailable && Self.isPrivateCloudOutage(error) {
                try Task.checkCancellation()
                quiz = try await Self.respond(LanguageModelSession(instructions: Self.instructions), to: prompt)
            }
        } else {
            quiz = try await Self.respond(LanguageModelSession(instructions: Self.instructions), to: prompt)
        }

        return quiz.questions.compactMap { Question(generated: $0, topic: subject) }
    }

    /// 日次クォータ切れ・オフライン・混雑のときだけオンデバイスに戻す。
    /// guardrail や拒否などはオンデバイスでも同じく失敗するので、二度待たせずにそのまま返す。
    @available(iOS 27.0, *)
    private static func isPrivateCloudOutage(_ error: any Error) -> Bool {
        switch error {
        case is PrivateCloudComputeLanguageModel.Error:
            return true
        case let error as LanguageModelError:
            switch error {
            case .rateLimited, .timeout: return true
            default: return false
            }
        default:
            return false
        }
    }

    private static func respond(_ session: LanguageModelSession, to prompt: String) async throws -> GeneratedQuiz {
        let options = GenerationOptions(temperature: 0.3)
        return try await session.respond(to: prompt, generating: GeneratedQuiz.self, options: options).content
    }
}
