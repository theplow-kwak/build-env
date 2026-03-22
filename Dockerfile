# escape=`

# Windows Container-based Development Environment Dockerfile
# Base image: Windows Server Core with .NET Framework
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Labels
LABEL maintainer="dev@example.com"
LABEL description="Development environment with CMake, LLVM, Python, Git, Visual Studio Build Tools, and Node.js"

# System update and basic settings
SHELL ["powershell", "-NoLogo", "-ExecutionPolicy", "Bypass", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Create required directories in a single layer
RUN New-Item C:\deps -ItemType Directory -Force; `
    New-Item C:\workspace -ItemType Directory -Force

# Copy Chocolatey installation script and certificate, then execute
COPY install-chocolatey.ps1 C:/temp/install-chocolatey.ps1
RUN C:/temp/install-chocolatey.ps1

# Install basic development tools via Chocolatey
RUN choco install -y cmake --version=3.31.10; `
    choco install -y llvm --version=14.0.6; `
    choco install -y python --version=3.10.11; `
    choco install -y git

# Install Visual Studio Build Tools with required components to custom path
RUN choco install -y visualstudio2022buildtools `
    --package-parameters "'--installPath C:\deps\vs2022 `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK.19041 `
    --add Microsoft.VisualStudio.Component.Windows11SDK.22621'"

# Install Node.js with proper PATH configuration and environment setup
RUN choco install -y nodejs --version=14.16.1; `
    $env:PATH = 'C:\Program Files\nodejs;' + $env:PATH; `
    npm config set msvs_version 2022 --global; `
    npm config set python "C:\Python310\python.exe"; `
    npm config set strict-ssl false; npm install -g node-gyp@9.4.1

# Clean up chocolatey cache
RUN choco source remove -n=chocolatey

# Install pip packages
RUN python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade pip; `
    python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org colorama==0.4.3 minio==5.0.10

# Clone vcpkg and bootstrap it
RUN git config --global http.sslVerify false; `
    git clone https://github.com/microsoft/vcpkg.git C:\deps\vcpkg; `
    C:\deps\vcpkg\bootstrap-vcpkg.bat

# Create symbolic links for vcpkg in user home directories for $HOME/vcpkg compatibility
RUN New-Item -ItemType SymbolicLink -Path "C:\Users\ContainerAdministrator\vcpkg" -Target "C:\deps\vcpkg" -Force; `
    New-Item -ItemType SymbolicLink -Path "C:\Users\Administrator\vcpkg" -Target "C:\deps\vcpkg" -Force

# Download and extract Node headers, then cleanup
ARG NODE_VERSION=14.16.1
ENV NODE_BASE_PATH=C:\deps\third-party-lib\node-cache\v14.16.0
RUN New-Item -Path "$env:NODE_BASE_PATH\x64" -ItemType Directory -Force; `
    Invoke-WebRequest "https://nodejs.org/download/release/v$env:NODE_VERSION/node-v$env:NODE_VERSION-headers.tar.gz" `
    -OutFile C:\node_headers.tar.gz; `
    tar -xf C:\node_headers.tar.gz -C "$env:NODE_BASE_PATH" --strip-components=1; `
    Invoke-WebRequest "https://nodejs.org/download/release/v$env:NODE_VERSION/win-x64/node.lib" `
    -OutFile "$env:NODE_BASE_PATH\x64\node.lib"; `
    Remove-Item C:\node_headers.tar.gz -Force

# Set Static Environment Variables using ENV (Recommended)
ENV GYP_MSVS_VERSION="2022" `
    VCINSTALLDIR="C:\deps\vs2022\VC" `
    PYTHON="C:\Python310\python.exe" `
    VSCMD_ARG_host_arch="x64" `
    VSCMD_ARG_target_arch="x64" `
    VCPKG_ROOT="C:\deps\vcpkg"

# Update Path-based variables (INCLUDE, LIB, PATH)
ENV INCLUDE="${NODE_BASE_PATH}\include;${INCLUDE}" `
    LIB="${NODE_BASE_PATH}\x64;${LIB}"
RUN [Environment]::SetEnvironmentVariable('NODE_TLS_REJECT_UNAUTHORIZED', '0', 'Machine'); `
    [Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64', [EnvironmentVariableTarget]::Machine)

COPY entrypoint.ps1 C:/temp/entrypoint.ps1

WORKDIR C:/workspace

ENTRYPOINT ["powershell.exe", "-File", "C:/temp/entrypoint.ps1"]
CMD ["powerShell.exe"]