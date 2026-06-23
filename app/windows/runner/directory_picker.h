#ifndef RUNNER_DIRECTORY_PICKER_H_
#define RUNNER_DIRECTORY_PICKER_H_

#include <windows.h>

#include <optional>
#include <string>

std::optional<std::wstring> SelectDirectory(HWND owner,
                                            const std::wstring& initial_path);

#endif  // RUNNER_DIRECTORY_PICKER_H_
