# Webview IOS example
## _Bienvenidos_

Este proyecto contiene un ejemplo básico de la integración de **1DOC3** mediante un webview en **Swift**
## Configuración de permisos
en tu archivo **Info.plist** asegurate de tener los siguientes permisos:
```
<key>NSCameraUsageDescription</key>
// Mensaje personalizado que se le muestra al usuario
<string>Estás usando tu cámara para la videconferencia con uno de nuestros doctores</string>

<key>NSMicrophoneUsageDescription</key>
// Mensaje personalizado que se le muestra al usuario
<string>Estás usando tu micrófono para la videconferencia con uno de nuestros doctores</string>
```

Estos permisos son necesarios para el uso correcto de videollamada y envío de audios.


## Configuración del WKWebView

 Reemplaza la **URL** de ejemplo por la de tu proyecto
```
WebViewContainer(urlString: "https://www.example.com")
```
En el **ContentView.swift** vas a ver un ejemplo de cómo puedes hacerlo.