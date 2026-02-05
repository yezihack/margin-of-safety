package model

import "time"

// Source 资产来源表
type Source struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `gorm:"uniqueIndex;not null" json:"name"` // 来源名称，如"支付宝"
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// 默认来源
var DefaultSources = []string{
	"支付宝",
	"天天基金",
	"微信",
	"腾讯理财通",
	"且慢",
	"雪球",
	"京东金融",
	"易方达基金APP",
	"华夏基金APP",
	"广发基金APP",
	"招商银行",
	"工商银行",
	"建设银行",
	"华泰证券",
	"中信证券",
	"国泰君安",
	"国泰君安",
}
