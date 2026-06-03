# # Download the Rive native libraries for windows > find_program(DART_EXECUTABLE 

Session: `02ef7a61-9571-4533-abaf-a8d23bb0870c`
Saved: 2026-06-03T09:06:13.013Z

## User

# Download the Rive native libraries for windows
> find_program(DART_EXECUTABLE dart REQUIRED)
> if(NOT DART_EXECUTABLE)
>   message(FATAL_ERROR "rive_native: Dart SDK not found. Please install Dart and ensure it is in your PATH.")
  endif()
  
  execute_process(
>   COMMAND cmd.exe /C "${DART_EXECUTABLE} run rive_native:setup --verbose -p windows"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/../"
    RESULT_VARIABLE result
  )
  
> message(STATUS "rive_native setup output: ${output}")
  if(NOT error STREQUAL "")
>   message(WARNING "rive_native setup error: ${error}")
  endif()
  
  if(NOT result EQUAL 0)
>   message(FATAL_ERROR "rive_native: Failed to run setup command. Exit code: ${result}")
  endif()

## Assistant

The command `dart run rive_native:setup -p windows` downloads native DLLs. It fails because `dart run` always checks pub.dev for security advisories, even when all packages are cached.

**Two-step fix:**

**Step 1 — Run setup on the host** (has internet), which downloads the DLLs:
```powershell
cd c:\project\vLearn2\flutter_app
dart run rive_native:setup -p windows
```

Then find what it produced:
```powershell
Get-ChildItem -Recurse -Filter "*.dll" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }
```

**Step 2 — Patch CMakeLists.txt on the VM** to skip the download if the DLLs already exist. Find the file on the VM:

```
%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\rive_native-<version>\windows\CMakeLists.txt
```

Replace the `execute_process` block with a guarded version:

```cmake
# Check if native libs already present (offline / air-gapped build)
file(GLOB RIVE_PREBUILT "${CMAKE_SOURCE_DIR}/../windows/rive_native*.dll")
if(RIVE_PREBUILT)
  message(STATUS "rive_native: prebuilt DLLs found, skipping download.")
else()
  execute_process(
    COMMAND cmd.exe /C "${DART_EXECUTABLE} run rive_native:setup --verbose -p windows"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/../"
    RESULT_VARIABLE result
  )
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "rive_native: Failed to run setup command.  Exit code: ${result}")
  endif()
endif()
```

The workflow then is:
1. Run setup on the host → produces DLLs → bundle them with `make_bundle.ps1` (they'll be in `windows/` under the Flutter app)
2. Apply the bundle on the VM → DLLs land in place
3. Patch the CMakeLists.txt on the VM once → future builds skip the download entirely

What path did the DLLs land in after running setup on the host?
