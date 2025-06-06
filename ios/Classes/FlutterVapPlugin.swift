import Flutter
import UIKit
import QGVAPlayer

public class FlutterVapPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = FlutterVapPluginViewFactory(messenger: registrar.messenger(), registrar: registrar)
        registrar.register(factory, withId: "flutter_vap_plugin")
    }
}

class FlutterVapPluginViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var registrar: FlutterPluginRegistrar

    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
        self.messenger = messenger
        self.registrar = registrar
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FlutterVapView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            registrar: registrar,
            args: args
        )
    }
}

class FlutterVapView: NSObject, FlutterPlatformView, VAPWrapViewDelegate {
    private let containerView: UIView
    private weak var vapView: QGVAPWrapView?
    private var channel: FlutterMethodChannel
    private var registrar: FlutterPluginRegistrar
    private var currentConfig: [String: Any]?
    private var isPlaying: Bool = false

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar, args: Any?) {
        self.containerView = UIView(frame: frame)
        self.registrar = registrar
        self.channel = FlutterMethodChannel(
            name: "flutter_vap_plugin_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()
        self.setupMethodChannel()
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
      
            switch call.method {
            case "stop":
                self?.stopPlayback()
                result(nil)
            case "play":
                if let args = call.arguments as? [String: Any],
                   let path = args["path"] as? String,
                   let sourceType = args["sourceType"] as? String {
                    self?.playWithParams(path: path, sourceType: sourceType)
                    print("play 方法 sourcePath:",path)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for play", details: nil))
                }
                
    
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupVapViewIfNeeded() {
        if vapView == nil {
            let newVapView = QGVAPWrapView(frame: containerView.bounds)
            vapView = newVapView
            guard let vapView = vapView else { return }
            vapView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(vapView)
            NSLayoutConstraint.activate([
                vapView.topAnchor.constraint(equalTo: containerView.topAnchor),
                vapView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                vapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                vapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            vapView.contentMode = .scaleToFill
        }
    }

    private func stopPlayback() {
        if isPlaying {
            self.vapView?.stopHWDMP4()
            isPlaying = false
        }
    }

    private func playVideo(_ videoPath: String) {
        guard let vapView = self.vapView else {
            let errorInfo: [String: Any] = [
                "errorType": -1,
                "errorMsg": "VAP view not initialized"
            ]
            self.channel.invokeMethod("onFailed", arguments: errorInfo)
            return
        }

        if !FileManager.default.fileExists(atPath: videoPath) {
            let errorInfo: [String: Any] = [
                "errorType": -1,
                "errorMsg": "Video file does not exist: \(videoPath)"
            ]
            self.channel.invokeMethod("onFailed", arguments: errorInfo)
            return
        }

        // 确保任何现有播放都被停止
        vapView.stopHWDMP4()
        isPlaying = true

        print("FlutterVapPlugin - Playing video from path: \(videoPath)")
        vapView.contentMode = .scaleToFill
        vapView.playHWDMP4(videoPath,repeatCount: 0,  delegate: self)
    }

//    开始播放
    func vapWrap_viewDidStartPlayMP4(_ container: UIView) {
        self.channel.invokeMethod("onVideoStart",arguments: nil)
    }
// 每一帧触发
    func vapWrap_viewDidPlayMP4AtFrame(_ frame: QGMP4AnimatedImageFrame) {
        self.channel.invokeMethod("onVideoRender", arguments: ["frameIndex": frame.index])
    }
    
    func vapWrap_viewDidStopPlayMP4(_ lastFrameIndex: Int, view container: UIView) {
        isPlaying = false
        self.channel.invokeMethod("onVideoStop", arguments: nil)
    }

    func vapWrap_viewDidFinishPlayMP4(_ totalFrameCount: Int, view container: UIView) {
        isPlaying = false
        // 确保不会自动开始下一次播放
        self.vapView?.stopHWDMP4()
        self.channel.invokeMethod("onVideoFinish", arguments: nil)
       
    }

    func vapWrap_viewDidFailPlayMP4(_ error: Error) {
        isPlaying = false
        let errorInfo: [String: Any] = [
            "errorType": -1,
            "errorMsg": error.localizedDescription
        ]
        self.channel.invokeMethod("onFailed", arguments: errorInfo)
    }
    
    private func destroyInstance() {
        self.stopPlayback()
        self.vapView?.removeFromSuperview()
        self.vapView = nil
    }


    func view() -> UIView {
        return containerView
    }

    private func playWithParams(path: String, sourceType: String) {
        setupVapViewIfNeeded()
        switch sourceType {
        case "file":
            self.playVideo(path)
        case "asset":
            let key = registrar.lookupKey(forAsset: path)
            if let assetPath = Bundle.main.path(forResource: key, ofType: nil) {
                self.playVideo(assetPath)
            } else {
                print("FlutterVapPlugin - Could not find asset: \(path)")
                let errorInfo: [String: Any] = [
                    "errorType": -1,
                    "errorMsg": "Could not find asset: \(path)"
                ]
                self.channel.invokeMethod("onFailed", arguments: errorInfo)
            }
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
            let errorInfo: [String: Any] = [
                "errorType": -1,
                "errorMsg": "Unsupported source type: \(sourceType)"
            ]
            self.channel.invokeMethod("onFailed", arguments: errorInfo)
        }
    }
}
