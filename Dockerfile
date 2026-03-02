# Windows Container 기반 개발 환경 구축 Dockerfile
# Base image: Windows Server Core with .NET Framework
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# 레이블 추가
LABEL maintainer="dev@example.com"
LABEL description="Development environment with CMake, LLVM, Python, Git, Visual Studio Build Tools, and Node.js"

# 시스템 업데이트 및 기본 설정
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Chocolatey 설치
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Chocolatey로 기본 개발 도구 설치
RUN choco install -y cmake --version=3.31.1
RUN choco install -y llvm --version=14.0.6
RUN choco install -y python --version=3.10.11
RUN choco install -y git
RUN choco install -y nodejs --version=14.6.0
RUN npm install -g node-gyp@9.4.1

# NVM (Node Version Manager) 설치
RUN $env:PATH = [System.Environment]::GetEnvironmentVariable('Path','Machine'); \
    Invoke-WebRequest -Uri "https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-noinstall.zip" -OutFile "nvm.zip"; \
    Expand-Archive -Path "nvm.zip" -DestinationPath "C:\nvm"; \
    Remove-Item "nvm.zip"; \
    New-Item -ItemType Directory -Path 'C:\Program Files\nodejs' -Force | Out-Null

# NVM 환경 변수 설정
RUN [Environment]::SetEnvironmentVariable('NVM_HOME', 'C:\nvm', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('NVM_SYMLINK', 'C:\Program Files\nodejs', [EnvironmentVariableTarget]::Machine); \
    $env:PATH = [System.Environment]::GetEnvironmentVariable('Path','Machine'); \
    [Environment]::SetEnvironmentVariable('Path', $env:PATH + ';C:\nvm;C:\Program Files\nodejs', [EnvironmentVariableTarget]::Machine)

# Visual Studio Build Tools 설치 (대체 방법)
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:/temp/vs_buildtools.exe
RUN C:/temp/vs_buildtools.exe --quiet --wait --norestart --nocache \
    --add Microsoft.VisualStudio.Workload.VCTools \
    --add Microsoft.VisualStudio.Component.Windows10SDK.19041 \
    --add Microsoft.VisualStudio.Component.Windows11SDK.22621 \
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 \
    --includeRecommended --installPath "C:\BuildTools"

RUN Remove-Item C:/temp/vs_buildtools.exe

# 환경 변수 설정
RUN [Environment]::SetEnvironmentVariable('GYP_MSVS_VERSION', '2022', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('VCINSTALLDIR', 'C:\BuildTools\VC', [EnvironmentVariableTarget]::Machine); \
    [Environment]::SetEnvironmentVariable('PYTHON', 'C:\Python310\python.exe', [EnvironmentVariableTarget]::Machine)

# NVM 설정 파일 생성
RUN Set-Content -Path 'C:\nvm\settings.txt' -Value @('root: C:\nvm','path: C:\Program Files\nodejs','arch: 64','proxy:','node_mirror: https://nodejs.org/dist/','npm_mirror: https://github.com/npm/cli/archive/') -Encoding ASCII

# NPM 설정
RUN npm config set msvs_version 2022 --global; \
    npm config set python "C:\Python310\python.exe"; \
    npm config set msbuild_path "C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe"

# 작업 디렉토리 설정
WORKDIR C:\\workspace

# 기본 명령어
CMD ["cmd.exe", "/k", "C:\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat x64 -winsdk=10.0.19041.0 && powershell.exe"]