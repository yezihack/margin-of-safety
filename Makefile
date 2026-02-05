.PHONY: install dev build clean

install:
	go mod download
	cd frontend && npm install

dev:
	@echo "Starting Wails dev (CGO enabled for WebView2)..."
	GOPROXY=https://goproxy.cn,direct wails dev

build:
	@echo "Building with Wails..."
	GOPROXY=https://goproxy.cn,direct wails build

clean:
	rm -rf build/
	rm -rf frontend/dist/
	rm -rf frontend/node_modules/
	go clean -cache

deps:
	go install github.com/wailsapp/wails/v2/cmd/wails@latest
