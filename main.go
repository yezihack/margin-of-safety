package main

import (
	"embed"
	"log"

	"margin/pkg/db"

	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
	// 初始化数据库
	database, err := db.InitDB()
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// 创建应用实例
	app := NewApp(database)

	// 创建 Wails 应用
	err = wails.Run(&options.App{
		Title:  "Margin - Build portfolios that survive uncertainty",
		Width:  1320,
		Height: 880,
		AssetServer: &assetserver.Options{
			Assets: assets,
		},
		BackgroundColour: &options.RGBA{R: 27, G: 38, B: 54, A: 1},
		OnStartup:        app.startup,
		Bind: []interface{}{
			app,
		},
	})

	if err != nil {
		log.Fatal("Error:", err)
	}
}
