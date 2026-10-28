#include "webview_value.h"
#include <memory>
#include <string.h>
#include <inttypes.h>
#include <cstdlib>

#if defined(_MSC_VER)
#pragma warning(disable: 4996)
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
#endif

#define return_val_if_fail(p, ret) if(!(p)) return (ret)
#define return_if_fail(p) if(!(p)) return

using std::malloc;
using std::free;

struct webview_value{
  WValueType type;
  int ref_count;
};

typedef struct {
  WValue parent;
  bool value;
} WValueBool;

typedef struct {
  WValue parent;
  int64_t value;
} WValueInt;

typedef struct {
  WValue parent;
  float value;
} WValueFloat;

typedef struct {
  WValue parent;
  double value;
} WValueDouble;

typedef struct {
  WValue parent;
  char* value;
} WValueString;

typedef struct {
  WValue parent;
  uint8_t* values;
  size_t values_length;
} WValueUint8List;

typedef struct {
  WValue parent;
  int32_t* values;
  size_t values_length;
} WValueInt32List;

typedef struct {
  WValue parent;
  int64_t* values;
  size_t values_length;
} WValueInt64List;

typedef struct {
  WValue parent;
  float* values;
  size_t values_length;
} WValueFloatList;

typedef struct {
  WValue parent;
  double* values;
  size_t values_length;
} WValueDoubleList;

struct WPtrArray {
  void **pdata;
  size_t len;
  size_t capacity;
  void (*free_func)(void*);
};

WPtrArray* webview_ptr_array_new_with_free_func(void (*free_func)(void*)) {
    WPtrArray* array = (WPtrArray*)malloc(sizeof(WPtrArray));
    array->pdata = NULL;
    array->len = 0;
    array->capacity = 0;
    array->free_func = free_func;
    return array;
}

void webview_ptr_array_free(WPtrArray* array) {
    if (array->free_func) {
        for (size_t i = 0; i < array->len; i++) {
            array->free_func(array->pdata[i]);
        }
    }
    free(array->pdata);
    free(array);
}

void webview_ptr_array_unref(WPtrArray* array) {
    if (array) {
        webview_ptr_array_free(array);
    }
}

void webview_ptr_array_add(WPtrArray* array, void* data) {
    if (array->len == array->capacity) {
        size_t new_capacity = array->capacity == 0 ? 16 : array->capacity * 2;
        void** new_pdata = (void**)realloc(array->pdata, new_capacity * sizeof(void*));
        if (new_pdata) {
            array->pdata = new_pdata;
            array->capacity = new_capacity;
        } else {
            return;
        }
    }
    array->pdata[array->len++] = data;
}

void* webview_ptr_array_index(WPtrArray* array, size_t index) {
    if (index >= array->len) {
        return NULL;
    }
    return array->pdata[index];
}

typedef struct {
  WValue parent;
  WPtrArray* values;
} WValueList;

typedef struct {
  WValue parent;
  WPtrArray* keys;
  WPtrArray* values;
} WValueMap;

static WValue* webview_value_new(WValueType type, size_t size) {
  WValue* self = static_cast<WValue*>(malloc(size));
  self->type = type;
  self->ref_count = 1;
  return self;
}

static ssize_t webview_value_lookup_index(WValue* self, WValue* key) {
  return_val_if_fail(self->type == Webview_Value_Type_Map, size_t(-1));

  for (size_t i = 0; i < webview_value_get_len(self); i++) {
    WValue* k = webview_value_get_key(self, i);
    if (webview_value_equals(k, key)) {
      return i;
    }
  }
  return -1;
}

// Helper function to match GDestroyNotify type.
static void webview_value_destroy(void *value) {
  webview_value_unref(static_cast<WValue*>(value));
}

WValue* webview_value_new_null() {
  return webview_value_new(Webview_Value_Type_Null, sizeof(WValue));
}

