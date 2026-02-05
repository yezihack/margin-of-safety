package repo

import (
	"context"
	"margin/internal/model"

	"gorm.io/gorm"
)

type RebalanceRepository struct {
	db *gorm.DB
}

func NewRebalanceRepository(db *gorm.DB) *RebalanceRepository {
	return &RebalanceRepository{db: db}
}

// Create 创建再平衡记录
func (r *RebalanceRepository) Create(ctx context.Context, rebalance *model.Rebalance) error {
	return r.db.WithContext(ctx).Create(rebalance).Error
}

// GetAll 获取所有再平衡记录
func (r *RebalanceRepository) GetAll(ctx context.Context) ([]*model.Rebalance, error) {
	var rebalances []*model.Rebalance
	err := r.db.WithContext(ctx).Order("created_at DESC").Find(&rebalances).Error
	return rebalances, err
}

// GetLatest 获取最新的再平衡记录
func (r *RebalanceRepository) GetLatest(ctx context.Context) (*model.Rebalance, error) {
	var rebalance model.Rebalance
	err := r.db.WithContext(ctx).Order("created_at DESC").First(&rebalance).Error
	if err != nil {
		return nil, err
	}
	return &rebalance, nil
}

// Delete 删除再平衡记录
func (r *RebalanceRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&model.Rebalance{}, id).Error
}
