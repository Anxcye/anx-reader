#ifndef WEBVIEW_PLUGIN_H
#define WEBVIEW_PLUGIN_H

#include "webview_value.h"
#include "webview_app.h"
#include <include/cef_base.h>

#include <functional>
namespace webview_cef {
    class WebviewTexture{
    public:
        virtual ~WebviewTexture(){}
        // Software off-screen frame (CPU BGRA buffer from CefRenderHandler::OnPaint).
        virtual void onFrame(const void* buffer, int width, int height){}
        // GPU accelerated frame (shared texture handle from OnAcceleratedPaint).
        virtual void onAcceleratedFrame(const void* sharedHandle, int width, int height, int format){}
        int64_t textureId = 0;
        bool isFocused = false;
        // IME state for THIS browser (a single plugin can host several). The
        // macOS key router consults the focused browser's state so one webview's
        // editable focus / composition never gates another's keyboard input.
        bool editableFocused = false;  // a web editable node is focused
        bool composing = false;        // the OS IME has an active marked composition
    };
    class WebviewPlugin {
    public:
        WebviewPlugin();
        ~WebviewPlugin();
        void initCallback();
        void uninitCallback();
        void HandleMethodCall(std::string name, WValue* values, std::function<void(int ,WValue*)> result);
        void sendKeyEvent(CefKeyEvent& ev);
        void setInvokeMethodFunc(std::function<void(std::string, WValue*)> func);
        void setCreateTextureFunc(std::function<std::shared_ptr<WebviewTexture>()> func);
        bool getAnyBrowserFocused();
        // Drive one external BeginFrame for this plugin's browsers (GPU path).
        void tickBeginFrame();
        // IME state of the currently focused browser (see WebviewTexture). The
        // macOS key router uses these to send text/composition keys to the OS
        // IME and navigation/control keys to CEF. Per-browser, so one webview's
        // composition never gates another's keyboard input.
        bool isEditableFocused();
        bool isComposing();

        // Native IME pipeline forwarders (driven by the Windows WM_IME_* handler).
        void imeSetCompositionNative(const std::wstring& text, int cursor);
        void imeCommitTextNative(const std::wstring& text);
        void imeFinishCompositionNative();

    private :
        // Resolve the browserId whose renderer currently has focus, or -1.
        int focusedBrowserId();
        // Set the composing flag for a specific browser (no-op if unknown).
        void setComposingForBrowser(int browserId, bool composing);
        int cursorAction(WValue *args, std::string name);
    	std::function<void(std::string, WValue*)> m_invokeFunc;
	    std::function<std::shared_ptr<WebviewTexture>()> m_createTextureFunc;
        CefRefPtr<WebviewHandler> m_handler;
	    CefRefPtr<WebviewApp> m_app;
    	std::unordered_map<int, std::shared_ptr<WebviewTexture>> m_renderers;
	    bool m_init = false;
    };

    int initCEFProcesses(CefMainArgs args);
    int initCEFProcesses();
    void startCEF();
#ifdef OS_MAC
    // macOS multi-process: the platform layer (Obj-C) resolves these from the
    // app bundle and sets them before startCEF() so CEF can launch the bundled
    // helper sub-processes. Must be called before startCEF().
    void setMacCEFPaths(const std::string& subprocessPath,
                        const std::string& frameworkDirPath,
                        const std::string& mainBundlePath);
#endif
    void doMessageLoopWork();
    void SwapBufferFromBgraToRgba(void* _dest, const void* _src, int width, int height);
    void stopCEF();
}

#endif //WEBVIEW_PLUGIN_H
