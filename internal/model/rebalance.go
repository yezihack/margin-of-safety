package model

import "time"

// Rebalance 再平衡记录
type Rebalance struct {
	ID               uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	StockRatio       float64   `gorm:"not null" json:"stock_ratio"`        // 股票比例
	BondRatio        float64   `gorm:"not null" json:"bond_ratio"`         // 债券比例
	TotalAmount      float64   `gorm:"not null" json:"total_amount"`       // 总金额
	StockAmount      float64   `gorm:"not null" json:"stock_amount"`       // 股票金额
	BondAmount       float64   `gorm:"not null" json:"bond_amount"`        // 债券金额
	TargetStockRatio float64   `gorm:"not null" json:"target_stock_ratio"` // 目标股票比例
	TargetBondRatio  float64   `gorm:"not null" json:"target_bond_ratio"`  // 目标债券比例
	Note             string    `gorm:"type:text" json:"note"`              // 备注
	CreatedAt        time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Rebalance) TableName() string {
	return "rebalances"
}
