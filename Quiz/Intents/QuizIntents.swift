//
//  QuizIntents.swift
//  Quiz
//
//  Siri / Spotlight から起動できる App Intents と、そのルーティング。
//

import AppIntents

/// App Intents からの起動要求をアプリ本体（HomeView）へ橋渡しする共有状態。
@MainActor
@Observable
final class QuizLauncher {
    static let shared = QuizLauncher()
    private init() {}

    enum Request: Equatable {
        case category(QuizCategory)
        case ai
    }

    /// 未処理の起動要求。HomeView が消費する。
    var pending: Request?
}

// MARK: - AppEnum 対応

extension QuizCategory: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "クイズのカテゴリ"
    }

    static var caseDisplayRepresentations: [QuizCategory: DisplayRepresentation] {
        [
            .basic: "プログラミング知識編",
            .iphone: "iPhoneアプリ開発編",
            .algorithm: "アルゴリズム編",
        ]
    }
}

// MARK: - Intents

/// カテゴリを指定してクイズを開始する。
struct StartCategoryQuizIntent: AppIntent {
    static let title: LocalizedStringResource = "カテゴリを指定してクイズを開始"
    static let description = IntentDescription("選んだカテゴリでクイズを始めます。")
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "カテゴリ")
    var category: QuizCategory

    @MainActor
    func perform() async throws -> some IntentResult {
        QuizLauncher.shared.pending = .category(category)
        return .result()
    }
}

/// AI 生成クイズを開始する。
struct StartAIQuizIntent: AppIntent {
    static let title: LocalizedStringResource = "AIクイズを開始"
    static let description = IntentDescription("オンデバイスAIが作るオリジナル問題に挑戦します。")
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuizLauncher.shared.pending = .ai
        return .result()
    }
}

// MARK: - App Shortcuts

struct QuizShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartCategoryQuizIntent(),
            phrases: [
                "\(.applicationName)でクイズを始める",
                "\(.applicationName)で\(\.$category)のクイズを始める",
            ],
            shortTitle: "カテゴリ別クイズ",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StartAIQuizIntent(),
            phrases: [
                "\(.applicationName)でAIクイズを始める",
            ],
            shortTitle: "AIクイズ",
            systemImageName: "sparkles"
        )
    }
}
