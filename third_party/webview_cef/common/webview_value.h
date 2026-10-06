#ifndef WEBVIEW_CEF_VALUE_H_
#define WEBVIEW_CEF_VALUE_H_

#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief The type of a value.
 * 
 * the values are represented as a follows:
 * 
 * 
 */

typedef struct webview_value WValue;

typedef enum {
    Webview_Value_Type_Null,
    Webview_Value_Type_Bool,
    Webview_Value_Type_Int,
    Webview_Value_Type_Float,
    Webview_Value_Type_Double,
    Webview_Value_Type_String,
    Webview_Value_Type_Uint8_List,
    Webview_Value_Type_Int32_List,
    Webview_Value_Type_Int64_List,
    Webview_Value_Type_Float_List,
    Webview_Value_Type_Double_List,
    Webview_Value_Type_List,
    Webview_Value_Type_Map,
}WValueType;

WValue* webview_value_new_null();
WValue* webview_value_new_bool(bool value);
WValue* webview_value_new_int(int64_t value);
WValue* webview_value_new_float(float value);
WValue* webview_value_new_double(double value);
WValue* webview_value_new_string(const char* value);
WValue* webview_value_new_string_len(const char* value, size_t len);
WValue* webview_value_new_uint8_list(const uint8_t* value, size_t len);
WValue* webview_value_new_int32_list(const int32_t* value, size_t len);
WValue* webview_value_new_int64_list(const int64_t* value, size_t len);
WValue* webview_value_new_float_list(const float* value, size_t len);
WValue* webview_value_new_double_list(const double* value, size_t len);
WValue* webview_value_new_list();
WValue* webview_value_new_map();
WValue* webview_value_ref(WValue* value);
void webview_value_unref(WValue* value);
WValueType webview_value_get_type(WValue* value);
bool webview_value_equals(WValue* value1, WValue* value2);
void webview_value_append(WValue* parent, WValue* child);
void webview_value_set(WValue* parent, WValue* key, WValue* child);
void webview_value_set_string(WValue* parent, const char* key, WValue* child);
bool webview_value_get_bool(WValue* value);
int64_t webview_value_get_int(WValue* value);
float webview_value_get_float(WValue* value);
double webview_value_get_double(WValue* value);
const char* webview_value_get_string(WValue* value);
size_t webview_value_get_len(WValue* value);
const uint8_t* webview_value_get_uint8_list(WValue* value);
const int32_t* webview_value_get_int32_list(WValue* value);
const int64_t* webview_value_get_int64_list(WValue* value);
const float* webview_value_get_float_list(WValue* value);
const double* webview_value_get_double_list(WValue* value);
WValue* webview_value_get_list_value(WValue* value, size_t index);
WValue* webview_value_get_key(WValue* value, size_t index);
WValue* webview_value_get_value(WValue* value, size_t index);
WValue* webview_value_get_by_key(WValue* value, WValue* key);
WValue* webview_value_get_by_string(WValue* value, const char* key);
char* webview_value_to_string(WValue* value);

#ifdef __cplusplus
}
#endif
#endif //WEBVIEW_CEF_VALUE_H_