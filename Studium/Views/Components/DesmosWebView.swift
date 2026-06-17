//
//  DesmosWebView.swift
//  Studium
//

import SwiftUI
import WebKit

#if os(iOS)
import UIKit

struct DesmosCalculatorView: View {
    var body: some View {
        DesmosWebViewRepresentable()
            .background(Color.systemGroupedBackground)
            .ignoresSafeArea(edges: .bottom)
    }
}

struct DesmosWebViewRepresentable: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {}

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        if let url = URL(string: "https://www.desmos.com/testing/collegeboard/graphing") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#elseif os(macOS)
import AppKit

struct DesmosCalculatorView: View {
    var body: some View {
        DesmosWebViewRepresentableMac()
            .background(Color.systemGroupedBackground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

final class DesmosWKContainer: NSView {
    let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }
}

struct DesmosWebViewRepresentableMac: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {}

    func makeNSView(context: Context) -> DesmosWKContainer {
        let config = WKWebViewConfiguration()
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        if let url = URL(string: "https://www.desmos.com/testing/collegeboard/graphing") {
            webView.load(URLRequest(url: url))
        }
        return DesmosWKContainer(webView: webView)
    }

    func updateNSView(_ container: DesmosWKContainer, context: Context) {}
}

#else

struct DesmosCalculatorView: View {
    var body: some View {
        ContentUnavailableView("Desmos", systemImage: "function", description: Text("Open the app on iPhone, iPad, or Mac."))
    }
}

#endif

#Preview {
    NavigationStack {
        DesmosCalculatorView()
            .navigationTitle("Desmos")
    }
}
