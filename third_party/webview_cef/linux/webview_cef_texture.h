#ifndef WEBVIEW_CEF_TEXTURE_H_
#define WEBVIEW_CEF_TEXTURE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

struct WebviewCefTexture{
    FlPixelBufferTexture parent_instance;
    uint8_t *buffer = nullptr; // your pixel buffer.
    uint32_t width = 0;
    uint32_t height = 0;
};

struct WebviewCefTextureClass{
    FlPixelBufferTextureClass parent_class;
};

G_DEFINE_TYPE(WebviewCefTexture,
              webview_cef_texture,
              fl_pixel_buffer_texture_get_type())

#define WEBVIEW_CEF_TEXTURE(obj) \
    (G_TYPE_CHECK_INSTANCE_CAST((obj), webview_cef_texture_get_type(), WebviewCefTexture))

static gboolean webview_cef_texture_copy_pixels(FlPixelBufferTexture *texture,
                                                const uint8_t **out_buffer,
                                                uint32_t *width,
                                                uint32_t *height,
                                                GError **error) {
    // This method is called on Render Thread. Be careful with your
    // cross-thread operation.

    // @width and @height are initially stored the canvas size in Flutter.

    // You must prepare your pixel buffer in RGBA format.
    // So you may do some format conversion first if your original pixel
    // buffer is not in RGBA format.
    WebviewCefTexture *_texture = WEBVIEW_CEF_TEXTURE(texture);
    if(_texture == nullptr){
        return TRUE;
    }
    *out_buffer = _texture->buffer;
    *width = _texture->width;
    *height = _texture->height;
    return TRUE;
}
static WebviewCefTexture* webview_cef_texture_new(){
    return WEBVIEW_CEF_TEXTURE(g_object_new(webview_cef_texture_get_type(), nullptr));
}

static void webview_cef_texture_class_init(WebviewCefTextureClass *klass)
{
    FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = webview_cef_texture_copy_pixels;
}
static void webview_cef_texture_init(WebviewCefTexture *self) {}


#endif // WEBVIEW_CEF_TEXTURE_H_
