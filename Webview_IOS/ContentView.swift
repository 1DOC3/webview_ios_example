
import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        // Crea un WebViewContainer y carga una URL
        WebViewContainer(urlString: "https://www.example.com")
    }
}

struct WebViewContainer: UIViewRepresentable {
    let urlString: String
    
    // Configura y devuelve una instancia de WKWebView
    func makeUIView(context: Context) -> WKWebView {
        // Configuración de preferencias del WKWebView
        let webViewPrefs = WKPreferences()
        webViewPrefs.javaScriptCanOpenWindowsAutomatically = true
        
        // Configuración de la instancia de WKWebView
        let webViewConf = WKWebViewConfiguration()
        webViewConf.preferences = webViewPrefs
        webViewConf.allowsInlineMediaPlayback = true // Configuración que evita pantalla de video en negro
        webViewConf.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: CGRect.zero, configuration: webViewConf)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.keyboardDismissMode = .onDrag
        
        // Asigna el delegado de navegación
        webView.navigationDelegate = context.coordinator

        return webView
    }
    
    // Carga la URL en el WKWebView
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    // Crea y devuelve un coordinador
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinador que actúa como delegado de navegación
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // WKNavigationDelegate - Manejo de eventos de navegación
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Aquí podrías realizar acciones cuando la página se ha cargado completamente
        }
    }
}


struct WebViewExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
