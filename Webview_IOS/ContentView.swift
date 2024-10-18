
import SwiftUI
import WebKit
import QuickLook

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
        webViewPrefs.javaScriptCanOpenWindowsAutomatically = false
        
        // Configuración de la instancia de WKWebView
        let webViewConf = WKWebViewConfiguration()
        webViewConf.preferences = webViewPrefs
        webViewConf.allowsInlineMediaPlayback = true // Configuración que evita pantalla de video en negro
        webViewConf.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: CGRect.zero, configuration: webViewConf)
        // Habilita el inspeccionamiento del WebView
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.keyboardDismissMode = .onDrag
        
        // Asigna el delegado de navegación
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

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
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, QLPreviewControllerDataSource {
        var parent: WebViewContainer
        var lastDownloadedPDFURL: URL?
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // WKNavigationDelegate - Manejo de eventos de navegación
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Aquí podrías realizar acciones cuando la página se ha cargado completamente
        }
            
        // WKNavigationDelegate - Manejo de eventos de navegación
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            if let url = navigationAction.request.url {
                // Comprobar si la URL de navegación es un archivo que deseas descargar
                if isDownloadableFile(url) {
                    // Aquí puedes manejar la descarga
                    downloadFileInExternalBrowser(url)
                    
                    // Evitar la navegación adicional para evitar que el archivo se abra en el WebView
                    decisionHandler(.cancel)
                    return
                }
                
                if isRedirectDownloadableFile(url) {
                    let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
                    // Obtener todas las cookies del WKWebView
                    cookieStore.getAllCookies { cookies in
                        for cookie in cookies {
                            // Asignar el nombre y el valor de la cookie
                            HTTPCookieStorage.shared.setCookie(cookie)
                        }

                         var request = URLRequest(url: url)

                        let cookies = HTTPCookieStorage.shared.cookies(for: url)!
                        let headers = HTTPCookie.requestHeaderFields(with: cookies)

                        request.allHTTPHeaderFields = headers
                        
                        // Crear una tarea de datos para la solicitud GET
                        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                            if let error = error {
                                print("Error: \(error)")
                            } else if  let httpResponse = response as? HTTPURLResponse{
                                if httpResponse.statusCode == 200, let redirectURL = httpResponse.url {
                                    self.downloadFileInExternalBrowser(redirectURL)
                                
                                } else {
                                // La respuesta no es una redirección o no contiene la URL de redirección
                                let str = String(data: data!, encoding: .utf8)
                                print("Received data:\n\(str ?? "")")
                            }
                            }
                        }

                        task.resume()
                    }
                    
                    decisionHandler(.cancel)
                    return
                }

                if url.path.contains("/api/prescription-pdf") {
                    handlePrescriptionPdfDownload(webView: webView, url: url)
                    decisionHandler(.cancel)
                    return
                }
            }
            // Permitir la navegación normal en otras URL
            decisionHandler(.allow)
        }

        // Implementar WKUIDelegate para manejar nuevas ventanas
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
        
        // Función para verificar si la URL es un archivo descargable (personaliza según tus necesidades)
        func isDownloadableFile(_ url: URL) -> Bool {
            // Aquí puedes implementar tu lógica para determinar si la URL es un archivo descargable
            // Por ejemplo, puedes verificar la extensión del archivo o cualquier otro criterio
            // Devuelve true si es un archivo descargable, false en caso contrario
            
            let fileExtension = url.pathExtension.lowercased()
            let allowedExtensions = ["pdf", "jpeg", "jpg", "png"]
            return allowedExtensions.contains(fileExtension)
        }
        
        func isRedirectDownloadableFile(_ url: URL) -> Bool {
            // Aquí puedes implementar tu lógica para determinar si la URL es un archivo descargable
            // Por ejemplo, puedes verificar la extensión del archivo o cualquier otro criterio
            // Devuelve true si es un archivo descargable, false en caso contrario
            
            // Obtener la extensión del archivo desde la URL
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                for queryItem in queryItems {
                    if queryItem.name == "name" {
                        if let fileName = queryItem.value {
                            print("Nombre del archivo: \(fileName)")
                            
                            let components = fileName.components(separatedBy: ".")
                            let fileExtension = components.last
                            
                            // Verificar si la extensión es una de las admitidas
                            let allowedExtensions = ["pdf", "jpeg", "jpg", "png"]
                            return allowedExtensions.contains(fileExtension!)
                        }
                        
                    }
                }
            }
    
            return false
        }
        
        func downloadFileInExternalBrowser(_ url: URL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        print("Abriendo en el navegador externo...")
                    } else {
                        print("No se pudo abrir en el navegador externo")
                    }
                }
            } else {
                print("No se puede abrir la URL en el navegador externo")
            }
        }

        func handlePrescriptionPdfDownload(webView: WKWebView, url: URL) {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            cookieStore.getAllCookies { cookies in
                var request = URLRequest(url: url)
                
                // Agregar cookies a la solicitud
                let headers = HTTPCookie.requestHeaderFields(with: cookies)
                request.allHTTPHeaderFields = headers
                
                // Crear una tarea de datos para la solicitud GET
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        print("Error al descargar el PDF: \(error)")
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200,
                          let data = data else {
                        print("Respuesta inválida o sin datos")
                        return
                    }
                    
                    // Obtener el nombre del archivo del header Content-Disposition
                    var filename = "prescription.pdf"
                    if let disposition = httpResponse.allHeaderFields["Content-Disposition"] as? String {
                        let filenamePattern = "filename=\"?(.+)\"?"
                        if let range = disposition.range(of: filenamePattern, options: .regularExpression) {
                            filename = String(disposition[range].dropFirst(9).dropLast())
                        }
                    }
                    
                    // Asegurar que el nombre del archivo termina con .pdf
                    if !filename.lowercased().hasSuffix(".pdf") {
                        filename += ".pdf"
                    }
                    
                    // Guardar el archivo PDF
                    self.savePDF(data: data, filename: filename)
                }
                task.resume()
            }
        }
        
        func savePDF(data: Data, filename: String) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            
            do {
                try data.write(to: fileURL)
                print("PDF guardado en: \(fileURL.path)")
                self.lastDownloadedPDFURL = fileURL
                
                DispatchQueue.main.async {
                    // Mostrar una alerta o iniciar la vista previa del PDF
                    let previewController = QLPreviewController()
                    previewController.dataSource = self
                    
                    if let topViewController = UIApplication.shared.windows.first?.rootViewController {
                        topViewController.present(previewController, animated: true, completion: nil)
                    }
                }
            } catch {
                print("Error al guardar el PDF: \(error)")
            }
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return lastDownloadedPDFURL != nil ? 1 : 0
        }
                
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return lastDownloadedPDFURL as QLPreviewItem? ?? URL(fileURLWithPath: "") as QLPreviewItem
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
