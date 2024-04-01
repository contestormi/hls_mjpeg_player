import Flutter
import WebKit
import UIKit

public class HlsMjpegPlayerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = HlsMjpegPlayerFactory(registrar: registrar)
        registrar.register(factory, withId: "HlsMjpegPlayer")
    }
}

class HlsMjpegPlayerFactory: NSObject, FlutterPlatformViewFactory {
    private var registrar: FlutterPluginRegistrar
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return HlsMjpegPlayer(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            registrar: registrar
        )
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class HlsMjpegPlayer: NSObject, FlutterPlatformView, WKNavigationDelegate {
    private var mainView = HlsMjpegPlayerView()
    private var mChannel: FlutterMethodChannel?
    private var resultHandler: FlutterResult?
    private var htmlContent: String = """
<html style="height: 100%; width: 100%;">
<body style="margin: 0px;
			 height: 100%;
             width: 100%;"
      bgcolor="#000000">
<img
        style="-webkit-user-select:none;
        position: absolute;
		top:0;
		left: 0;
		width:100%;
		height: 100%;
		object-fit: contain;
		object-position: center;
        "
        src="#URL#">
</body>
</html>
"""
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        registrar: FlutterPluginRegistrar
    ) {
        super.init()
        initVar(registrar: registrar)
        loadUrl(arguments: args)
    }
    
    func view() -> UIView {
        return mainView
    }
    
    deinit{
        mainView.webView.stopLoading()
        DispatchQueue.main.async {
            WKWebsiteDataStore.default().removeData(ofTypes:
                                                        [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache],
                                                    modifiedSince: Date(timeIntervalSince1970: 0), completionHandler:{})
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let isBlank = webView.url?.absoluteString.contains("blank") ?? false
        if isBlank { return }
        let arg: [String: String?] = ["status": "Error"]
        mChannel?.invokeMethod("onStatusChange", arguments: arg)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let isBlank = webView.url?.absoluteString.contains("blank") ?? false
        if isBlank { return }
        let arg: [String: String?] = ["status": "Error"]
        mChannel?.invokeMethod("onStatusChange", arguments: arg)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        let isBlank = webView.url?.absoluteString.contains("blank") ?? false
        let arg: [String: String?] = ["status": isBlank ? "Pause" : "Play"]
        mChannel?.invokeMethod("onStatusChange", arguments: arg)
        mainView.imageView.isHidden = !isBlank
        if let resultHandler = resultHandler {
            resultHandler("Loaded")
        }
    }
    
    private func loadUrl(arguments args: Any?){
        let arg: [String: String?] = ["status": "Loading"]
        mChannel?.invokeMethod("onStatusChange", arguments: arg)
        
        let argumentsDictionary = args as? Dictionary<String, Any> ?? [:]
        let initialUrl = argumentsDictionary["url"] as? String ?? ""
        
        let url = URL(string: initialUrl)
        if(!initialUrl.isEmpty && url != nil){
            mainView.webView.loadHTMLString(self.htmlContent.replacingOccurrences(of: "#URL#", with: initialUrl),baseURL: url)
          //  mainView.webView.load(URLRequest(url: url!))
        }
    }
    
    private func pause(){
        mainView.pause()
    }
    
    private func initVar(registrar: FlutterPluginRegistrar){
        mChannel = FlutterMethodChannel(name: "com.example.hls_mjpeg_player", binaryMessenger: registrar.messenger())
        mChannel?.setMethodCallHandler{ [weak self] call, result in
            self?.resultHandler = result
            switch call.method{
            case "play":
                self?.loadUrl(arguments: call.arguments)
            case "pause":
                self?.pause()
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        mainView.webView.navigationDelegate = self
    }
}

private class HlsMjpegPlayerView: UIView{
    let imageView = UIImageView()
    let webView = WKWebView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(webView)
        addSubview(imageView)
        addLayoutConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Unsupported")
    }
    
    private func addLayoutConstraint() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leftAnchor.constraint(equalTo: leftAnchor),
            imageView.rightAnchor.constraint(equalTo: rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leftAnchor.constraint(equalTo: leftAnchor),
            webView.rightAnchor.constraint(equalTo: rightAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    func pause(){
        let isBlank = webView.url?.absoluteString.contains("blank") ?? false
        if isBlank { return }
        
        let config = WKSnapshotConfiguration()
        config.rect = webView.frame
        webView.takeSnapshot(with: config, completionHandler: { (image: UIImage?, error: Error?) in
            self.imageView.image = image
            self.webView.stopLoading()
            self.webView.load(URLRequest(url: URL(string: "about:blank")!))
        })
    }
}

