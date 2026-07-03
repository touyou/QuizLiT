//
//  Question.swift
//  Quiz
//
//  プログラミングクイズのデータモデル。
//

import SwiftUI

/// 出題カテゴリ。ホーム画面で複数選択できる。
enum QuizCategory: String, CaseIterable, Identifiable {
    case basic
    case iphone
    case algorithm

    var id: String { rawValue }

    /// カテゴリの表示名。
    var title: String {
        switch self {
        case .basic: "プログラミング知識編"
        case .iphone: "iPhoneアプリ開発編"
        case .algorithm: "アルゴリズム編"
        }
    }

    /// カテゴリを象徴する SF Symbol。
    var systemImage: String {
        switch self {
        case .basic: "book.closed.fill"
        case .iphone: "iphone.gen3"
        case .algorithm: "point.3.connected.trianglepath.dotted"
        }
    }

    /// カテゴリの色。Liquid Glass のティントに使う。
    var tint: Color {
        switch self {
        case .basic: .blue
        case .iphone: .green
        case .algorithm: .orange
        }
    }
}

/// 一問分のクイズ。
struct Question: Identifiable, Hashable {
    let id = UUID()
    let category: QuizCategory
    let text: String
    let choices: [String]
    /// 正解の選択肢のインデックス（0 始まり）。
    let answerIndex: Int
}
