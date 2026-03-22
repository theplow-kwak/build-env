# Git History Compression Guide

## Overview
Git 히스토리를 압축하여 줄이는 다양한 방법을 안내합니다. 현재 레포지토리에는 17개의 커밋이 있습니다.

## Current History Analysis
```
* c48fa78 (HEAD -> main, origin/main, origin/HEAD) refactor: add VS Code/Beyond Compare installs
* fc1d3ab refactor: streamline Chocolatey installation script with improved error handling
* f35147a refactor: convert Dockerfile to PowerShell script for Windows container development environment
* ba4406d fixed error
* bc0daf9 fixed error from set env
* 7155e07 upgrade for set env valiables
* 9846e23 fixed path
* c84e6b7 download node.lib also
* fe21943 using copy-item instead of symbolic link
* f775690 fixed entrypoint
* 974dd45 improve entrypoint for the node headers
* 29e0555 MCTP.md: 기본 전송 단위 (BTU)
* 32c913a Install Node.js after installing VSTools
* b89f5e0 install Visual Studio Build Tools to custom path and update VCINSTALLDIR
* 9493c78 set trusted-host for upgrade pip
* 9ce2d35 remove dockerfile.gpt
* ac4ce60 refactor: optimize Dockerfile for Windows container development environment
```

## Methods to Compress Git History

### 1. Interactive Rebase (Recommended for local changes)

#### Compress last N commits:
```bash
# 마지막 5개 커밋을 하나로 압축
git rebase -i HEAD~5
```

#### Compress all commits into one:
```bash
# 전체 히스토리를 하나의 커밋으로 압축
git rebase -i --root
```

#### Rebase 과정:
1. `git rebase -i HEAD~5` 실행
2. 에디터에서 첫 번째 커밋은 `pick`으로 유지
3. 나머지 커밋을 `squash` 또는 `s`로 변경
4. 저장하고 종료
5. 새로운 커밋 메시지 작성

### 2. Soft Reset (Local only)

#### Reset to specific commit and create new commit:
```bash
# 특정 커밋으로 리셋 (예: 5개 전으로)
git reset --soft HEAD~5

# 모든 변경사항을 하나의 커밋으로
git add .
git commit -m "Consolidated changes from last 5 commits"

# 강제 푸시 (주의: 원격 레포지토리 영향)
git push --force-with-lease origin main
```

### 3. Hard Reset and Force Push (Destructive)

#### Complete history rewrite:
```bash
# 현재 HEAD를 orphan 브랜치로 이동
git checkout --orphan temp-branch

# 모든 파일 추가
git add -A
git commit -m "Initial commit with compressed history"

# 기존 브랜치 삭제 및 이름 변경
git branch -D main
git branch -m main

# 강제 푸시
git push -f origin main
```

### 4. Filter-Branch (Advanced, for removing files)

#### Remove specific files from history:
```bash
# 특정 파일을 전체 히스토리에서 제거
git filter-branch --tree-filter 'rm -f filename' HEAD

# 또는 BFG Repo-Cleaner 사용 (권장)
java -jar bfg.jar --delete-files filename.git
```

### 5. Git Filter-Repo (Modern approach)

#### Install and use git-filter-repo:
```bash
# 설치 (Python 필요)
pip install git-filter-repo

# 사용 예시
git filter-repo --path file-to-remove --invert-paths
```

## Recommended Approach for Your Case

### Option 1: Interactive Rebase (Safest)
```bash
# 최근 10개 커밋을 하나로 압축
git rebase -i HEAD~10

# 에디터에서:
# pick c48fa78 refactor: add VS Code/Beyond Compare installs
# squash fc1d3ab refactor: streamline Chocolatey installation script
# squash f35147a refactor: convert Dockerfile to PowerShell script
# ... (나머지 7개도 squash로 변경)
```

### Option 2: Selective Squash
```bash
# 관련된 커밋만 그룹화
git rebase -i HEAD~17

# 예시:
# pick ac4ce60 refactor: optimize Dockerfile for Windows container development environment
# squash 4e106ce Remove Dockerfile.gpt from repository
# squash 96654d5 Dockerfiles from ChatGPT
# pick 9ce2d35 remove dockerfile.gpt
# squash 9493c78 set trusted-host for upgrade pip
# ... (기타 관련 커밋 그룹화)
```

## Safety Precautions

### Before Compressing:
1. **Backup your repository**:
   ```bash
   git clone --mirror your-repo backup-repo.git
   ```

2. **Ensure no one else is working on the branch**

3. **Create a backup branch**:
   ```bash
   git branch backup-branch
   ```

### After Compressing:
1. **Force push with lease** (safer than force):
   ```bash
   git push --force-with-lease origin main
   ```

2. **Notify team members** if it's a shared repository

## Best Practices

1. **Only compress local history** if the branch is shared
2. **Use meaningful commit messages** after squashing
3. **Test the compressed history** works correctly
4. **Consider using `--force-with-lease`** instead of `--force`
5. **Document the changes** for team awareness

## Quick Commands Summary

```bash
# View current history
git log --oneline --graph

# Interactive rebase (recommended)
git rebase -i HEAD~10

# Soft reset (local only)
git reset --soft HEAD~5
git commit -m "New consolidated message"
git push --force-with-lease origin main

# Complete rewrite (destructive)
git checkout --orphan temp-branch
git add -A
git commit -m "Initial commit"
git branch -D main
git branch -m main
git push -f origin main
```

Choose the method that best fits your needs based on whether you want to preserve some history structure or completely rewrite it.