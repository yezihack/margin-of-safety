package db

import (
	"database/sql"
	"fmt"
	"margin/internal/model"
	"os"
	"path/filepath"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	_ "modernc.org/sqlite" // 纯 Go SQLite 驱动，无需 CGO
)

// GetDBPath 获取数据库文件路径（跨平台）
func GetDBPath() (string, error) {
	// 获取用户主目录
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get user home directory: %w", err)
	}

	// 创建应用数据目录：~/.marginofsafety
	appDir := filepath.Join(homeDir, ".marginofsafety")

	// 确保目录存在
	if err := os.MkdirAll(appDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create app directory: %w", err)
	}

	// 返回数据库文件完整路径
	dbPath := filepath.Join(appDir, "margin.db")
	return dbPath, nil
}

// GetDBInfo 获取数据库信息（用于前端显示）
func GetDBInfo() (map[string]interface{}, error) {
	dbPath, err := GetDBPath()
	if err != nil {
		return nil, err
	}

	info := map[string]interface{}{
		"path": dbPath,
	}

	// 检查文件是否存在并获取大小
	if fileInfo, err := os.Stat(dbPath); err == nil {
		info["size"] = fileInfo.Size()
		info["modified"] = fileInfo.ModTime().Format("2006-01-02 15:04:05")
		info["exists"] = true
	} else {
		info["exists"] = false
	}

	return info, nil
}

// BackupDB 备份数据库到指定路径
func BackupDB(destPath string) error {
	srcPath, err := GetDBPath()
	if err != nil {
		return fmt.Errorf("failed to get database path: %w", err)
	}

	// 检查源文件是否存在
	if _, err := os.Stat(srcPath); os.IsNotExist(err) {
		return fmt.Errorf("database file does not exist")
	}

	// 读取源文件
	data, err := os.ReadFile(srcPath)
	if err != nil {
		return fmt.Errorf("failed to read database file: %w", err)
	}

	// 写入目标文件
	if err := os.WriteFile(destPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write backup file: %w", err)
	}

	return nil
}

// InitDB 初始化数据库（使用 modernc.org/sqlite，无需 CGO）
func InitDB() (*gorm.DB, error) {
	// 获取数据库路径
	dbPath, err := GetDBPath()
	if err != nil {
		return nil, err
	}

	// 先用 database/sql 打开，强制使用 modernc.org/sqlite
	sqlDB, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// 使用已打开的 sql.DB 创建 GORM 实例
	db, err := gorm.Open(sqlite.Dialector{
		DriverName: "sqlite",
		Conn:       sqlDB,
	}, &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to create gorm instance: %w", err)
	}

	// 自动迁移数据表
	err = db.AutoMigrate(
		&model.Config{},
		&model.Asset{},
		&model.History{},
		&model.Source{},
		&model.Rebalance{},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to migrate database: %w", err)
	}

	return db, nil
}
