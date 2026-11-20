//
//  LicensesView.swift
//  Quiz
//
//  同梱しているライブラリのライセンス(Licenses.txt)。
//

import SwiftUI

struct LicensesView: View {
    // 依存を足したら Licenses.txt も更新する
    private let text: String = {
        guard let url = Bundle.main.url(forResource: "Licenses", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text
    }()

    var body: some View {
        ScrollView {
            Text(verbatim: text)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
        .navigationTitle("オープンソースライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }
}
