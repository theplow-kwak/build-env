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

## docker-ce 사전설치

script를 사용하여 docker-ce를 설치한다.

```powershell
.\install-docker-ce.ps1 -HyperV
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

https로 동작하는 docker server에 접근하기 위해 insecure 설정을 추가한다.

```powershell
.\insecure-docker.ps1 -Registry myregistry:5000
```

## Docker image 사용 방법

### 1. Docker image pull

docker hub에서 사전 제작한 docker image를 다운받아 사용한다.

```powershell
docker pull 192.168.0.100:5000/build-env:1.0
docker tag 192.168.0.100:5000/build-env:1.0 build-env
```

### 2. Docker image를 이용한 빌드 실행

#### 방법 1. 컨테이너 실행

```powershell
docker run -it --rm --memory=16GB -v C:\workspace:C:/workspace build-env:latest cmd /c "cd C:\workspace && install.bat"
```

#### 방법 2. 컨테이너에 접속

'--rm' option을 사용하여 매번 컨테이너를 지우는 대신, 한번 실행한 컨테이너에 재 접속 하는 방식

```powershell
docker run -it --memory=16GB -v C:\workspace:C:/workspace build-env:latest powershell.exe"
docker start build-env
docker attach build-env
```

### 개발 환경 확인

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

## Dockerfile을 이용한 docker image build

### Docker 이미지 빌드

```powershell
cd c:\projects\build-env
docker build -t build-env .
```

### docker image 삭제

```powershell
docker image prune -f
docker rmi -f $(docker images -q)
```

### docker image push

```bash
docker commit build-env build-env-saved
docker tag build-env-saved:latest 192.168.0.100:5000/build-env:1.0
docker push 192.168.0.100:5000/build-env:1.0
```

### docker image pull

```bash
docker pull 192.168.0.100:5000/build-env:1.0
```
