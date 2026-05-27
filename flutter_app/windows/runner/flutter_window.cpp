#include "flutter_window.h"

#include <optional>

#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include "flutter/generated_plugin_registrant.h"

typedef int (*WindowsDevID_GetDeviceIdFn)(char*, int);

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Load WindowsDevID.dll once. The DLL must sit next to the .exe
  // (the CMakeLists POST_BUILD rule copies it there automatically).
  devid_dll_ = LoadLibraryA("WindowsDevID.dll");

  machine_id_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.vlearn2/machine_id",
          &flutter::StandardMethodCodec::GetInstance());

  machine_id_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "get") {
          result->NotImplemented();
          return;
        }
        if (!devid_dll_) {
          result->Error("LOAD_ERROR",
                        "WindowsDevID.dll not found beside the executable");
          return;
        }
        auto fn = reinterpret_cast<WindowsDevID_GetDeviceIdFn>(
            GetProcAddress(devid_dll_, "WindowsDevID_GetDeviceId"));
        if (!fn) {
          result->Error("PROC_ERROR",
                        "WindowsDevID_GetDeviceId export not found");
          return;
        }
        char buf[21] = {0};
        fn(buf, sizeof(buf));
        result->Success(flutter::EncodableValue(std::string(buf)));
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  machine_id_channel_.reset();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  if (devid_dll_) {
    FreeLibrary(devid_dll_);
    devid_dll_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
