#include "webview_js_handler.h"
#include <atomic>

std::atomic_long s_nReqID {1001};

JSValue ConvertCefV8ValueToJSValue(CefRefPtr<CefV8Value> value) {
    JSValue result;

    if (value->IsString()) {
        result.type = JSValue::Type::STRING;
        result.stringValue = value->GetStringValue().ToString();
    } else if (value->IsInt()) {
        result.type = JSValue::Type::INT;
        result.intValue = value->GetIntValue();
    } else if (value->IsBool()) {
        result.type = JSValue::Type::BOOL;
        result.boolValue = value->GetBoolValue();
    } else if (value->IsDouble()) {
        result.type = JSValue::Type::DOUBLE;
        result.doubleValue = value->GetDoubleValue();
    } else if (value->IsArray()) {
        result.type = JSValue::Type::ARRAY;
        int length = value->GetArrayLength();
        for (int i = 0; i < length; ++i) {
            result.arrayValue.push_back(ConvertCefV8ValueToJSValue(value->GetValue(i)));
        }
    } else {
        result.type = JSValue::Type::UNKNOWN;
    }

    return result;
}

bool CefJSHandler::Execute(const CefString& name,
                           CefRefPtr<CefV8Value> object,
                           const CefV8ValueList& arguments,
                           CefRefPtr<CefV8Value>& retval,
                           CefString& exception)
{
    if (name == "jsCmd")
    {
        if (arguments.size() < 2) {
            exception = "Invalid arguments.";
            return true;
        }
        //the first param is function name,the last param is callback function,and allow most 2 custom params between them.
        CefString function_name = arguments[0]->GetStringValue();
        CefString params = "";
        CefRefPtr<CefV8Value> callback;
        CefRefPtr<CefV8Value> rawdata;
        if (arguments[0]->IsString() && arguments[1]->IsFunction())
        {
            callback = arguments[1];
        }
        else if (arguments[0]->IsString() && arguments[1]->IsString() && arguments[2]->IsFunction())
        {
            params = arguments[1]->GetStringValue();
            callback = arguments[2];
        }
        else if (arguments[0]->IsString() && arguments[1]->IsString() && arguments[3]->IsFunction())
        {
            params = arguments[1]->GetStringValue();
            rawdata = arguments[2];
            callback = arguments[3];
        }
        else
        {
            exception = "Invalid arguments.";
            return true;
        }

        //call c++ funtion
        if (!js_bridge_->CallCppFunction(function_name, params, callback, rawdata))
        {
            std::ostringstream strStream;
            strStream << "Failed to call function:  " << function_name.c_str() << ".";
            strStream.flush();

            exception = strStream.str();
        }

    }
    else if (name == "StartRequest")
    {
        if (arguments.size() < 5) {
            exception = "Invalid arguments.";
            return true;
        }
        // args[0]
        int reqId = (int)arguments[0]->GetIntValue();

        // args[1]
        CefString strCmd = arguments[1]->GetStringValue();

        //// args[2]
        CefString strCallback = arguments[2]->GetStringValue();

        //// args[3]
        CefString strArgs = arguments[3]->GetStringValue();

        // call c++ function
        if (!js_bridge_->StartRequest(reqId, strCmd, strCallback, strArgs))
        {
            std::ostringstream strStream;
            strStream << "Failed to call function:  " << strCmd.c_str() << ".";
            strStream.flush();

            exception = strStream.str();
        }

    }
    else if (name == "GetNextReqID")
    {
        int reqID = CefJSBridge::GetNextReqID();
        retval = CefV8Value::CreateInt(reqID);
    }
    else if (name == "EvaluateCallback") {
        CefString callbackId = arguments[0]->GetStringValue();
        CefRefPtr<CefV8Value> result = arguments[1];
        JSValue jsValue = ConvertCefV8ValueToJSValue(result);

        if (!js_bridge_->EvaluateCallback(callbackId, jsValue)) {
            std::ostringstream strStream;
            strStream << "Failed to callback:  " << callbackId.c_str() << ".";
            strStream.flush();

            exception = strStream.str();
        }
    }
    else {
        exception = "NativeHost no this fun.";
    }

    return true;
}

bool CefJSBridge::StartRequest(int reqId,
                               const CefString& strCmd,
                               const CefString& strCallback,
                               const CefString& strArgs)
{
    if (reqId > 0) {
        reqId *= -1;
    }

    auto it = startRequest_callback_.find(reqId);
    if (it == startRequest_callback_.cend())
    {
        CefRefPtr<CefV8Context> context = CefV8Context::GetCurrentContext();
        if (context)
        {
            CefRefPtr<CefFrame> frame = context->GetFrame();
            if (frame)
            {
                CefRefPtr<CefProcessMessage> message = CefProcessMessage::Create(kJSCallCppFunctionMessage);
                message->GetArgumentList()->SetString(0, strCmd);
                message->GetArgumentList()->SetString(1, strArgs);
                message->GetArgumentList()->SetInt(2, reqId);
                startRequest_callback_.emplace(reqId, std::make_pair(frame, strCallback));
                frame->SendProcessMessage(PID_BROWSER, message);
                return true;
            }
        }
    }

    return false;
}