WValue* webview_value_new_bool(bool value) {
  WValueBool* self = reinterpret_cast<WValueBool*>(
      webview_value_new(Webview_Value_Type_Bool, sizeof(WValueBool)));
  self->value = value ? true : false;
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_int(int64_t value) {
  WValueInt* self = reinterpret_cast<WValueInt*>(
      webview_value_new(Webview_Value_Type_Int, sizeof(WValueInt)));
  self->value = value;
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_float(float value) {
  WValueFloat* self = reinterpret_cast<WValueFloat*>(
      webview_value_new(Webview_Value_Type_Float, sizeof(WValueFloat)));
  self->value = value;
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_double(double value) {
  WValueDouble* self = reinterpret_cast<WValueDouble*>(
      webview_value_new(Webview_Value_Type_Double, sizeof(WValueDouble)));
  self->value = value;
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_string(const char* value) {
  WValueString* self = reinterpret_cast<WValueString*>(
      webview_value_new(Webview_Value_Type_String, sizeof(WValueString)));
  self->value = strdup(value);
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_string_len(const char* value,
                                                   size_t value_length) {
  WValueString* self = reinterpret_cast<WValueString*>(
      webview_value_new(Webview_Value_Type_String, sizeof(WValueString)));
  if (value_length == 0) {
    self->value = strdup("");
  } else {
    self->value = new char[value_length + 1];
    strncpy(self->value, value, value_length);
    self->value[value_length] = '\0';
  }
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_uint8_list(const uint8_t* data,
                                                 size_t data_length) {
  WValueUint8List* self = reinterpret_cast<WValueUint8List*>(
      webview_value_new(Webview_Value_Type_Uint8_List, sizeof(WValueUint8List)));
  self->values_length = data_length;
  self->values = static_cast<uint8_t*>(malloc(sizeof(uint8_t) * data_length));
  memcpy(self->values, data, sizeof(uint8_t) * data_length);
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_int32_list(const int32_t* data,
                                                 size_t data_length) {
  WValueInt32List* self = reinterpret_cast<WValueInt32List*>(
      webview_value_new(Webview_Value_Type_Int32_List, sizeof(WValueInt32List)));
  self->values_length = data_length;
  self->values = static_cast<int32_t*>(malloc(sizeof(int32_t) * data_length));
  memcpy(self->values, data, sizeof(int32_t) * data_length);
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_int64_list(const int64_t* data,
                                                 size_t data_length) {
  WValueInt64List* self = reinterpret_cast<WValueInt64List*>(
      webview_value_new(Webview_Value_Type_Int64_List, sizeof(WValueInt64List)));
  self->values_length = data_length;
  self->values = static_cast<int64_t*>(malloc(sizeof(int64_t) * data_length));
  memcpy(self->values, data, sizeof(int64_t) * data_length);
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_float_list(const float* data,
                                                   size_t data_length) {
  WValueFloatList* self = reinterpret_cast<WValueFloatList*>(
      webview_value_new(Webview_Value_Type_Float_List, sizeof(WValueFloatList)));
  self->values_length = data_length;
  self->values = static_cast<float*>(malloc(sizeof(float) * data_length));
  memcpy(self->values, data, sizeof(float) * data_length);
  return reinterpret_cast<WValue*>(self);
}

 WValue* webview_value_new_double_list(const double* data,
                                                 size_t data_length) {
  WValueDoubleList* self = reinterpret_cast<WValueDoubleList*>(
      webview_value_new(Webview_Value_Type_Double_List, sizeof(WValueDoubleList)));
  self->values_length = data_length;
  self->values = static_cast<double*>(malloc(sizeof(double) * data_length));
  memcpy(self->values, data, sizeof(double) * data_length);
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_list() {
  WValueList* self = reinterpret_cast<WValueList*>(
      webview_value_new(Webview_Value_Type_List, sizeof(WValueList)));
  self->values = webview_ptr_array_new_with_free_func(webview_value_destroy);
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_new_map() {
  WValueMap* self = reinterpret_cast<WValueMap*>(
      webview_value_new(Webview_Value_Type_Map, sizeof(WValueMap)));
  self->keys = webview_ptr_array_new_with_free_func(webview_value_destroy);
  self->values = webview_ptr_array_new_with_free_func(webview_value_destroy);
  return reinterpret_cast<WValue*>(self);
}

WValue* webview_value_ref(WValue* self) {
  return_val_if_fail(self != nullptr, nullptr);
  self->ref_count++;
  return self;
}

void webview_value_unref(WValue *self)
{
  return_if_fail(self != nullptr);
  return_if_fail(self->ref_count > 0);
  self->ref_count--;
  if (self->ref_count != 0)
  {
    return;
  }

  switch (self->type)
  {
  case Webview_Value_Type_String:
  {
    WValueString *v = reinterpret_cast<WValueString *>(self);
    free(v->value);
    break;
  }
  case Webview_Value_Type_Uint8_List:
  {
    WValueUint8List *v = reinterpret_cast<WValueUint8List *>(self);
    free(v->values);
    break;
  }
  case Webview_Value_Type_Int32_List:
  {
    WValueInt32List *v = reinterpret_cast<WValueInt32List *>(self);
    free(v->values);
    break;
  }
  case Webview_Value_Type_Int64_List:
  {
    WValueInt64List *v = reinterpret_cast<WValueInt64List *>(self);
    free(v->values);
    break;
  }
  case Webview_Value_Type_Float_List:
  {
    WValueFloatList *v = reinterpret_cast<WValueFloatList *>(self);
    free(v->values);
    break;
  }
  case Webview_Value_Type_Double_List:
  {
    WValueDoubleList *v = reinterpret_cast<WValueDoubleList *>(self);
    free(v->values);
    break;
  }
  case Webview_Value_Type_List:
  {
    WValueList *v = reinterpret_cast<WValueList *>(self);
    webview_ptr_array_unref(v->values);
    break;
  }
  case Webview_Value_Type_Map:
  {
    WValueMap *v = reinterpret_cast<WValueMap *>(self);
    webview_ptr_array_unref(v->keys);
    webview_ptr_array_unref(v->values);
    break;
  }
  case Webview_Value_Type_Null:
  case Webview_Value_Type_Bool:
  case Webview_Value_Type_Int:
  case Webview_Value_Type_Float:
  case Webview_Value_Type_Double:
    break;
  }
  free(self);
}

WValueType webview_value_get_type(WValue* self) {
  return_val_if_fail(self != nullptr, Webview_Value_Type_Null);
  return self->type;
}

bool webview_value_equals(WValue *a, WValue *b)
{
  return_val_if_fail(a != nullptr, false);
  return_val_if_fail(b != nullptr, false);

  if (a->type != b->type)
  {
      return false;
  }

  switch (a->type)
  {
  case Webview_Value_Type_Null:
      return true;
  case Webview_Value_Type_Bool:
      return webview_value_get_bool(a) == webview_value_get_bool(b);
  case Webview_Value_Type_Int:
      return webview_value_get_int(a) == webview_value_get_int(b);
  case Webview_Value_Type_Float:
      return webview_value_get_float(a) == webview_value_get_float(b);
  case Webview_Value_Type_Double:
      return webview_value_get_double(a) == webview_value_get_double(b);
  case Webview_Value_Type_String:
  {
      WValueString *a_ = reinterpret_cast<WValueString *>(a);
      WValueString *b_ = reinterpret_cast<WValueString *>(b);
      return strcmp(a_->value, b_->value) == 0;
  }
  case Webview_Value_Type_Uint8_List:
  {
      if (webview_value_get_len(a) != webview_value_get_len(b))
      {
      return false;
      }
      const uint8_t *values_a = webview_value_get_uint8_list(a);
      const uint8_t *values_b = webview_value_get_uint8_list(b);
      for (size_t i = 0; i < webview_value_get_len(a); i++)
      {
      if (values_a[i] != values_b[i])
      {
          return false;
      }
      }
      return true;
  }
  case Webview_Value_Type_Int32_List:
  {
      if (webview_value_get_len(a) != webview_value_get_len(b))
      {
      return false;
      }
      const int32_t *values_a = webview_value_get_int32_list(a);
      const int32_t *values_b = webview_value_get_int32_list(b);
      for (size_t i = 0; i < webview_value_get_len(a); i++)
      {
      if (values_a[i] != values_b[i])
      {
          return false;
      }
      }
      return true;
  }
  case Webview_Value_Type_Int64_List:
  {
      if (webview_value_get_len(a) != webview_value_get_len(b))
      {
      return false;
      }
      const int64_t *values_a = webview_value_get_int64_list(a);
      const int64_t *values_b = webview_value_get_int64_list(b);
      for (size_t i = 0; i < webview_value_get_len(a); i++)
      {
      if (values_a[i] != values_b[i])
      {
          return false;
      }
      }
      return true;
  }
  case Webview_Value_Type_Float_List:
  {
      if (webview_value_get_len(a) != webview_value_get_len(b))
      {
      return false;
      }
      const float *values_a = webview_value_get_float_list(a);
      const float *values_b = webview_value_get_float_list(b);
      for (size_t i = 0; i < webview_value_get_len(a); i++)
      {
      if (values_a[i] != values_b[i])
      {
          return false;
      }
      }
      return true;
  }
  case Webview_Value_Type_Double_List:
  {
      if (webview_value_get_len(a) != webview_value_get_len(b))
      {
      return false;
      }
      const double *values_a = webview_value_get_double_list(a);
      const double *values_b = webview_value_get_double_list(b);
      for (size_t i = 0; i < webview_value_get_len(a); i++)
      {
      if (values_a[i] != values_b[i])
      {
          return false;
      }
      }
      return true;
  }
  case Webview_Value_Type_List:
  {
      if (webview_value_get_len(a) != webview_value_get_len(b))
      {
      return false;
      }
      for (size_t i = 0; i < webview_value_get_len(a); i++)
      {
      if (!webview_value_equals(webview_value_get_list_value(a, i),
                                webview_value_get_list_value(b, i)))
      {
          return false;
      }
      }
      return true;
  }
  case Webview_Value_Type_Map:
  {
      if (webview_value_get_len(a) != webview_value_get_len(b))
      {
      return false;
      }
      for (size_t i = 0; i < webview_value_get_len(a); i++)
      {
      WValue *key = webview_value_get_key(a, i);
      WValue *value_b = webview_value_get_by_key(b, key);
      if (value_b == nullptr)
      {
          return false;
      }
      WValue *value_a = webview_value_get_key(a, i);
      if (!webview_value_equals(value_a, value_b))
      {
          return false;
      }
      }
      return true;
  }
  }
  return false;
}

void webview_value_append_take(WValue* self, WValue* value) {
    return_if_fail(self != nullptr);
    return_if_fail(self->type == Webview_Value_Type_List);
    return_if_fail(value != nullptr);


    WValueList* v = reinterpret_cast<WValueList*>(self);
    webview_ptr_array_add(v->values, value);
}

void webview_value_append(WValue* self, WValue* value) {
  return_if_fail(self != nullptr);
  return_if_fail(self->type == Webview_Value_Type_List);
  return_if_fail(value != nullptr);

  webview_value_append_take(self, webview_value_ref(value));
}

void webview_value_set_take(WValue* self, WValue* key, WValue* value)
{
    return_if_fail(self != nullptr);
    return_if_fail(self->type == Webview_Value_Type_Map);
    return_if_fail(key != nullptr);
    return_if_fail(value != nullptr);

    WValueMap* v = reinterpret_cast<WValueMap*>(self);
    ssize_t index = webview_value_lookup_index(self, key);
    if (index < 0) {
        webview_ptr_array_add(v->keys, key);
        webview_ptr_array_add(v->values, value);
    }
    else {
        webview_value_destroy(v->keys->pdata[index]);
        v->keys->pdata[index] = key;
        webview_value_destroy(v->values->pdata[index]);
        v->values->pdata[index] = value;
    }
}

 void webview_value_set(WValue* self, WValue* key, WValue* value) {
  return_if_fail(self != nullptr);
  return_if_fail(self->type == Webview_Value_Type_Map);
  return_if_fail(key != nullptr);
  return_if_fail(value != nullptr);

  webview_value_set_take(self, webview_value_ref(key), webview_value_ref(value));
 }

void webview_value_set_string(WValue* self,const char* key,WValue* value) {
  return_if_fail(self != nullptr);
  return_if_fail(self->type == Webview_Value_Type_Map);
  return_if_fail(key != nullptr);
  return_if_fail(value != nullptr);

  webview_value_set_take(self, webview_value_new_string(key), webview_value_ref(value));
}

bool webview_value_get_bool(WValue* self) {
  return_val_if_fail(self != nullptr, false);
  return_val_if_fail(self->type == Webview_Value_Type_Bool, false);
  WValueBool* v = reinterpret_cast<WValueBool*>(self);
  return v->value;
}

int64_t webview_value_get_int(WValue* self) {
  return_val_if_fail(self != nullptr, 0);
  return_val_if_fail(self->type == Webview_Value_Type_Int, 0);
  WValueInt* v = reinterpret_cast<WValueInt*>(self);
  return v->value;
}

float webview_value_get_float(WValue* self) {
  return_val_if_fail(self != nullptr, 0.0);
  return_val_if_fail(self->type == Webview_Value_Type_Float, 0.0);
  WValueFloat* v = reinterpret_cast<WValueFloat*>(self);
  return v->value;
}

double webview_value_get_double(WValue* self) {
  return_val_if_fail(self != nullptr, 0.0);
  return_val_if_fail(self->type == Webview_Value_Type_Double, 0.0);
  WValueDouble* v = reinterpret_cast<WValueDouble*>(self);
  return v->value;
}

const char* webview_value_get_string(WValue* self) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_String, nullptr);
  WValueString* v = reinterpret_cast<WValueString*>(self);
  return v->value;
}

const uint8_t* webview_value_get_uint8_list(WValue* self) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Uint8_List, nullptr);
  WValueUint8List* v = reinterpret_cast<WValueUint8List*>(self);
  return v->values;
}

const int32_t* webview_value_get_int32_list(WValue* self) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Int32_List, nullptr);
  WValueInt32List* v = reinterpret_cast<WValueInt32List*>(self);
  return v->values;
}

const int64_t* webview_value_get_int64_list(WValue* self) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Int64_List, nullptr);
  WValueInt64List* v = reinterpret_cast<WValueInt64List*>(self);
  return v->values;
}

const float* webview_value_get_float_list(WValue* self) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Float_List, nullptr);
  WValueFloatList* v = reinterpret_cast<WValueFloatList*>(self);
  return v->values;
}

const double* webview_value_get_double_list(WValue* self) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Double_List, nullptr);
  WValueDoubleList* v = reinterpret_cast<WValueDoubleList*>(self);
  return v->values;
}

