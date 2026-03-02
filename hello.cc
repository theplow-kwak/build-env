#include <node.h>
void Method(const v8::FunctionCallbackInfo<v8::Value>& args) {}
void init(v8::Local<v8::Object> exports) {}
NODE_MODULE(NODE_GYP_MODULE_NAME, init)
