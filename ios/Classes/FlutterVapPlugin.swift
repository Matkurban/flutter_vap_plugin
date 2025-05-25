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
    private let repeatCount: Int
    private let autoPlay: Bool
    private var vapView: UIView?
    private var isDownloading = false
    private var channel: FlutterMethodChannel
    private var currentConfig: [String: Any]?
    private var lastPlayedPath: String?
    private var tapGesture: UITapGestureRecognizer?

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
        let params = args as? [String: Any]
        self.path = params?["path"] as? String ?? ""
        self.sourceType = params?["sourceType"] as? String ?? ""
        self.repeatCount = params?["repeatCount"] as? Int ?? 1
        self.autoPlay = params?["autoPlay"] as? Bool ?? true
        self.containerView = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "flutter_vap_plugin_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()
        setupMethodChannel()
        if autoPlay {
            setupVapView()
        } else {
            loadOnly()
        }
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }

            switch call.method {
            case "stop":
                self.vapView?.stopHWDMP4()
                result(nil)
            case "play":
                if let args = call.arguments as? [String: Any],
                   let path = args["path"] as? String,
                   let sourceType = args["sourceType"] as? String {
                    let repeatCount = args["repeatCount"] as? Int ?? 1
                    self.playWithParams(path: path, sourceType: sourceType, repeatCount: repeatCount)
                } else if let path = self.lastPlayedPath {
                    self.playVideo(path)
                }
                result(nil)
            case "destroy":
                self.destroyInstance()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupVapView() {
        // 设置容器视图
        containerView.backgroundColor = .clear

        // 创建 VAP 视图并设置为撑满父容器
        vapView = UIView(frame: containerView.bounds)
        guard let vapView = vapView else { return }

        // 设置自动布局约束使其撑满父视图
        vapView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(vapView)

        NSLayoutConstraint.activate([
            vapView.topAnchor.constraint(equalTo: containerView.topAnchor),
            vapView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            vapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            vapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // 设置视频内容模式为撑满
        vapView.contentMode = .scaleToFill

        // 根据 sourceType 处理不同来源的视频
        switch sourceType {
        case "file":
            playVideo(path)
        case "asset":
            if let resourcePath = Bundle.main.path(forResource: path, ofType: nil) {
                playVideo(resourcePath)
            }
        case "network":
            downloadAndPlay(url: path)
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
        }
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
            downloadOnly(url: path)
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
        }
    }

    private func downloadOnly(url urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileName = url.lastPathComponent
        let localUrl = cacheDir.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: localUrl.path) {
            self.lastPlayedPath = localUrl.path
            return
        }
        let session = URLSession.shared
        let task = session.downloadTask(with: url) { [weak self] (tempUrl, response, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let tempUrl = tempUrl {
                    do {
                        if FileManager.default.fileExists(atPath: localUrl.path) {
                            try FileManager.default.removeItem(at: localUrl)
                        }
                        try FileManager.default.moveItem(at: tempUrl, to: localUrl)
                        self.lastPlayedPath = localUrl.path
                    } catch {
                        print("FlutterVapPlugin - File save error: \(error.localizedDescription)")
                    }
                }
            }
        }
        task.resume()
    }

    private func downloadAndPlay(url urlString: String) {
        guard let url = URL(string: urlString) else {
            print("FlutterVapPlugin - Invalid URL: \(urlString)")
            return
        }

        // 创建本地缓存目录
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileName = url.lastPathComponent
        let localUrl = cacheDir.appendingPathComponent(fileName)

        // 如果本地已经有缓存文件，直接播放
        if FileManager.default.fileExists(atPath: localUrl.path) {
            print("FlutterVapPlugin - Using cached file: \(localUrl.path)")
            playVideo(localUrl.path)
            return
        }

        print("FlutterVapPlugin - Downloading file from: \(urlString)")
        isDownloading = true

        let session = URLSession.shared
        let task = session.downloadTask(with: url) { [weak self] (tempUrl, response, error) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isDownloading = false

                if let error = error {
                    print("FlutterVapPlugin - Download error: \(error.localizedDescription)")
                    return
                }

                guard let tempUrl = tempUrl else {
                    print("FlutterVapPlugin - No file downloaded")
                    return
                }

                do {
                    if FileManager.default.fileExists(atPath: localUrl.path) {
                        try FileManager.default.removeItem(at: localUrl)
                    }
                    try FileManager.default.moveItem(at: tempUrl, to: localUrl)
                    print("FlutterVapPlugin - File downloaded to: \(localUrl.path)")
                    self.playVideo(localUrl.path)
                } catch {
                    print("FlutterVapPlugin - File save error: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }

    private func downloadAndPlay(url urlString: String, repeatCount: Int) {
        guard let url = URL(string: urlString) else {
            print("FlutterVapPlugin - Invalid URL: \(urlString)")
            return
        }
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileName = url.lastPathComponent
        let localUrl = cacheDir.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: localUrl.path) {
            self.playVideo(localUrl.path, repeatCount: repeatCount)
            return
        }
        isDownloading = true
        let session = URLSession.shared
        let task = session.downloadTask(with: url) { [weak self] (tempUrl, response, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isDownloading = false
                if let error = error {
                    print("FlutterVapPlugin - Download error: \(error.localizedDescription)")
                    return
                }
                guard let tempUrl = tempUrl else {
                    print("FlutterVapPlugin - No file downloaded")
                    return
                }
                do {
                    if FileManager.default.fileExists(atPath: localUrl.path) {
                        try FileManager.default.removeItem(at: localUrl)
                    }
                    try FileManager.default.moveItem(at: tempUrl, to: localUrl)
                    print("FlutterVapPlugin - File downloaded to: \(localUrl.path)")
                    self.playVideo(localUrl.path, repeatCount: repeatCount)
                } catch {
                    print("FlutterVapPlugin - File save error: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }

    private func playWithParams(path: String, sourceType: String, repeatCount: Int) {
        switch sourceType {
        case "file":
            self.playVideo(path, repeatCount: repeatCount)
        case "asset":
            if let resourcePath = Bundle.main.path(forResource: path, ofType: nil) {
                self.playVideo(resourcePath, repeatCount: repeatCount)
            }
        case "network":
            self.downloadAndPlay(url: path, repeatCount: repeatCount)
        default:
            print("FlutterVapPlugin - Unsupported source type: \(sourceType)")
        }
    }

    private func playVideo(_ videoPath: String, repeatCount: Int? = nil) {
        print("FlutterVapPlugin - Playing video from path: \(videoPath)")
        guard let vapView = vapView else { return }
        self.lastPlayedPath = videoPath
        vapView.isUserInteractionEnabled = true
        vapView.hwd_enterBackgroundOP = .stop
        if tapGesture == nil {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
            vapView.addGestureRecognizer(gesture)
            tapGesture = gesture
        }
        vapView.playHWDMP4(videoPath, repeatCount: repeatCount ?? self.repeatCount, delegate: self)
    }

    @objc private func onTap(gesture: UIGestureRecognizer) {
        // 异步处理，避免阻塞主线程
        DispatchQueue.main.async { [weak self] in
            self?.vapView?.stopHWDMP4()
        }
    }

    private func destroyInstance() {
        self.vapView?.stopHWDMP4()
        if let tap = tapGesture {
            self.vapView?.removeGestureRecognizer(tap)
            tapGesture = nil
        }
        self.vapView?.removeFromSuperview()
        self.vapView = nil
    }

    // HWDMP4PlayDelegate methods
    func onVapPlayStart() {
        channel.invokeMethod("onVideoStart", arguments: nil)
    }

    func onVapPlayComplete() {
        channel.invokeMethod("onVideoComplete", arguments: nil)
    }

    func onVapDidDestroyed() {
        channel.invokeMethod("onVideoDestroy", arguments: nil)
    }

    func onVapPlayError(_ error: Error) {
        let errorInfo: [String: Any] = [
            "errorType": -1,
            "errorMsg": error.localizedDescription
        ]
        channel.invokeMethod("onFailed", arguments: errorInfo)
    }

    func onVapPlayerFrame(_ frame: Int) {
        channel.invokeMethod("onVideoRender", arguments: ["frameIndex": frame])
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

    func view() -> UIView {
        return containerView
    }

    // dispose 不再自动销毁 vapView，仅解绑 channel
    func dispose() {
        channel.setMethodCallHandler(nil)
    }
}
