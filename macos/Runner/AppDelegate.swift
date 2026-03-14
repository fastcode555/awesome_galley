import Cocoa
import FlutterMacOS
import ImageIO

@main
class AppDelegate: FlutterAppDelegate {
  private var openedFiles: [String] = []
  private var methodChannel: FlutterMethodChannel?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Get the Flutter view controller
    if let window = NSApplication.shared.windows.first,
       let flutterViewController = window.contentViewController as? FlutterViewController {
      
      // Set up method channel
      methodChannel = FlutterMethodChannel(
        name: "image_gallery/platform",
        binaryMessenger: flutterViewController.engine.binaryMessenger
      )
      
      methodChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleMethodCall(call: call, result: result)
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
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    openedFiles.append(filename)
    return true
  }
  
  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    openedFiles.append(contentsOf: filenames)
  }
  
  // Handle method calls from Dart
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "verifyFileAssociations":
      // File associations are configured in Info.plist
      // This is just a verification method
      result(nil)
      
    case "openDefaultAppSettings":
      // Open System Preferences to Default Apps
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?General") {
        NSWorkspace.shared.open(url)
      }
      result(nil)
      
    case "getOpenedFiles":
      result(openedFiles)
      openedFiles.removeAll() // Clear after returning
      
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
