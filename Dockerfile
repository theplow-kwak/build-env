# Windows Container-based Development Environment Dockerfile
# Base image: Windows Server Core with .NET Framework
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Labels
LABEL maintainer="dev@example.com"
LABEL description="Development environment with CMake, LLVM, Python, Git, Visual Studio Build Tools, and Node.js"

# System update and basic settings
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Copy Chocolatey installation script and certificate, then execute
COPY install-chocolatey.ps1 C:/temp/install-chocolatey.ps1
RUN C:/temp/install-chocolatey.ps1

# Install basic development tools via Chocolatey
RUN choco install -y cmake --version=3.31.10
RUN choco install -y llvm --version=14.0.6 --force
RUN choco install -y python --version=3.10.11
RUN choco install -y git
RUN choco install -y nodejs --version=14.16.1
RUN npm config set strict-ssl false; npm install -g node-gyp@9.4.1

# Install Visual Studio Build Tools
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:/temp/vs_buildtools.exe
RUN C:/temp/vs_buildtools.exe --quiet --wait --norestart --nocache \
    --add Microsoft.VisualStudio.Workload.VCTools \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
    --add Microsoft.VisualStudio.Component.Windows10SDK.19041 \
    --add Microsoft.VisualStudio.Component.Windows11SDK.22621 \
    --installPath "C:\BuildTools"
RUN Remove-Item C:/temp/vs_buildtools.exe

# Install pip packages
RUN python -m pip install --upgrade pip; \
    python -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org colorama==0.4.3 minio==5.0.10

# Install vcpkg to system-wide location (accessible by both Administrator and ContainerAdministrator)
RUN git config --global http.sslVerify false; \
    cd C:\; \
    git clone https://github.com/microsoft/vcpkg.git
RUN cd C:/vcpkg ; ./bootstrap-vcpkg.bat

# Create symbolic links for vcpkg in user home directories for $HOME/vcpkg compatibility
RUN New-Item -ItemType SymbolicLink -Path "C:\Users\ContainerAdministrator\vcpkg" -Target "C:\vcpkg" -Force
RUN New-Item -ItemType SymbolicLink -Path "C:\Users\Administrator\vcpkg" -Target "C:\vcpkg" -Force

# Set environment variables
RUN [Environment]::SetEnvironmentVariable('GYP_MSVS_VERSION', '2022', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('VCINSTALLDIR', 'C:\BuildTools\VC', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('PYTHON', 'C:\Python310\python.exe', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('VSCMD_ARG_host_arch', 'x64', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('VSCMD_ARG_target_arch', 'x64', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('VCPKG_ROOT', 'C:\vcpkg', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64', [EnvironmentVariableTarget]::Machine)

# Configure NPM
RUN npm config set msvs_version 2022 --global; \
    npm config set python "C:\Python310\python.exe"

# Set working directory
WORKDIR C:/workspace

# Default command - Start PowerShell with vcvarsall.bat executed for node-gyp usage
CMD ["powershell.exe"]
