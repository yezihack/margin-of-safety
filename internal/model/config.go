package model

import "time"

// Config 配置表
type Config struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Key       string    `gorm:"uniqueIndex;not null" json:"key"`
	Value     string    `gorm:"type:text" json:"value"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// 配置键常量
const (
	ConfigKeyPasswordHash = "password_hash"
	ConfigKeyEncryptKey   = "encrypt_key"
	ConfigKeyFirstRun     = "first_run"
)
