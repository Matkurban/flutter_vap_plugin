import Flutter
import UIKit
import QGVAPlayer

public class FlutterVapPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = FlutterVapPluginViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "flutter_vap_plugin")
    }
}

class FlutterVapPluginViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
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
            args: args
        )
    }
}

class FlutterVapView: NSObject, FlutterPlatformView, HWDMP4PlayDelegate {
    private let containerView: UIView
    private let path: String
    private let sourceType: String
    private let autoPlay: Bool
    private weak var vapView: QGVAPView?
    private var isDownloading = false
    private var channel: FlutterMethodChannel
    private var currentConfig: [String: Any]?
    private var lastPlayedPath: String?
    private var tapGesture: UITapGestureRecognizer?
    private var isDestroyed = false

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        let params = args as? [String: Any]
        self.path = params?["path"] as? String ?? ""
        self.sourceType = params?["sourceType"] as? String ?? ""
        self.autoPlay = params?["autoPlay"] as? Bool ?? true
        self.containerView = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "flutter_vap_plugin_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        // 确保在主线程设置 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupMethodChannel()
            if self.autoPlay {
                self.setupVapView()
            } else {
                self.loadOnly()
            }
        }
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self, !self.isDestroyed else {
                result(FlutterError(code: "DESTROYED", message: "View was destroyed", details: nil))
                return
            }

            switch call.method {
            case "stop":
                self.stopPlayback()
                result(nil)
            case "play":
                if let args = call.arguments as? [String: Any],
                   let path = args["path"] as? String,
                   let sourceType = args["sourceType"] as? String {
                    self.playWithParams(path: path, sourceType: sourceType)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for play", details: nil))
                }
            case "destroy":
                self.destroyInstance()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupVapView() {
        containerView.backgroundColor = .clear

        let newVapView = QGVAPView(frame: containerView.bounds)
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

        switch sourceType {
        case "file":
            playVideo(path)
        case "asset":
            if let resourcePath = Bundle.main.path(forResource: path, ofType: nil) {
                playVideo(resourcePath)
            }
        case "network":
            playVideo(path)
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
        }
    }

    private func stopPlayback() {
        DispatchQueue.main.async { [weak self] in
            self?.vapView?.stopHWDMP4()
        }
    }

    private func playVideo(_ videoPath: String) {
        guard !isDestroyed else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let vapView = self.vapView else { return }

            print("FlutterVapPlugin - Playing video from path: \(videoPath)")
            self.lastPlayedPath = videoPath
            vapView.isUserInteractionEnabled = true
            vapView.hwd_enterBackgroundOP = .stop

            if self.tapGesture == nil {
                let gesture = UITapGestureRecognizer(target: self, action: #selector(self.onTap))
                vapView.addGestureRecognizer(gesture)
                self.tapGesture = gesture
            }

            let config = QGVAPConfigModel()
            if self.sourceType == "network" {
                vapView.playHWDMP4(videoPath, config: config, delegate: self)
            } else {
                vapView.playMP4(videoPath, config: config, delegate: self)
            }
        }
    }

    // HWDMP4PlayDelegate methods
    func onVapPlayStart() {
        guard !isDestroyed else { return }
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onVideoStart", arguments: nil)
        }
    }

    func onVapPlayComplete() {
        guard !isDestroyed else { return }
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onVideoComplete", arguments: nil)
        }
    }

    func onVapDidDestroyed() {
        guard !isDestroyed else { return }
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onVideoDestroy", arguments: nil)
        }
    }

    func onVapPlayError(_ error: Error) {
        guard !isDestroyed else { return }
        DispatchQueue.main.async { [weak self] in
            let errorInfo: [String: Any] = [
                "errorType": -1,
                "errorMsg": error.localizedDescription
            ]
            self?.channel.invokeMethod("onFailed", arguments: errorInfo)
        }
    }

    func onVapPlayerFrame(_ frame: Int) {
        guard !isDestroyed else { return }
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod("onVideoRender", arguments: ["frameIndex": frame])
        }
    }

    private func destroyInstance() {
        isDestroyed = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stopPlayback()
            if let tap = self.tapGesture {
                self.vapView?.removeGestureRecognizer(tap)
                self.tapGesture = nil
            }
            self.vapView?.removeFromSuperview()
            self.vapView = nil
        }
    }

    deinit {
        destroyInstance()
    }

    func dispose() {
        destroyInstance()
        channel.setMethodCallHandler(nil)
    }

    func view() -> UIView {
        return containerView
    }

    private func loadOnly() {
        // 只加载资源，不自动播放
        switch sourceType {
        case "file":
            self.lastPlayedPath = path
        case "asset":
            if let resourcePath = Bundle.main.path(forResource: path, ofType: nil) {
                self.lastPlayedPath = resourcePath
            }
        case "network":
            self.lastPlayedPath = path
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
        }
    }

    private func playWithParams(path: String, sourceType: String) {
        switch sourceType {
        case "file":
            self.playVideo(path)
        case "asset":
            if let resourcePath = Bundle.main.path(forResource: path, ofType: nil) {
                self.playVideo(resourcePath)
            }
        case "network":
            self.playVideo(path)
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
        }
    }

    @objc private func onTap(gesture: UIGestureRecognizer) {
        // 异步处理，避免阻塞主线程
        DispatchQueue.main.async { [weak self] in
            self?.vapView?.stopHWDMP4()
        }
    }

    func onVapConfigReady(_ config: [String: Any]) {
        self.currentConfig = config
        channel.invokeMethod("onVideoConfigReady", arguments: nil)
    }

    func content(forVapTag tag: String!, resource info: QGVAPSourceInfo) -> String {
        return ""
    }

    func loadVapImage(withURL urlStr: String!, context: [AnyHashable : Any]!, completion completionBlock: VAPImageCompletionBlock!) {
        DispatchQueue.main.async {
            completionBlock(nil, nil, urlStr)
        }
    }
}
