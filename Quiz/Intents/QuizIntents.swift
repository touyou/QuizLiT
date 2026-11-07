//
//  QuizIntents.swift
//  Quiz
//
//  Siri / Spotlight から起動できる App Intents と、そのルーティング。
//  ホーム画面のスタートボタンと AI 出題ボタンも同じ Intent を通す。
//

import AppIntents

/// App Intents からの起動要求をアプリ本体（HomeView）へ橋渡しする共有状態。
@MainActor
@Observable
final class QuizLauncher {
    static let shared = QuizLauncher()
    private init() {}

    enum Request: Equatable {
        case categories(Set<QuizCategory>)
        /// 空のテーマは「おまかせ」。
        case ai(theme: String)
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
    static var supportedModes: IntentModes { .foreground(.immediate) }
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$category)のクイズを開始")
    }

    @Parameter(title: "カテゴリ")
    var category: QuizCategory

    @MainActor
    func perform() async throws -> some IntentResult {
        QuizLauncher.shared.pending = .categories([category])
        return .result()
    }
}

/// 複数のカテゴリを混ぜてクイズを開始する。ホーム画面のスタートボタンはこれを通す。
struct StartMixedQuizIntent: AppIntent {
    static let title: LocalizedStringResource = "カテゴリを混ぜてクイズを開始"
    static let description = IntentDescription("選んだ複数のカテゴリから混ぜて出題します。")
    static var supportedModes: IntentModes { .foreground(.immediate) }
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$categories)のクイズを開始")
    }

    @Parameter(title: "カテゴリ")
    var categories: [QuizCategory]

    init() {}

    init(categories: Set<QuizCategory>) {
        self.categories = QuizCategory.allCases.filter(categories.contains)
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard !categories.isEmpty else {
            throw $categories.needsValueError("どのカテゴリで出題しますか？")
        }
        QuizLauncher.shared.pending = .categories(Set(categories))
        return .result()
    }
}

/// AI 生成クイズを開始する。
struct StartAIQuizIntent: AppIntent {
    static let title: LocalizedStringResource = "AIクイズを開始"
    static let description = IntentDescription("AIが作るオリジナル問題に挑戦します。テーマを指定すると、そのテーマで問題を作ります。")
    static var supportedModes: IntentModes { .foreground(.immediate) }
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$theme)でAIクイズを開始")
    }

    @Parameter(title: "テーマ", description: "例: SwiftUI、再帰、正規表現。指定しなければおまかせ")
    var theme: String?

    init() {}

    init(theme: String) {
        self.theme = theme
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuizLauncher.shared.pending = .ai(theme: theme ?? "")
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
