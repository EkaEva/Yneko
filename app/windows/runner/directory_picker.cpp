#include "directory_picker.h"

#include <shobjidl.h>

namespace {

class ScopedComInitializer {
 public:
  ScopedComInitializer() : result_(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)) {}

  ~ScopedComInitializer() {
    if (SUCCEEDED(result_)) {
      CoUninitialize();
    }
  }

  HRESULT result() const { return result_; }

 private:
  HRESULT result_;
};

template <typename T>
class ScopedComPtr {
 public:
  ScopedComPtr() = default;
  ~ScopedComPtr() { reset(); }

  T** put() { return &ptr_; }
  T* get() const { return ptr_; }
  T* operator->() const { return ptr_; }

  void reset() {
    if (ptr_) {
      ptr_->Release();
      ptr_ = nullptr;
    }
  }

 private:
  T* ptr_ = nullptr;
};

class ScopedCoTaskMemString {
 public:
  ~ScopedCoTaskMemString() {
    if (value_) {
      CoTaskMemFree(value_);
    }
  }

  PWSTR* put() { return &value_; }
  PWSTR get() const { return value_; }

 private:
  PWSTR value_ = nullptr;
};

void SetInitialFolder(IFileOpenDialog* dialog, const std::wstring& initial_path) {
  if (initial_path.empty()) {
    return;
  }

  ScopedComPtr<IShellItem> folder;
  if (SUCCEEDED(SHCreateItemFromParsingName(
          initial_path.c_str(), nullptr, IID_PPV_ARGS(folder.put())))) {
    dialog->SetFolder(folder.get());
  }
}

}  // namespace

std::optional<std::wstring> SelectDirectory(HWND owner,
                                            const std::wstring& initial_path) {
  ScopedComInitializer com;
  if (FAILED(com.result()) && com.result() != RPC_E_CHANGED_MODE) {
    return std::nullopt;
  }

  ScopedComPtr<IFileOpenDialog> dialog;
  HRESULT result = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                    CLSCTX_INPROC_SERVER,
                                    IID_PPV_ARGS(dialog.put()));
  if (FAILED(result)) {
    return std::nullopt;
  }

  DWORD options = 0;
  if (SUCCEEDED(dialog->GetOptions(&options))) {
    dialog->SetOptions(options | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM |
                       FOS_PATHMUSTEXIST);
  }
  dialog->SetTitle(L"选择下载路径");
  SetInitialFolder(dialog.get(), initial_path);

  result = dialog->Show(owner);
  if (result == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
    return std::nullopt;
  }
  if (FAILED(result)) {
    return std::nullopt;
  }

  ScopedComPtr<IShellItem> item;
  result = dialog->GetResult(item.put());
  if (FAILED(result)) {
    return std::nullopt;
  }

  ScopedCoTaskMemString path;
  result = item->GetDisplayName(SIGDN_FILESYSPATH, path.put());
  if (FAILED(result) || !path.get()) {
    return std::nullopt;
  }

  return std::wstring(path.get());
}
