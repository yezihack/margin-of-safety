package main

import (
	"fmt"
	"log"
	"margin/pkg/db"
	"os"
	"runtime"
)

func main() {
	fmt.Println("=== 数据库路径测试 ===")
	fmt.Printf("操作系统: %s\n", runtime.GOOS)
	fmt.Printf("架构: %s\n", runtime.GOARCH)

	// 获取用户主目录
	homeDir, err := os.UserHomeDir()
	if err != nil {
		log.Fatal("获取用户主目录失败:", err)
	}
	fmt.Printf("用户主目录: %s\n", homeDir)

	// 获取数据库路径
	dbPath, err := db.GetDBPath()
	if err != nil {
		log.Fatal("获取数据库路径失败:", err)
	}
	fmt.Printf("数据库路径: %s\n", dbPath)

	// 检查目录是否存在
	appDir := dbPath[:len(dbPath)-len("/margin.db")]
	if _, err := os.Stat(appDir); os.IsNotExist(err) {
		fmt.Printf("应用目录不存在，将被创建: %s\n", appDir)
	} else {
		fmt.Printf("应用目录已存在: %s\n", appDir)
	}

	fmt.Println("\n✓ 路径测试通过")
}
