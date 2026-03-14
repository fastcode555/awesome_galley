#include "platform_channel_handler.h"

#include <windows.h>
#include <shlobj.h>
#include <propvarutil.h>
#include <propsys.h>
#include <propkey.h>
#include <iostream>
#include <sstream>

#pragma comment(lib, "propsys.lib")

namespace image_gallery {

namespace {

// Convert std::string to std::wstring
std::wstring StringToWString(const std::string& str) {
  if (str.empty()) return std::wstring();
  int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
  std::wstring wstr(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstr[0], size_needed);
  return wstr;
}

// Convert std::wstring to std::string
std::string WStringToString(const std::wstring& wstr) {
  if (wstr.empty()) return std::string();
  int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
  std::string str(size_needed, 0);
  WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &str[0], size_needed, NULL, NULL);
  return str;
}

// Register a file extension in the Windows Registry
bool RegisterExtension(const std::string& extension, const std::string& prog_id,
                      const std::string& app_name, const std::string& app_path) {
  HKEY hKey;
  std::wstring ext_w = StringToWString(extension);
  std::wstring prog_id_w = StringToWString(prog_id);
  
  // Create extension key
  if (RegCreateKeyExW(HKEY_CURRENT_USER, 
                     (L"Software\\Classes\\" + ext_w).c_str(),
                     0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) != ERROR_SUCCESS) {
    return false;
  }
  
  // Set default value to ProgID
  RegSetValueExW(hKey, NULL, 0, REG_SZ, 
                (BYTE*)prog_id_w.c_str(), 
                (DWORD)((prog_id_w.length() + 1) * sizeof(wchar_t)));
  RegCloseKey(hKey);
  
  // Create ProgID key
  if (RegCreateKeyExW(HKEY_CURRENT_USER,
                     (L"Software\\Classes\\" + prog_id_w).c_str(),
                     0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) != ERROR_SUCCESS) {
    return false;
  }
  
  std::wstring app_name_w = StringToWString(app_name);
  RegSetValueExW(hKey, NULL, 0, REG_SZ,
                (BYTE*)app_name_w.c_str(),
                (DWORD)((app_name_w.length() + 1) * sizeof(wchar_t)));
  RegCloseKey(hKey);
  
  // Create shell\open\command key
  std::wstring command_key = L"Software\\Classes\\" + prog_id_w + L"\\shell\\open\\command";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, command_key.c_str(),
                     0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) != ERROR_SUCCESS) {
    return false;
  }
  
  // Set command to open files with this application
  std::wstring command = L"\"" + StringToWString(app_path) + L"\" \"%1\"";
  RegSetValueExW(hKey, NULL, 0, REG_SZ,
                (BYTE*)command.c_str(),
                (DWORD)((command.length() + 1) * sizeof(wchar_t)));
  RegCloseKey(hKey);
  
  return true;
}

// Extract EXIF data using Windows Property System
flutter::EncodableMap ExtractExifDataWindows(const std::string& file_path) {
  flutter::EncodableMap exif_data;
  
  std::wstring file_path_w = StringToWString(file_path);
  IPropertyStore* pPropertyStore = NULL;
  
  HRESULT hr = SHGetPropertyStoreFromParsingName(
      file_path_w.c_str(),
      NULL,
      GPS_DEFAULT,
      IID_PPV_ARGS(&pPropertyStore));
  
  if (SUCCEEDED(hr) && pPropertyStore) {
    PROPVARIANT pv;
    PropVariantInit(&pv);
    
    // Extract date taken
    if (SUCCEEDED(pPropertyStore->GetValue(PKEY_Photo_DateTaken, &pv))) {
      if (pv.vt == VT_FILETIME) {
        SYSTEMTIME st;
        FileTimeToSystemTime(&pv.filetime, &st);
        std::ostringstream oss;
        oss << st.wYear << "-" 
            << std::setfill('0') << std::setw(2) << st.wMonth << "-"
            << std::setfill('0') << std::setw(2) << st.wDay << " "
            << std::setfill('0') << std::setw(2) << st.wHour << ":"
            << std::setfill('0') << std::setw(2) << st.wMinute << ":"
            << std::setfill('0') << std::setw(2) << st.wSecond;
        exif_data[flutter::EncodableValue("dateTaken")] = 
            flutter::EncodableValue(oss.str());
      }
      PropVariantClear(&pv);
    }
    
    // Extract camera make
    if (SUCCEEDED(pPropertyStore->GetValue(PKEY_Photo_CameraManufacturer, &pv))) {
      if (pv.vt == VT_LPWSTR) {
        exif_data[flutter::EncodableValue("cameraMake")] = 
            flutter::EncodableValue(WStringToString(pv.pwszVal));
      }
      PropVariantClear(&pv);
    }
    
    // Extract camera model
    if (SUCCEEDED(pPropertyStore->GetValue(PKEY_Photo_CameraModel, &pv))) {
      if (pv.vt == VT_LPWSTR) {
        exif_data[flutter::EncodableValue("cameraModel")] = 
            flutter::EncodableValue(WStringToString(pv.pwszVal));
      }
      PropVariantClear(&pv);
    }
    
    // Extract GPS latitude
    double latitude = 0.0;
    if (SUCCEEDED(pPropertyStore->GetValue(PKEY_GPS_Latitude, &pv))) {
      if (pv.vt == VT_VECTOR && pv.capropvar.cElems >= 3) {
        // GPS coordinates are stored as degrees, minutes, seconds
        // Convert to decimal degrees
        latitude = pv.capropvar.pElems[0].dblVal + 
                  pv.capropvar.pElems[1].dblVal / 60.0 +
                  pv.capropvar.pElems[2].dblVal / 3600.0;
      }
      PropVariantClear(&pv);
    }
    
    // Extract GPS longitude
    double longitude = 0.0;
    if (SUCCEEDED(pPropertyStore->GetValue(PKEY_GPS_Longitude, &pv))) {
      if (pv.vt == VT_VECTOR && pv.capropvar.cElems >= 3) {
        longitude = pv.capropvar.pElems[0].dblVal + 
                   pv.capropvar.pElems[1].dblVal / 60.0 +
                   pv.capropvar.pElems[2].dblVal / 3600.0;
      }
      PropVariantClear(&pv);
    }
    
    if (latitude != 0.0 || longitude != 0.0) {
      exif_data[flutter::EncodableValue("latitude")] = 
          flutter::EncodableValue(latitude);
      exif_data[flutter::EncodableValue("longitude")] = 
          flutter::EncodableValue(longitude);
    }
    
    pPropertyStore->Release();
  }
  
  return exif_data;
}

}  // namespace

