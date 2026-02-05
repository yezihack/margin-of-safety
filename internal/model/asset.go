package model

import "time"

// Asset 资产表
type Asset struct {
	ID              uint      `gorm:"primaryKey" json:"id"`
	Code            string    `gorm:"index;default:'';not null" json:"code"` // 基金代码，如"050027"
	Name            string    `gorm:"default:'';not null" json:"name"`       // 资产名称，如"博时信用债纯债债券A"
	URL             string    `gorm:"default:''" json:"url"`                 // 基金详情页 URL
	Type            string    `gorm:"index;not null" json:"type"`            // stock/bond
	Source          string    `gorm:"not null" json:"source"`                // 支付宝/天天基金
	EncryptedAmount string    `gorm:"type:text;not null" json:"-"`           // 加密后的金额
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// 资产类型常量
const (
	AssetTypeStock = "stock"
	AssetTypeBond  = "bond"
)
