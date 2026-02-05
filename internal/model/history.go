package model

import "time"

// History 历史快照表
type History struct {
	ID                  uint      `gorm:"primaryKey" json:"id"`
	EncryptedStockTotal string    `gorm:"type:text;not null" json:"-"` // 加密的股票总额
	EncryptedBondTotal  string    `gorm:"type:text;not null" json:"-"` // 加密的债券总额
	StockRatio          float64   `json:"stock_ratio"`                 // 股票比例
	BondRatio           float64   `json:"bond_ratio"`                  // 债券比例
	CreatedAt           time.Time `json:"created_at"`
}
