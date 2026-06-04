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
    // 缩放类型，默认 FIT_XY
    private var scaleType: String = "FIT_XY"

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar, args: Any?) {
        self.containerView = UIView(frame: frame)
        self.registrar = registrar
        self.channel = FlutterMethodChannel(
            name: "flutter_vap_plugin_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()
        // 读取创建参数中的 scaleType
        if let dict = args as? [String: Any], let st = dict["scaleType"] as? String, !st.isEmpty {
            self.scaleType = st
        }
        self.setupMethodChannel()
    }

    // 保证在主线程执行闭包
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async { block() }
        }
    }

    // 保证在主线程调用 Flutter 通道
    private func invokeOnMain(_ method: String, arguments: Any? = nil) {
        onMain { [weak self] in
            self?.channel.invokeMethod(method, arguments: arguments)
        }
    }

    // 应用 scaleType 到 vapView
    private func applyScaleType() {
        onMain { [weak self] in
            guard let self = self, let vapView = self.vapView else { return }
            switch self.scaleType {
            case "FIT_CENTER":
                vapView.contentMode = .aspectFit
                vapView.clipsToBounds = false
            case "CENTER_CROP":
                vapView.contentMode = .aspectFill
                vapView.clipsToBounds = true
            default: // "FIT_XY"
                vapView.contentMode = .scaleToFill
                vapView.clipsToBounds = false
            }
        }
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "stop":
                self.stopPlayback()
                result(nil)
            case "play":
                if let args = call.arguments as? [String: Any],
                   let path = args["path"] as? String,
                   let sourceType = args["sourceType"] as? String {
                    self.playWithParams(path: path, sourceType: sourceType)
                    print("play 方法 sourcePath:", path)
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
            onMain { [weak self] in
                guard let self = self else { return }
                let newVapView = QGVAPWrapView(frame: self.containerView.bounds)
                self.vapView = newVapView
                guard let vapView = self.vapView else { return }
                vapView.translatesAutoresizingMaskIntoConstraints = false
                self.containerView.addSubview(vapView)
                NSLayoutConstraint.activate([
                    vapView.topAnchor.constraint(equalTo: self.containerView.topAnchor),
                    vapView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
                    vapView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
                    vapView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
                ])
                // 应用缩放策略
                self.applyScaleType()
            }
        }
    }

    private func stopPlayback() {
        onMain { [weak self] in
            guard let self = self else { return }
            if self.isPlaying {
                self.vapView?.stopHWDMP4()
                self.isPlaying = false
            }
        }
    }

    private func playVideo(_ videoPath: String) {
        guard vapView != nil else {
            let errorInfo: [String: Any] = [
                "errorType": -1,
                "errorMsg": "VAP view not initialized"
            ]
            invokeOnMain("onFailed", arguments: errorInfo)
            return
        }

        if !FileManager.default.fileExists(atPath: videoPath) {
            let errorInfo: [String: Any] = [
                "errorType": -1,
                "errorMsg": "Video file does not exist: \(videoPath)"
            ]
            invokeOnMain("onFailed", arguments: errorInfo)
            return
        }

        // 确保任何现有播放都被停止，并按缩放策略播放
        onMain { [weak self] in
            guard let self = self, let vapView = self.vapView else { return }
            vapView.stopHWDMP4()
            self.isPlaying = true

            print("FlutterVapPlugin - Playing video from path: \(videoPath)")
            // 播放前应用缩放策略（若外部未来支持动态切换）
            self.applyScaleType()
            vapView.playHWDMP4(videoPath, repeatCount: 0, delegate: self)
        }
    }

    //    开始播放
    func vapWrap_viewDidStartPlayMP4(_ container: UIView) {
        invokeOnMain("onVideoStart", arguments: nil)
    }
    // 每一帧触发
    func vapWrap_viewDidPlayMP4AtFrame(_ frame: QGMP4AnimatedImageFrame) {
        invokeOnMain("onVideoRender", arguments: ["frameIndex": frame.index])
    }
    
    func vapWrap_viewDidStopPlayMP4(_ lastFrameIndex: Int, view container: UIView) {
        onMain { [weak self] in self?.isPlaying = false }
        invokeOnMain("onVideoDestroy", arguments: nil)
    }

    func vapWrap_viewDidFinishPlayMP4(_ totalFrameCount: Int, view container: UIView) {
        onMain { [weak self] in
            self?.isPlaying = false
            self?.vapView?.stopHWDMP4()
        }
        invokeOnMain("onVideoFinish", arguments: nil)
    }

    func vapWrap_viewDidFailPlayMP4(_ error: Error) {
        onMain { [weak self] in self?.isPlaying = false }
        let errorInfo: [String: Any] = [
            "errorType": -1,
            "errorMsg": error.localizedDescription
        ]
        invokeOnMain("onFailed", arguments: errorInfo)
    }
    
    private func destroyInstance() {
        stopPlayback()
        onMain { [weak self] in
            self?.vapView?.removeFromSuperview()
            self?.vapView = nil
        }
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
                invokeOnMain("onFailed", arguments: errorInfo)
            }
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
            let errorInfo: [String: Any] = [
                "errorType": -1,
                "errorMsg": "Unsupported source type: \(sourceType)"
            ]
            invokeOnMain("onFailed", arguments: errorInfo)
        }
    }
}
