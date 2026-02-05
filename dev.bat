@echo off
echo ========================================
echo Margin Dev (No CGO Required)
echo ========================================
echo.

REM 设置环境变量
set CGO_ENABLED=0
set GOPROXY=https://goproxy.cn,direct
set GOOS=windows
set GOARCH=amd64

echo 环境配置:
echo - CGO_ENABLED=0 (纯 Go 编译)
echo - GOPROXY=https://goproxy.cn,direct
echo - 使用 modernc.org/sqlite (无需 GCC)
echo.

echo 下载依赖...
go mod download

echo.
echo 启动开发服务器...
wails dev

pause
