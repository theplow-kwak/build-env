# Windows Build Enveronment Docker Image

Windows Servercore Container 기반의 개발 환경 Docker image.

## 포함된 개발 도구

- **CMake 3.31.10**
- **LLVM 14.0.6**
- **Git**
- **Python 3.10.11** include (colorama 0.4.3, minio 5.0.10)
- **vcpkg**
- **Node.js 14.6.0**
- **node-gyp 9.4.1**
- **Visual Studio Build Tools 2022**

## 사용 방법

### 1. Docker 이미지 빌드

```bash
cd c:\projects\build-env
docker build -t build-env .
```

### 2. 컨테이너 실행

```bash
docker run -it --memory=16GB -v C:\workspace:C:/workspace build-env:latest
```

### 3. 컨테이너에 접속

```bash
docker start build-env
docker attach build-env
```

### 4. 개발 환경 확인

컨테이너 내부에서 다음 명령어로 설치된 도구 확인:

```powershell
# CMake 버전 확인
cmake --version

# Python 버전 확인
python --version

# Node.js 버전 확인
node --version

# Git 버전 확인
git --version

# MSBuild 경로 확인
Get-Command msbuild
```

## 주요 환경 변수

- `GYP_MSVS_VERSION=2022`: Node.js 빌드 시 Visual Studio 버전 지정
- `VCINSTALLDIR`: Visual Studio C++ 컴파일러 경로
- `PYTHON`: Python 실행 파일 경로

## 주의사항

- Windows Container는 Windows 호스트에서만 실행 가능
- 이미지 크기가 크므로 넉넉한 디스크 공간 필요
- 첫 빌드 시 다소 시간이 소요될 수 있음

## docker image 삭제

```powershell
docker image prune -f
docker rmi -f $(docker images -q)
```
