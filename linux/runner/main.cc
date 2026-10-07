#include "my_application.h"

#include <webview_cef/webview_cef_plugin.h>

int main(int argc, char** argv) {
  // Chromium's multi-process architecture re-executes this binary for each
  // CEF sub-process; those runs must exit here with the returned code and
  // never start the Flutter app. Returns -1 in the main (browser) process.
  //
  // Passing argv straight through hands CEF its own command-line switches:
  // CefMainArgs(argc, argv) feeds both CefExecuteProcess and CefInitialize, so
  // Chromium switches given on our command line take effect — notably
  // `--ozone-platform=wayland` for the Wayland experiment. GApplication never
  // sees them as errors because our local_command_line override does no
  // GOption parsing (see my_application.cc).
  int exit_code = initCEFProcesses(argc, argv);
  if (exit_code >= 0) {
    return exit_code;
  }

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
