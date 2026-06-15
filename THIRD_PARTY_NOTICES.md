# Third-Party Notices

This repository contains GPLv3 source code for the MinecraftBedrockUnlocker installer, launcher wrapper and documentation. It also distributes or downloads third-party Online-Fix runtime files that are not authored by this repository.

## Online-Fix runtime components

| File | Purpose | Source availability | License scope in this repository |
|---|---|---|---|
| `winmm.dll` | Runtime loader used by the unlock flow. | Closed-source Online-Fix component. | Not relicensed by this repository. |
| `OnlineFix64.dll` | Runtime unlock component. | Closed-source Online-Fix component. | Not relicensed by this repository. |
| `dlllist.txt` | Runtime configuration that points to the Online-Fix DLL name. | Online-Fix runtime asset. | Not relicensed by this repository. |
| `OnlineFix.ini` | Runtime configuration for the Online-Fix component. | Online-Fix runtime asset. | Not relicensed by this repository. |

The CoelhoFZ repository is only the installer and launcher around those components. The Online-Fix team controls the implementation of the DLLs, and this repository cannot publish source code it does not have.

## GPLv3 scope

GPLv3 applies to the source code authored in this repository, including:

- `install.ps1`
- `unlocker.ps1`
- `build/Launcher.cs`
- `build/build.sh`
- `build/app.manifest`
- repository documentation and project files unless stated otherwise

GPLv3 does not turn the third-party Online-Fix runtime DLLs into GPLv3 source code. They remain third-party binary components documented here.

## Current release hashes

For release `v3.1.10`, the published hashes were:

```text
de28a5433a596efa9693b3488f0a70355fd435654ab5ef3f70c405daab6dcb20  install.ps1
51d080a84d68553968da2f8ab9bab5abd3cad6b8874e2aa5f16702eff3af3a22  unlocker.ps1
845de534f5d0e2afc55f62b87c805dae175358cfe3dc8c010b1c58935a98af5c  MinecraftBedrockUnlocker.exe
cb8baaa2054a11628b96e474e1428a430c95321f8ac3b89764255cbd6628a9d6  winmm.dll
52cb3902999034e01bae63c6a06612d1798b0e0addc1bd4ce7680891b0229953  OnlineFix64.dll
fc0befb4aae4b7f0eeb1c398fccea03cc795590e09db6628974520091fcfc516  dlllist.txt
d13a4c53389c6a35616ccbe2c09912a43369d904a52b461d734f4ebec212ddfc  OnlineFix.ini
```

Always prefer the `SHA256SUMS.txt` file attached to the exact release you downloaded.