PlatformChannelHandler::PlatformChannelHandler() = default;
PlatformChannelHandler::~PlatformChannelHandler() = default;

void PlatformChannelHandler::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto handler = std::make_unique<PlatformChannelHandler>();
  
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "image_gallery/platform",
      &flutter::StandardMethodCodec::GetInstance());
  
  channel->SetMethodCallHandler(
      [handler_ptr = handler.get()](const auto& call, auto result) {
        handler_ptr->HandleMethodCall(call, std::move(result));
      });
  
  handler->channel_ = std::move(channel);
  
  // Keep handler alive
  registrar->AddPlugin(std::move(handler));
}

void PlatformChannelHandler::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string& method = method_call.method_name();
  
  if (method == "registerFileAssociations") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
      return;
    }
    
    // Extract extensions
    std::vector<std::string> extensions;
    auto ext_it = arguments->find(flutter::EncodableValue("extensions"));
    if (ext_it != arguments->end()) {
      const auto* ext_list = std::get_if<flutter::EncodableList>(&ext_it->second);
      if (ext_list) {
        for (const auto& ext : *ext_list) {
          const auto* ext_str = std::get_if<std::string>(&ext);
          if (ext_str) {
            extensions.push_back(*ext_str);
          }
        }
      }
    }
    
    // Extract app name
    std::string app_name = "Image Gallery Viewer";
    auto name_it = arguments->find(flutter::EncodableValue("appName"));
    if (name_it != arguments->end()) {
      const auto* name_str = std::get_if<std::string>(&name_it->second);
      if (name_str) {
        app_name = *name_str;
      }
    }
    
    // Extract app path
    std::string app_path;
    auto path_it = arguments->find(flutter::EncodableValue("appPath"));
    if (path_it != arguments->end()) {
      const auto* path_str = std::get_if<std::string>(&path_it->second);
      if (path_str) {
        app_path = *path_str;
      }
    }
    
    RegisterFileAssociations(extensions, app_name, app_path, std::move(result));
    
  } else if (method == "setAsDefaultApp") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
      return;
    }
    
    std::vector<std::string> extensions;
    auto ext_it = arguments->find(flutter::EncodableValue("extensions"));
    if (ext_it != arguments->end()) {
      const auto* ext_list = std::get_if<flutter::EncodableList>(&ext_it->second);
      if (ext_list) {
        for (const auto& ext : *ext_list) {
          const auto* ext_str = std::get_if<std::string>(&ext);
          if (ext_str) {
            extensions.push_back(*ext_str);
          }
        }
      }
    }
    
    SetAsDefaultApp(extensions, std::move(result));
    
  } else if (method == "extractExifData") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
      return;
    }
    
    std::string file_path;
    auto path_it = arguments->find(flutter::EncodableValue("filePath"));
    if (path_it != arguments->end()) {
      const auto* path_str = std::get_if<std::string>(&path_it->second);
      if (path_str) {
        file_path = *path_str;
      }
    }
    
    ExtractExifData(file_path, std::move(result));
    
  } else {
    result->NotImplemented();
  }
}

void PlatformChannelHandler::RegisterFileAssociations(
    const std::vector<std::string>& extensions,
    const std::string& app_name,
    const std::string& app_path,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (app_path.empty()) {
    result->Error("INVALID_PATH", "Application path is required");
    return;
  }
  
  std::string prog_id = "ImageGalleryViewer.Image";
  bool success = true;
  
  for (const auto& ext : extensions) {
    if (!RegisterExtension(ext, prog_id, app_name, app_path)) {
      success = false;
      break;
    }
  }
  
  if (success) {
    // Notify shell of changes
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, NULL, NULL);
    result->Success();
  } else {
    result->Error("REGISTRATION_FAILED", "Failed to register file associations");
  }
}

void PlatformChannelHandler::SetAsDefaultApp(
    const std::vector<std::string>& extensions,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  // On Windows 10+, we need to open Settings for the user to set default apps
  // We can't programmatically set default apps without user interaction
  
  // Open Windows Settings to Default Apps
  ShellExecuteW(NULL, L"open", L"ms-settings:defaultapps", NULL, NULL, SW_SHOWNORMAL);
  
  result->Success();
}

void PlatformChannelHandler::ExtractExifData(
    const std::string& file_path,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (file_path.empty()) {
    result->Error("INVALID_PATH", "File path is required");
    return;
  }
  
  try {
    flutter::EncodableMap exif_data = ExtractExifDataWindows(file_path);
    
    if (exif_data.empty()) {
      result->Success();  // No EXIF data found, return null
    } else {
      result->Success(flutter::EncodableValue(exif_data));
    }
  } catch (...) {
    result->Error("EXTRACTION_FAILED", "Failed to extract EXIF data");
  }
}

}  // namespace image_gallery
