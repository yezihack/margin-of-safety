@echo off
echo ========================================
echo Building Margin Application
echo ========================================

REM 获取当前日期时间
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set BUILD_DATE=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

REM 获取 Git 提交哈希（如果可用）
for /f %%i in ('git rev-parse --short HEAD 2^>nul') do set GIT_COMMIT=%%i
if "%GIT_COMMIT%"=="" set GIT_COMMIT=unknown

echo Build Date: %BUILD_DATE%
echo Git Commit: %GIT_COMMIT%
echo.

REM 构建应用（注入版本信息）
wails build -ldflags "-X main.BuildDate='%BUILD_DATE%' -X main.GitCommit=%GIT_COMMIT%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Build completed successfully!
    echo Output: build\bin\margin.exe
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Build failed!
    echo ========================================
    exit /b 1
)
