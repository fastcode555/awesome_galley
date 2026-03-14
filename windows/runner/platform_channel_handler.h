#ifndef RUNNER_PLATFORM_CHANNEL_HANDLER_H_
#define RUNNER_PLATFORM_CHANNEL_HANDLER_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>
#include <vector>

namespace image_gallery {

// Handler for platform-specific method calls from Dart
class PlatformChannelHandler {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar);

 private:
  PlatformChannelHandler();
  ~PlatformChannelHandler();

  // Handle method calls from Dart
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Register file associations in Windows Registry
  void RegisterFileAssociations(
      const std::vector<std::string>& extensions,
      const std::string& app_name,
      const std::string& app_path,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Set application as default for file types
  void SetAsDefaultApp(
      const std::vector<std::string>& extensions,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Extract EXIF data from image file
  void ExtractExifData(
      const std::string& file_path,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

}  // namespace image_gallery

#endif  // RUNNER_PLATFORM_CHANNEL_HANDLER_H_
