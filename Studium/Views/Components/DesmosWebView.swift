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
            .background(Color(.systemGroupedBackground))
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
        if let url = URL(string: "https://www.desmos.com/calculator") {
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
            .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct DesmosWebViewRepresentableMac: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {}

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: "https://www.desmos.com/calculator") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
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
