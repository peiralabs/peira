#include "my_application.h"

#include <webview_cef/webview_cef_plugin.h>

int main(int argc, char** argv) {
  // Chromium's multi-process architecture re-executes this binary for each
  // CEF sub-process; those runs must exit here with the returned code and
  // never start the Flutter app. Returns -1 in the main (browser) process.
  int exit_code = initCEFProcesses(argc, argv);
  if (exit_code >= 0) {
    return exit_code;
  }

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