size_t webview_value_get_len(WValue *self)
{
  return_val_if_fail(self != nullptr, 0);
  return_val_if_fail(self->type == Webview_Value_Type_Uint8_List ||
                         self->type == Webview_Value_Type_Int32_List ||
                         self->type == Webview_Value_Type_Int64_List ||
                         self->type == Webview_Value_Type_Float_List ||
                         self->type == Webview_Value_Type_Double_List ||
                         self->type == Webview_Value_Type_List ||
                         self->type == Webview_Value_Type_Map,
                     0);

  switch (self->type)
  {
  case Webview_Value_Type_Uint8_List:
  {
    WValueUint8List *v = reinterpret_cast<WValueUint8List *>(self);
    return v->values_length;
  }
  case Webview_Value_Type_Int32_List:
  {
    WValueInt32List *v = reinterpret_cast<WValueInt32List *>(self);
    return v->values_length;
  }
  case Webview_Value_Type_Int64_List:
  {
    WValueInt64List *v = reinterpret_cast<WValueInt64List *>(self);
    return v->values_length;
  }
  case Webview_Value_Type_Float_List:
  {
    WValueFloatList *v = reinterpret_cast<WValueFloatList *>(self);
    return v->values_length;
  }
  case Webview_Value_Type_Double_List:
  {
    WValueDoubleList *v = reinterpret_cast<WValueDoubleList *>(self);
    return v->values_length;
  }
  case Webview_Value_Type_List:
  {
    WValueList *v = reinterpret_cast<WValueList *>(self);
    return v->values->len;
  }
  case Webview_Value_Type_Map:
  {
    WValueMap *v = reinterpret_cast<WValueMap *>(self);
    return v->keys->len;
  }
  case Webview_Value_Type_Null:
  case Webview_Value_Type_Bool:
  case Webview_Value_Type_Int:
  case Webview_Value_Type_Float:
  case Webview_Value_Type_Double:
  case Webview_Value_Type_String:
    return 0;
  }

  return 0;
}

