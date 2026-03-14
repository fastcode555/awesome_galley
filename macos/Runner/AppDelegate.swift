import Cocoa
import FlutterMacOS
import ImageIO

@main
class AppDelegate: FlutterAppDelegate {
  private var openedFiles: [String] = []
  private var methodChannel: FlutterMethodChannel?
  private var pendingFileResult: FlutterResult?
  
  override func applicationWillFinishLaunching(_ notification: Notification) {
    // 注册 Apple Event handler，必须在 applicationDidFinishLaunching 之前注册
    // 这样才能捕获冷启动时的 open document 事件
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleOpenDocuments(_:withReplyEvent:)),
      forEventClass: AEEventClass(kCoreEventClass),
      andEventID: AEEventID(kAEOpenDocuments)
    )
  }
  
  @objc func handleOpenDocuments(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
    guard let fileList = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
      NSLog("[AppDelegate] handleOpenDocuments: no file list")
      return
    }
    
    var paths: [String] = []
    let count = fileList.numberOfItems
    NSLog("[AppDelegate] handleOpenDocuments: \(count) item(s), type: \(fileList.descriptorType)")
    
    func extractPath(from desc: NSAppleEventDescriptor) -> String? {
      // 尝试 typeFileURL
      if let urlDesc = desc.coerce(toDescriptorType: DescType(typeFileURL)) {
        let urlData = urlDesc.data
        if let urlString = String(data: urlData, encoding: .utf8) {
          let cleaned = urlString.trimmingCharacters(in: .controlCharacters)
          if let url = URL(string: cleaned) { return url.path }
        }
      }
      // 尝试直接 stringValue（有时是 file:// URL 或路径）
      if let s = desc.stringValue {
        if s.hasPrefix("file://"), let url = URL(string: s) { return url.path }
        if s.hasPrefix("/") { return s }
      }
      return nil
    }
    
    if count == 0 {
      // 单个文件（numberOfItems 为 0 表示不是列表）
      if let path = extractPath(from: fileList) {
        paths.append(path)
      }
    } else {
      for i in 1...count {
        if let item = fileList.atIndex(i), let path = extractPath(from: item) {
          paths.append(path)
        }
      }
    }
    
    NSLog("[AppDelegate] handleOpenDocuments paths: \(paths)")
    
    if let channel = methodChannel {
      for path in paths {
        NSLog("[AppDelegate] pushing fileOpened: \(path)")
        channel.invokeMethod("fileOpened", arguments: path)
      }
    } else {
      openedFiles.append(contentsOf: paths)
    }
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = NSApplication.shared.windows.first,
       let flutterViewController = window.contentViewController as? FlutterViewController {
      
      methodChannel = FlutterMethodChannel(
        name: "image_gallery/platform",
        binaryMessenger: flutterViewController.engine.binaryMessenger
      )
      
      methodChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleMethodCall(call: call, result: result)
      }
      
      // 冷启动时 openedFiles 可能已有数据（来自 handleOpenDocuments 或 openFile 回调）
      if !openedFiles.isEmpty {
        let filesToSend = openedFiles
        openedFiles.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
          NSLog("[AppDelegate] Cold launch: pushing \(filesToSend.count) file(s) to Flutter")
          for file in filesToSend {
            self?.methodChannel?.invokeMethod("fileOpened", arguments: file)
          }
        }
      }
    }
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  // Handle files opened via Finder
  // - Cold launch: called BEFORE applicationDidFinishLaunching, stored in openedFiles
  // - Hot launch (app already running): methodChannel is ready, push directly to Flutter
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    NSLog("[AppDelegate] openFile: \(filename)")
    if let channel = methodChannel {
      NSLog("[AppDelegate] app already running, pushing fileOpened to Flutter")
      channel.invokeMethod("fileOpened", arguments: filename)
    } else {
      openedFiles.append(filename)
    }
    return true
  }
  
  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    NSLog("[AppDelegate] openFiles: \(filenames)")
    if let channel = methodChannel {
      for filename in filenames {
        channel.invokeMethod("fileOpened", arguments: filename)
      }
    } else {
      openedFiles.append(contentsOf: filenames)
    }
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "verifyFileAssociations":
      result(nil)
      
    case "openDefaultAppSettings":
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?General") {
        NSWorkspace.shared.open(url)
      }
      result(nil)
      
    case "getOpenedFiles":
      NSLog("[AppDelegate] getOpenedFiles called, files: \(openedFiles)")
      result(openedFiles)
      openedFiles.removeAll()
      
    case "extractExifData":
      guard let args = call.arguments as? [String: Any],
            let filePath = args["filePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "File path is required",
                          details: nil))
        return
      }
      let exifData = extractExifData(from: filePath)
      result(exifData)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // Extract EXIF data using ImageIO framework
  private func extractExifData(from filePath: String) -> [String: Any]? {
    guard let imageSource = CGImageSourceCreateWithURL(
      URL(fileURLWithPath: filePath) as CFURL, nil
    ) else {
      return nil
    }
    
    guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(
      imageSource, 0, nil
    ) as? [String: Any] else {
      return nil
    }
    
    var exifData: [String: Any] = [:]
    
    // Extract EXIF data
    if let exif = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
      // Date taken
      if let dateTime = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
        exifData["dateTaken"] = dateTime
      }
      
      // Camera make and model
      if let tiff = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
        if let make = tiff[kCGImagePropertyTIFFMake as String] as? String {
          exifData["cameraMake"] = make
        }
        if let model = tiff[kCGImagePropertyTIFFModel as String] as? String {
          exifData["cameraModel"] = model
        }
      }
      
      // Focal length
      if let focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double {
        exifData["focalLength"] = focalLength
      }
      
      // Aperture
      if let aperture = exif[kCGImagePropertyExifFNumber as String] as? Double {
        exifData["aperture"] = aperture
      }
      
      // ISO
      if let iso = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int],
         let isoValue = iso.first {
        exifData["iso"] = String(isoValue)
      }
      
      // Exposure time
      if let exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double {
        exifData["exposureTime"] = String(format: "1/%.0f", 1.0 / exposureTime)
      }
    }
    
    // Extract GPS data
    if let gps = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
      if let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
         let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
         let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
         let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
        
        // Convert to signed decimal degrees
        let signedLatitude = latitudeRef == "N" ? latitude : -latitude
        let signedLongitude = longitudeRef == "E" ? longitude : -longitude
        
        exifData["latitude"] = signedLatitude
        exifData["longitude"] = signedLongitude
      }
    }
    
    return exifData.isEmpty ? nil : exifData
  }
}
