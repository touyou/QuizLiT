//
//  BackgroundView.swift
//  Quiz
//
//  システム標準の背景（ライト/ダーク自動対応）を共通化する。
//

import SwiftUI

struct BackgroundView: View {
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
}

#Preview {
    BackgroundView()
}
