import UIKit
import Flutter
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let STORAGE_CHANNEL = "com.productra.shootsolo/storage"
    private let MEDIA_CHANNEL = "com.productra.shootsolo/media"
    var orientationLock = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not a FlutterViewController")
        }

        // Storage Channel Handler
        let storageChannel = FlutterMethodChannel(name: STORAGE_CHANNEL, binaryMessenger: controller.binaryMessenger)
        storageChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            if call.method == "getAvailableStorage" {
                if let availableStorage = self.getAvailableStorage() {
                    result(availableStorage)
                } else {
                    result(FlutterError(code: "UNAVAILABLE", message: "Could not get available storage.", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        // Media Channel Handler
        let mediaChannel = FlutterMethodChannel(name: MEDIA_CHANNEL, binaryMessenger: controller.binaryMessenger)
        mediaChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            if call.method == "addToGallery" {
                guard let arguments = call.arguments as? [String: Any],
                      let path = arguments["path"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
                    return
                }
                self.addVideoToGallery(path: path, result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Get available storage in bytes
    private func getAvailableStorage() -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemFreeSize] as? Int64
        } catch {
            print("Error getting storage info: \(error.localizedDescription)")
            return nil
        }
    }

    // Save video to Photos Library
    private func addVideoToGallery(path: String, result: @escaping FlutterResult) {
        let fileURL = URL(fileURLWithPath: path)

        // Ensure the file exists
        guard FileManager.default.fileExists(atPath: path) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "The specified file does not exist.", details: nil))
            return
        }

        // Request Photo Library access
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access is denied.", details: nil))
                }
                return
            }

            // Save video
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        result("Video added to gallery successfully.")
                    } else {
                        let errorMessage = error?.localizedDescription ?? "Unknown error"
                        result(FlutterError(code: "FAILED", message: "Failed to add video to gallery.", details: errorMessage))
                    }
                }
            }
        }
    }
}
