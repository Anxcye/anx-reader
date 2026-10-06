#pragma once
#ifndef WEBVIEW_CEF_JS_HANDLER_H_
#define WEBVIEW_CEF_JS_HANDLER_H_
#include "include/cef_base.h"
#include "include/cef_app.h"

#include <functional>
#include <memory>
#include <cstdint>


static const char kJSCallCppFunctionMessage[] = "JSCallCppFunction";		 //js call c++ message
static const char kExecuteJsCallbackMessage[] = "ExecuteJsCallback";		 //c++ call js message
static const char kEvaluateCallbackMessage[] = "EvaluateCallback";		 //js callback c++ message
static const char kFocusedNodeChangedMessage[] = "FocusedNodeChanged";		 //elements that capture focus in web pages changed message

struct JSValue {
    enum class Type { STRING, INT, BOOL, DOUBLE, ARRAY, UNKNOWN } type;

    std::string stringValue;
    int intValue;
    bool boolValue;
    double doubleValue;

    std::vector<JSValue> arrayValue;
    std::map<std::string, JSValue> objectValue;

    JSValue() : type(Type::UNKNOWN) {}
};

class CefJSBridge
{
	typedef std::map<int/* js_callback_id*/, std::pair<CefRefPtr<CefV8Context>/* context*/, std::pair<CefRefPtr<CefV8Value>/* callback*/, CefRefPtr<CefV8Value>/* rawdata*/>>> RenderCallbackMap;
	typedef std::map<int/* reqId*/, std::pair<CefRefPtr<CefFrame>/* frame*/, CefString /* callback*/>> StartRequestCallbackMap;

public:
	CefJSBridge() {};
	~CefJSBridge() {};
public:
	static int  GetNextReqID();
	bool StartRequest(int reqId, const CefString& strCmd, const CefString& strCallback, const CefString& strArgs);
    bool EvaluateCallback(const CefString& callbackId, const JSValue& result);

	bool CallCppFunction(const CefString& function_name, const CefString& params, CefRefPtr<CefV8Value> callback, CefRefPtr<CefV8Value> rawdata);
	void RemoveCallbackFuncWithFrame(CefRefPtr<CefFrame> frame);
	bool ExecuteJSCallbackFunc(int js_callback_id, bool has_error, const CefString& json_result);
private:
	uint32_t						js_callback_id_ = 0;
	RenderCallbackMap			render_callback_;
	StartRequestCallbackMap     startRequest_callback_;
};

class CefJSHandler : public CefV8Handler
{
public:
	CefJSHandler() {}
	virtual bool Execute(const CefString& name,
		CefRefPtr<CefV8Value> object,
		const CefV8ValueList& arguments,
		CefRefPtr<CefV8Value>& retval,
		CefString& exception) override;
	void AttachJSBridge(std::shared_ptr<CefJSBridge> js_bridge) { js_bridge_ = js_bridge; }
	IMPLEMENT_REFCOUNTING(CefJSHandler);
private:
	std::shared_ptr<CefJSBridge> js_bridge_;
};

#endif  // WEBVIEW_CEF_JS_HANDLER_H_
