#include <clocale>
#include "my_application.h"

int main(int argc, char** argv) {
  // Required by libmpv (used in media_kit / just_audio_media_kit).
  // Non-C LC_NUMERIC causes libmpv to abort or segfault.
  setlocale(LC_NUMERIC, "C");
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