WValue* webview_value_get_list_value(WValue* self, size_t index) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_List, nullptr);

  WValueList* v = reinterpret_cast<WValueList*>(self);
  return static_cast<WValue*>(webview_ptr_array_index(v->values, index));
}

WValue* webview_value_get_key(WValue* value, size_t index)
{
  return_val_if_fail(value != nullptr, nullptr);
  return_val_if_fail(value->type == Webview_Value_Type_Map, nullptr);

  WValueMap* v = reinterpret_cast<WValueMap*>(value);
  return static_cast<WValue*>(webview_ptr_array_index(v->keys, index));
}

WValue* webview_value_get_value(WValue* value, size_t index)
{
    return_val_if_fail(value != nullptr, nullptr);
    return_val_if_fail(value->type == Webview_Value_Type_Map, nullptr);

    WValueMap* v = reinterpret_cast<WValueMap*>(value);
    return static_cast<WValue*>(webview_ptr_array_index(v->values, index));
}

WValue* webview_value_get_map_key(WValue* self, size_t index) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Map, nullptr);

  WValueMap* v = reinterpret_cast<WValueMap*>(self);
  return static_cast<WValue*>(webview_ptr_array_index(v->keys, index));
}

WValue* webview_value_get_map_value(WValue* self, size_t index) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Map, nullptr);

  WValueMap* v = reinterpret_cast<WValueMap*>(self);
  return static_cast<WValue*>(webview_ptr_array_index(v->values, index));
}

