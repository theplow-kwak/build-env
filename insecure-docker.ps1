# 1. 설정 및 경로 정의
$configPath = "C:\ProgramData\docker\config"
$configFile = "$configPath\daemon.json"
$newRegistry = "서버-IP:포트"  # <--- 여기를 수정하세요!

# 2. 폴더가 없으면 생성
if (!(Test-Path $configPath)) { 
    New-Item -ItemType Directory -Path $configPath | Out-Null 
}

# 3. 기존 설정 불러오기 및 병합
if (Test-Path $configFile) {
    # 기존 파일이 있으면 읽어서 JSON 개체로 변환
    $currentConfig = Get-Content $configFile -Raw | ConvertFrom-Json
} else {
    # 기존 파일이 없으면 빈 개체 생성
    $currentConfig = @{} | Select-Object -Property "insecure-registries"
}

# 4. insecure-registries 항목 업데이트
if ($null -eq $currentConfig."insecure-registries") {
    # 항목이 아예 없으면 새로 추가
    $currentConfig | Add-Member -MemberType NoteProperty -Name "insecure-registries" -Value @($newRegistry)
} else {
    # 항목이 이미 있으면 중복 체크 후 추가
    if ($currentConfig."insecure-registries" -notcontains $newRegistry) {
        $currentConfig."insecure-registries" += $newRegistry
    }
}

# 5. 파일 저장 (JSON 형식으로 변환)
$currentConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile

Write-Host "Success: $configFile 에 $newRegistry 가 병합되었습니다." -ForegroundColor Green

# 6. Docker 서비스 재시작
Restart-Service docker

# 7. 결과 확인
docker info | Select-String "Insecure Registries" -Context 0,1
