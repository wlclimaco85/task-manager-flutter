#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(HINSTANCE instance,
                      HINSTANCE prev,
                      wchar_t *command_line,
                      int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a new
  // one when debugging.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

  flutter::DartProject project(L"data");

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);

  // ❗ Aqui muda: agora se usa window.Create()
  if (!window.Create(L"Portal Cont", origin, size)) {
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(true);

  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  return EXIT_SUCCESS;
}
