# Windows CUDA `llama.cpp` `llama-server` build + runtime packaging

This guide/script pair performs the exact workflow requested for building a current CUDA-enabled `llama-server` on Windows directly from the upstream git repository (not from a zip), then assembling a portable runtime folder.

## Files in this repo

- `scripts/build-llama-cuda-runtime.ps1` — end-to-end build + package script for Windows PowerShell.
- `scripts/launch-oxcart-server.bat` — launch file template copied into the runtime folder.

## Prerequisites (Windows)

- Git
- Node.js + npm
- CMake
- Visual Studio 2022 Build Tools (or Visual Studio 2022) with C++ toolchain
- CUDA toolkit + NVIDIA driver

## Run

Open **x64 Native Tools Command Prompt for VS 2022** or PowerShell with the same toolchain available, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-llama-cuda-runtime.ps1
```

## What the script does

1. Clones latest upstream to:
   `C:\Users\Melox\OneDrive\Documents\llama-cuda-oxcart`
2. Builds WebUI if present (`npm ci/check/lint/build`).
3. Configures CUDA build with:
   `-DGGML_CUDA=ON -DGGML_NATIVE=OFF -DLLAMA_CURL=ON`
4. Builds `llama-server` Release target.
5. Finds `llama-server.exe` and recursively collects dependent `.dll` files from build output.
6. Creates runtime folder:
   `C:\Users\Melox\OneDrive\Documents\oxcart-llama-server-cuda-runtime`
7. Copies:
   - `llama-server.exe`
   - discovered build-output DLLs
   - WebUI assets (if detected)
   - `launch-oxcart-server.bat`
8. Verifies:
   - `llama-server.exe --help`
   - launch BAT (started, waited, then stopped)
9. Emits a complete file list and writes a zip:
   `C:\Users\Melox\OneDrive\Documents\oxcart-llama-server-cuda-runtime.zip`

## Notes

- The script intentionally avoids copying system CUDA DLLs from `C:\Windows\System32`; those are expected to come from the target machine's CUDA/driver install.
- If upstream changes WebUI layout, script copies the detected built folder (`dist`, `build`, or `public`) and prints where it was found.
