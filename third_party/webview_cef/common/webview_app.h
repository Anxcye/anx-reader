// Copyright (c) 2013 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#ifndef CEF_TESTS_CEFSIMPLE_SIMPLE_APP_H_
#define CEF_TESTS_CEFSIMPLE_SIMPLE_APP_H_

#include <functional>
#include "webview_handler.h"
#include "webview_js_handler.h"

// Implement application-level callbacks for the browser process.
class WebviewApp : public CefApp, public CefBrowserProcessHandler, public CefRenderProcessHandler{
public:
    WebviewApp(CefRefPtr<WebviewHandler> handler);

    WebviewApp(){};

    enum ProcessType{
        BrowserProcess,
        RendererProcess,
        ZygoteProcess,
        OtherProcess,
    };

    static ProcessType GetProcessType(CefRefPtr<CefCommandLine> command_line);
    
    // CefApp methods:
    CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
        return this;
    }

    CefRefPtr<CefRenderProcessHandler> GetRenderProcessHandler() override { 
        return this; 
    }
    // CefBrowserProcessHandler methods:
    void OnBeforeCommandLineProcessing(
        const CefString& process_type,
        CefRefPtr<CefCommandLine> command_line) override;
    void SetProcessMode(uint32_t uMode);
    void SetEnableGPU(bool bEnable);
    void OnContextInitialized() override;
    // CefRefPtr<CefClient> GetDefaultClient() override;
    void OnBeforeChildProcessLaunch(CefRefPtr<CefCommandLine> command_line) override;
    void SetUnSafelyTreatInsecureOriginAsSecure(const CefString& strFilterDomain);

    // CefRenderProcessHandler methods.
    void OnWebKitInitialized() override;
    void OnBrowserCreated(
        CefRefPtr<CefBrowser> browser,
        CefRefPtr<CefDictionaryValue> extra_info) override;
    void OnBrowserDestroyed(CefRefPtr<CefBrowser> browser) override;
    void OnContextCreated(
        CefRefPtr<CefBrowser> browser,
        CefRefPtr<CefFrame> frame, 
        CefRefPtr<CefV8Context> context) override;
    void OnContextReleased(
        CefRefPtr<CefBrowser> browser, 
        CefRefPtr<CefFrame> frame,
        CefRefPtr<CefV8Context> context) override;
    void OnUncaughtException(
        CefRefPtr<CefBrowser> browser,
        CefRefPtr<CefFrame> frame,
        CefRefPtr<CefV8Context> context,
        CefRefPtr<CefV8Exception> exception,
        CefRefPtr<CefV8StackTrace> stackTrace) override;
    void OnFocusedNodeChanged(
        CefRefPtr<CefBrowser> browser,
        CefRefPtr<CefFrame> frame,
        CefRefPtr<CefDOMNode> node) override;
    bool OnProcessMessageReceived(
        CefRefPtr<CefBrowser> browser,
        CefRefPtr<CefFrame> frame,
        CefProcessId source_process,
        CefRefPtr<CefProcessMessage> message) override;
    
private:
    uint32_t                        m_uMode = 1;                        //process mode
    bool                            m_bEnableGPU = false;               //enable gpu
    CefString                       m_strFilterDomain;                  //insecure domain whitelist       

    CefRefPtr<WebviewHandler>       m_handler;                          //webview handler for main process
    std::shared_ptr<CefJSBridge>	m_render_js_bridge;                 //js bridge for render process
    // Include the default reference counting implementation.
    IMPLEMENT_REFCOUNTING(WebviewApp);
};

#endif  // CEF_TESTS_CEFSIMPLE_SIMPLE_APP_H_