bool CefJSBridge::EvaluateCallback(const CefString& callbackId, const JSValue& result) {
    CefRefPtr<CefV8Context> context = CefV8Context::GetCurrentContext();
    if (context) {
        CefRefPtr<CefFrame> frame = context->GetFrame();
        if (frame) {
            CefRefPtr<CefProcessMessage> message = CefProcessMessage::Create(
                                                                             kEvaluateCallbackMessage);
            CefRefPtr<CefListValue> args = message->GetArgumentList();

            args->SetString(0, callbackId);

            switch (result.type) {
                case JSValue::Type::STRING:
                    args->SetString(1, result.stringValue);
                    break;
                case JSValue::Type::INT:
                    args->SetInt(1, result.intValue);
                    break;
                case JSValue::Type::BOOL:
                    args->SetBool(1, result.boolValue);
                    break;
                case JSValue::Type::DOUBLE:
                    args->SetDouble(1, result.doubleValue);
                    break;
                case JSValue::Type::ARRAY: {
                    CefRefPtr<CefListValue> arrayList = CefListValue::Create();
                    for (size_t i = 0; i < result.arrayValue.size(); ++i) {
                        const JSValue &element = result.arrayValue[i];
                        switch (element.type) {
                            case JSValue::Type::STRING:
                                arrayList->SetString(i, element.stringValue);
                                break;
                            case JSValue::Type::INT:
                                arrayList->SetInt(i, element.intValue);
                                break;
                            case JSValue::Type::BOOL:
                                arrayList->SetBool(i, element.boolValue);
                                break;
                            case JSValue::Type::DOUBLE:
                                arrayList->SetDouble(i, element.doubleValue);
                                break;
                            default:
                                break;
                        }
                    }
                    args->SetList(1, arrayList);
                    break;
                }
                default:
                    // For avoiding values like
                    // error: enumeration value 'UNKNOWN' not handled in switch [-Werror,-Wswitch]
                    break;
            }

            // 메시지 전송
            frame->SendProcessMessage(PID_BROWSER, message);
            return true;
        }
    }
    return false;
}

int CefJSBridge::GetNextReqID()
{
    long nRet = ++s_nReqID;
    if (nRet < 0)
    {
        nRet = 0;
    }

    while (nRet == 0)
    {
        nRet = ++s_nReqID;
    }

    return nRet;
}

bool CefJSBridge::CallCppFunction(const CefString& function_name,
                                  const CefString& params,
                                  CefRefPtr<CefV8Value> callback,
                                  CefRefPtr<CefV8Value> rawdata)
{
    auto it = render_callback_.find(js_callback_id_);
    if (it == render_callback_.cend())
    {
        CefRefPtr<CefV8Context> context = CefV8Context::GetCurrentContext();
        if (context)
        {
            CefRefPtr<CefFrame> frame = context->GetFrame();
            if (frame)
            {
                CefRefPtr<CefProcessMessage> message = CefProcessMessage::Create(kJSCallCppFunctionMessage);
                message->GetArgumentList()->SetString(0, function_name);
                message->GetArgumentList()->SetString(1, params);
                message->GetArgumentList()->SetInt(2, js_callback_id_);
                render_callback_.emplace(js_callback_id_++, std::make_pair(context, std::make_pair(callback, rawdata)));
                frame->SendProcessMessage(PID_BROWSER, message);
                return true;
            }
        }
    }

    return false;
}


void CefJSBridge::RemoveCallbackFuncWithFrame(CefRefPtr<CefFrame> frame)
{
    if (!render_callback_.empty()) {
        for (auto it = render_callback_.begin(); it != render_callback_.end();) {
            if (it->second.first->IsSame(frame->GetV8Context())) {
                it = render_callback_.erase(it);
            }
            else {
                ++it;
            }
        }
    }

    if (!startRequest_callback_.empty()) {
        for (auto it = startRequest_callback_.begin(); it != startRequest_callback_.end();) {
            if (it->second.first->GetIdentifier() == frame->GetIdentifier()) {
                it = startRequest_callback_.erase(it);
            }
            else {
                ++it;
            }
        }
    }
}

bool CefJSBridge::ExecuteJSCallbackFunc(int callbackId, bool error, const CefString& result)
{
    if (callbackId < 0)
    {
        auto it = startRequest_callback_.find(callbackId);
        if (it != startRequest_callback_.cend())
        {
            auto frame = it->second.first;
            CefString callback = it->second.second;

            if (callback != "" && frame.get())
            {
                std::ostringstream strStream;
                strStream <<"window['" << callback.ToString() << "'](" << callbackId * -1 << ", " << result.ToString() << ");";
                strStream.flush();

                CefString strCode = strStream.str();
                frame->ExecuteJavaScript(strCode, frame->GetURL(), 0);
                startRequest_callback_.erase(callbackId);

                return true;
            }
            else
            {
                return false;
            }
        }
    }
    else
    {
        auto it = render_callback_.find(callbackId);
        if (it != render_callback_.cend())
        {
            auto context = it->second.first;
            auto callback = it->second.second.first;
            auto rawdata = it->second.second.second;
            if (context.get() && callback.get())
            {
                context->Enter();

                CefV8ValueList arguments;

                //the first param marks whether the function execution result was successful
                arguments.push_back(CefV8Value::CreateBool(error));

                // the second prarm take the return data
                arguments.push_back(CefV8Value::CreateString(result));
                if (rawdata.get()) {
                    arguments.push_back(rawdata);
                }

                // call js function
                CefRefPtr<CefV8Value> retval = callback->ExecuteFunction(nullptr, arguments);
                context->Exit();
                render_callback_.erase(callbackId);

                return true;
            }
            else
            {
                return false;
            }
        }

    }

    return false;
}
