//
//  AboutView.swift
//  Quiz
//
//  ホームの「このアプリについて」から開く情報画面。設定項目が無いアプリなので、設定画面は作らずこれだけを置く。
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AboutHeader()
                }

                Section("フィードバック") {
                    AboutLinkRow(title: "アプリを評価", systemImage: "star", destination: AppLinks.writeReview)
                    AboutLinkRow(title: "機能要望・不具合報告", systemImage: "envelope", destination: AppLinks.support)
                    ShareLink(item: AppLinks.appStore) {
                        Label("アプリを共有", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    AboutLinkRow(title: "開発者について", systemImage: "person", destination: AppLinks.developer)
                }

                Section {
                    AboutLinkRow(title: "プライバシーポリシー", systemImage: "hand.raised", destination: AppLinks.privacy)
                    AdPrivacyOptionsRow()
                    NavigationLink {
                        LicensesView()
                    } label: {
                        Label("オープンソースライセンス", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", systemImage: "xmark", role: .close) { dismiss() }
                }
            }
        }
    }
}

private struct AboutHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("programming_quiz")
                .resizable()
                .scaledToFit()
                .frame(height: 64)
                .accessibilityHidden(true)
            Text(verbatim: "Programming Quiz")
                .font(.title3.bold())
            Text("バージョン \(AppLinks.version)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("日本で個人が開発しています。")
                .font(.footnote)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// EEA・英国など、広告の同意を変えられる必要がある地域でだけ出す。
private struct AdPrivacyOptionsRow: View {
    private let consent = ConsentManager.shared

    var body: some View {
        if consent.isPrivacyOptionsRequired {
            Button {
                Task {
                    await consent.presentPrivacyOptionsForm()
                    AdsStartup.shared.start()
                }
            } label: {
                Label("広告のプライバシー設定", systemImage: "slider.horizontal.3")
            }
        }
    }
}

/// アプリの外（Safari・App Store）へ出る行。押すと外へ出ることが分かるよう矢印を付ける
private struct AboutLinkRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

enum AppLinks {
    static let appStore = URL(string: "https://apps.apple.com/app/id1089599534")!
    static let writeReview = URL(string: "https://apps.apple.com/app/id1089599534?action=write-review")!
    static let support = URL(string: "https://touyou.dev/programming-quiz/support")!
    static let privacy = URL(string: "https://touyou.dev/programming-quiz/privacy")!
    static let developer = URL(string: "https://touyou.dev")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }
}