WValue* webview_value_get_by_key(WValue* self, WValue* key) {
  return_val_if_fail(self != nullptr, nullptr);
  return_val_if_fail(self->type == Webview_Value_Type_Map, nullptr);

  ssize_t index = webview_value_lookup_index(self, key);
  if (index < 0) {
    return nullptr;
  }
  return webview_value_get_map_value(self, index);
}

WValue* webview_value_get_by_string(WValue* self, const char* key) {
  return_val_if_fail(self != nullptr, nullptr);
  WValue* string_key = webview_value_new_string(key);
  WValue* value = webview_value_get_by_key(self, string_key);
  // Explicit unref used because the g_autoptr is triggering a false positive
  // with clang-tidy.
  webview_value_unref(string_key);
  return value;
}

char* webview_value_to_string(WValue* value) {
  return_val_if_fail(value != nullptr, nullptr);
  switch (value->type)
  {
  case Webview_Value_Type_Null:
    return strdup("null");
  case Webview_Value_Type_Bool:
    return strdup(webview_value_get_bool(value) ? "true" : "false");
  case Webview_Value_Type_String:
    return strdup(webview_value_get_string(value));
  case Webview_Value_Type_Int:
  {
    char buf[32];
    snprintf(buf, sizeof(buf), "%" PRId64, webview_value_get_int(value));
    return strdup(buf);
  }
  case Webview_Value_Type_Float:
  {
    char buf[32];
    snprintf(buf, sizeof(buf), "%f", webview_value_get_float(value));
    return strdup(buf);
  }
  case Webview_Value_Type_Double:
  {
    char buf[32];
    snprintf(buf, sizeof(buf), "%f", webview_value_get_double(value));
    return strdup(buf);
  }
  case Webview_Value_Type_Uint8_List:
  {
    char *str = strdup("[");
    size_t len = webview_value_get_len(value);
    for(size_t i = 0; i < len; i++){
      uint8_t item = webview_value_get_uint8_list(value)[i];
      char buf[32];
      snprintf(buf, sizeof(buf), "%d", item);
      strcat(str, buf);
      if(i != len - 1){
        strcat(str, ",");
      }
    }
    strcat(str, "]");
    return str;
  }
  case Webview_Value_Type_Int32_List:
  {
    char *str = strdup("[");
    size_t len = webview_value_get_len(value);
    for(size_t i = 0; i < len; i++){
      int32_t item = webview_value_get_int32_list(value)[i];
      char buf[32];
      snprintf(buf, sizeof(buf), "%d", item);
      strcat(str, buf);
      if(i != len - 1){
        strcat(str, ",");
      }
    }
    strcat(str, "]");
    return str;
  }
  case Webview_Value_Type_Int64_List:
  {
    char *str = strdup("[");
    size_t len = webview_value_get_len(value);
    for(size_t i = 0; i < len; i++){
      int64_t item = webview_value_get_int64_list(value)[i];
      char buf[32];
      snprintf(buf, sizeof(buf), "%" PRId64, item);
      strcat(str, buf);
      if(i != len - 1){
        strcat(str, ",");
      }
    }
    strcat(str, "]");
    return str;
  }
  case Webview_Value_Type_Float_List:
  {
    char *str = strdup("[");
    size_t len = webview_value_get_len(value);
    for(size_t i = 0; i < len; i++){
      float item = webview_value_get_float_list(value)[i];
      char buf[32];
      snprintf(buf, sizeof(buf), "%f", item);
      strcat(str, buf);
      if(i != len - 1){
        strcat(str, ",");
      }
    }
    strcat(str, "]");
    return str;
  }
  case Webview_Value_Type_Double_List:
  {
    char *str = strdup("[");
    size_t len = webview_value_get_len(value);
    for(size_t i = 0; i < len; i++){
      double item = webview_value_get_double_list(value)[i];
      char buf[32];
      snprintf(buf, sizeof(buf), "%f", item);
      strcat(str, buf);
      if(i != len - 1){
        strcat(str, ",");
      }
    }
    strcat(str, "]");
    return str;
  }
  case Webview_Value_Type_List:
  {
    char *str = strdup("[");
    size_t len = webview_value_get_len(value);
    for(size_t i = 0; i < len; i++){
      WValue *item = webview_value_get_list_value(value, i);
      char *item_str = webview_value_to_string(item);
      strcat(str, item_str);
      free(item_str);
      if(i != len - 1){
        strcat(str, ",");
      }
    }
    strcat(str, "]");
    return str;
  }
  case Webview_Value_Type_Map:
  {
    char *str = strdup("{");
    size_t len = webview_value_get_len(value);
    for(size_t i = 0; i < len; i++){
      WValue *key = webview_value_get_map_key(value, i);
      WValue *item = webview_value_get_map_value(value, i);
      char *key_str = webview_value_to_string(key);
      char *item_str = webview_value_to_string(item);
      strcat(str, key_str);
      strcat(str, ":");
      strcat(str, item_str);
      free(key_str);
      free(item_str);
      if(i != len - 1){
        strcat(str, ",");
      }
    }
    strcat(str, "}");
    return str;
  }
  default:
    return strdup("<unknown type>");
  }
}
