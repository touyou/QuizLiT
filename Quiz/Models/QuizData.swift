//
//  QuizData.swift
//  Quiz
//
//  全問題を保持する静的データ。旧 UIKit 版の設問をそのまま移植している。
//

import Foundation

enum QuizData {
    /// 全カテゴリの全問題。
    static let allQuestions: [Question] = basic + iphone + algorithm

    /// 指定したカテゴリの問題をシャッフルして返す。
    static func questions(for categories: Set<QuizCategory>) -> [Question] {
        allQuestions
            .filter { question in
                guard let category = question.category else { return false }
                return categories.contains(category)
            }
            .shuffled()
    }

    // MARK: - 知識編（10問）

    private static let basic: [Question] = [
        Question(category: .basic,
                 text: "プログラミング言語Pythonの名前の由来となったとされるGuido van Rossumの大好きな番組といえば？",
                 choices: ["空飛ぶモンティ・パイソン", "山登りモンティ・パイソン", "宇宙に行くモンティ・パイソン"],
                 answerIndex: 0),
        Question(category: .basic,
                 text: "プログラミング言語Rubyを開発した日本のエンジニアと言えば？",
                 choices: ["まつもとゆきひろ", "村上憲郎", "橋本善久"],
                 answerIndex: 0),
        Question(category: .basic,
                 text: "プログラミング言語C++を布教する活動からC++を使う人達についた俗称といえば？",
                 choices: ["炎の軍団", "闇の軍団", "C.P.B.M."],
                 answerIndex: 1),
        Question(category: .basic,
                 text: "プログラミング言語SwiftがAppleのアプリケーション開発用言語として発表されたのは？",
                 choices: ["WWDC2013", "Apple Special Event2013", "WWDC2014"],
                 answerIndex: 2),
        Question(category: .basic,
                 text: "『すごいH本』で有名な純粋関数型言語といえば？",
                 choices: ["Hadoop", "Haskell", "Lisp"],
                 answerIndex: 1),
        Question(category: .basic,
                 text: "一説にコーヒーに関するものが名前の由来となっているとされているAndroidアプリ開発言語としても有名なプログラミング言語といえば？",
                 choices: ["Fortran", "Go", "Java"],
                 answerIndex: 2),
        Question(category: .basic,
                 text: "Appleの創業者のうちSteve Jobsじゃない方は？",
                 choices: ["スティーブ・ウォズニアック", "スティーブ・ジョンソン", "スティーブ・ポッター"],
                 answerIndex: 0),
        Question(category: .basic,
                 text: "日本語で書けるプログラミング言語として実在するものは？",
                 choices: ["あさがお", "なでしこ", "くのいち"],
                 answerIndex: 1),
        Question(category: .basic,
                 text: "Unity独自の言語であるBooのもととなっているプログラミング言語は？",
                 choices: ["Lisp", "Ruby", "Python"],
                 answerIndex: 2),
        Question(category: .basic,
                 text: "Go言語はどこの会社の言語？",
                 choices: ["Microsoft", "Google", "Adobe"],
                 answerIndex: 1),
    ]

    // MARK: - iPhoneアプリ開発編（10問）

    private static let iphone: [Question] = [
        Question(category: .iphone,
                 text: "iPhoneアプリ開発においてコードを書く際、UI要素の前にかならず書かなければいけないのは？",
                 choices: ["@IBAction", "@IBOutlet", "@IBInspectable"],
                 answerIndex: 1),
        Question(category: .iphone,
                 text: "Swiftにおいて配列の大きさを取得するために書くのは？",
                 choices: [".count", ".size", ".length"],
                 answerIndex: 0),
        Question(category: .iphone,
                 text: "iPhoneアプリ開発において画面遷移のことをなんと言う？",
                 choices: ["ChangeView", "Segue", "Move"],
                 answerIndex: 1),
        Question(category: .iphone,
                 text: "iPhoneアプリ開発において画面のデザインを行うファイルといえば？",
                 choices: ["デザインボード", "ファンタジーボード", "ストーリーボード"],
                 answerIndex: 2),
        Question(category: .iphone,
                 text: "起動した時にうつすViewをまるごと起動時の状態によって切り替えたい場合、どのファイルにその条件分岐を記述すればよい？",
                 choices: ["ViewController.swift", "AppDelegate.swift", "LanchScreen.storyboard"],
                 answerIndex: 1),
        Question(category: .iphone,
                 text: "SNS投稿機能を使いたい時にimportしなければならないライブラリと言えば？",
                 choices: ["Social", "UIKit", "Fabric"],
                 answerIndex: 0),
        Question(category: .iphone,
                 text: "iPhoneアプリ開発の統合開発環境といえば？",
                 choices: ["Xcode", "Atom", "Visual Studio"],
                 answerIndex: 0),
        Question(category: .iphone,
                 text: "Labelのコード上での型名は？",
                 choices: ["UITextLabel", "UILabel", "UILavelView"],
                 answerIndex: 1),
        Question(category: .iphone,
                 text: "CollectionViewのコード上での型名は？",
                 choices: ["UICollectionViewController", "UICollectionViewDelegate", "UICollectionView"],
                 answerIndex: 2),
        Question(category: .iphone,
                 text: "iPhoneアプリ開発においてコードを書く時、ボタンをおした時の処理などを記述する関数に必ずつけるものといえば？",
                 choices: ["@IBAction", "@IBInspectable", "@IBDesignable"],
                 answerIndex: 0),
    ]

    // MARK: - アルゴリズム編（7問）

    private static let algorithm: [Question] = [
        Question(category: .algorithm,
                 text: "再帰関数を用いて木の根をたどるように探索するアルゴリズムといえば？",
                 choices: ["深さ優先探索", "幅優先探索", "木の根探索"],
                 answerIndex: 0),
        Question(category: .algorithm,
                 text: "最短経路を求めるアルゴリズムとして有名なもののうち、スタートから順に最短距離を確定させていくことでおこなうものは？",
                 choices: ["ベルマンフォード法", "プリム法", "ダイクストラ法"],
                 answerIndex: 2),
        Question(category: .algorithm,
                 text: "漸化式をたてることで計算量を大幅に減らすことが出来るアルゴリズムの動的計画法、これの略称として一般的なものは？",
                 choices: ["DK", "DP", "MP"],
                 answerIndex: 1),
        Question(category: .algorithm,
                 text: "プログラミングコンテストの攻略本として発行され、以降アルゴリズムの解説書として一般のプログラマにも人気となった秋葉拓哉、岩田陽一、北川宜稔著『プログラミングコンテストチャレンジブック』の俗称と言えば？",
                 choices: ["蟻本", "雲丹本", "猫本"],
                 answerIndex: 0),
        Question(category: .algorithm,
                 text: "bitDPというアルゴリズムを使う問題をその代表的なものの名前をとってなんという？",
                 choices: ["巡回サービスマン問題", "巡回セールスマン問題", "巡回郵便局問題"],
                 answerIndex: 1),
        Question(category: .algorithm,
                 text: "かつては日本に競技プログラミングを広める広告塔となり、日本初のプログラミングコンテスト運営会社であるAtCoder社を設立した人といえば？",
                 choices: ["高橋直大", "高橋正三", "高橋利幸"],
                 answerIndex: 0),
        Question(category: .algorithm,
                 text: "囲碁などのAIにつかわれる乱数を利用したアルゴリズムといえば？",
                 choices: ["モンテカルロ法", "カルテモンロ法", "メルセンヌ法"],
                 answerIndex: 0),
    ]
}
