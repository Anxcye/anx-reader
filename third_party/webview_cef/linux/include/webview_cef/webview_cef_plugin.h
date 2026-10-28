#ifndef FLUTTER_PLUGIN_WEBVIEW_CEF_PLUGIN_H_
#define FLUTTER_PLUGIN_WEBVIEW_CEF_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>
#include <string>
G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _WebviewCefPlugin WebviewCefPlugin;
typedef struct {
  GObjectClass parent_class;
} WebviewCefPluginClass;

FLUTTER_PLUGIN_EXPORT GType webview_cef_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void webview_cef_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

FLUTTER_PLUGIN_EXPORT int initCEFProcesses(int argc, char** argv);

FLUTTER_PLUGIN_EXPORT gboolean processKeyEventForCEF(GtkWidget* widget, GdkEventKey* event, gpointer data);

#endif  // FLUTTER_PLUGIN_WEBVIEW_CEF_PLUGIN_H_
