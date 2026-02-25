@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM docker-openclawd 一键安装脚本（Windows）
REM 用法: 先下载本脚本后执行 scripts\install.bat [安装目录]
REM 或一键下载并执行: powershell -NoProfile -Command "irm https://raw.githubusercontent.com/liam798/docker-openclawd/main/scripts/install.bat -OutFile install.bat; .\install.bat"

set "REPO=%DOCKER_OPENCLAWD_REPO%"
if not defined REPO set "REPO=https://github.com/liam798/docker-openclawd.git"

set "BRANCH=%DOCKER_OPENCLAWD_BRANCH%"
if not defined BRANCH set "BRANCH=main"

REM 安装目录：第一个参数，或环境变量 DOCKER_OPENCLAWD_DEST，或默认当前目录下的 docker-openclawd
set "DEST=%~1"
if not defined DEST set "DEST=%DOCKER_OPENCLAWD_DEST%"
if not defined DEST set "DEST=%CD%\docker-openclawd"

echo docker-openclawd 一键安装
echo   仓库: %REPO% ^(分支: %BRANCH%^)
echo   目标: %DEST%
echo.

REM 检查 Git
where git >nul 2>&1
if errorlevel 1 (
  echo 错误: 未检测到 Git，请先安装 Git for Windows。
  echo   https://git-scm.com/download/win
  exit /b 1
)

REM 检查 Docker 和 Docker Compose
docker --version >nul 2>&1
if errorlevel 1 (
  echo 错误: 未检测到 Docker，请先安装 Docker Desktop。
  echo   https://docs.docker.com/get-docker/
  exit /b 1
)
docker compose version >nul 2>&1
if errorlevel 1 (
  echo 错误: 未检测到 Docker Compose v2，请确保已安装 Docker Desktop 并启用 Compose。
  echo   https://docs.docker.com/compose/install/
  exit /b 1
)

REM 克隆或更新
if exist "%DEST%\.git" (
  echo 已在 %DEST% 检测到仓库，正在更新...
  pushd "%DEST%"
  git fetch origin
  git checkout %BRANCH% 2>nul
  git pull --ff-only origin %BRANCH%
  if errorlevel 1 (
    echo 更新失败，请检查网络或手动处理。
    popd
    exit /b 1
  )
  popd
) else (
  echo 正在克隆仓库到 %DEST% ...
  git clone --branch %BRANCH% --single-branch --depth 1 "%REPO%" "%DEST%"
  if errorlevel 1 (
    echo 克隆失败，请检查网络与 Git 配置。
    exit /b 1
  )
)

if not exist "%DEST%\docker-setup.bat" (
  echo 错误: 未找到 docker-setup.bat，请检查仓库是否完整。
  exit /b 1
)

echo.
echo 正在执行 docker-setup.bat ...
echo ----------------------------------------
pushd "%DEST%"
call docker-setup.bat
set "EXIT_CODE=!errorlevel!"
popd
endlocal & exit /b %EXIT_CODE%
