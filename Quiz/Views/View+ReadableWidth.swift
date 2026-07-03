//
//  View+ReadableWidth.swift
//  Quiz
//
//  iPad など広い画面で本文が横に広がりすぎないよう、
//  読みやすい幅に制限して中央寄せする共通モディファイア。
//

import SwiftUI

extension View {
    /// コンテンツを読みやすい最大幅に収めて中央寄せする。
    /// iPhone（幅が maxWidth 未満）ではそのまま全幅で表示される。
    func readableWidth(_ maxWidth: CGFloat = 640) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
