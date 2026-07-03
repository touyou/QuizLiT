//
//  BackgroundView.swift
//  Quiz
//
//  Liquid Glass が映えるように、柔らかいグラデーション背景を共通化する。
//

import SwiftUI

struct BackgroundView: View {
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .indigo, .blue, .purple,
                .blue, .cyan, .indigo,
                .purple, .indigo, .blue,
            ]
        )
        .overlay(Color.black.opacity(0.15))
        .ignoresSafeArea()
    }
}

#Preview {
    BackgroundView()
}
