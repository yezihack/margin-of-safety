package repo

import (
	"context"
	"margin/internal/model"

	"gorm.io/gorm"
)

type HistoryRepository struct {
	db *gorm.DB
}

func NewHistoryRepository(db *gorm.DB) *HistoryRepository {
	return &HistoryRepository{db: db}
}

func (r *HistoryRepository) Create(ctx context.Context, history *model.History) error {
	return r.db.WithContext(ctx).Create(history).Error
}

func (r *HistoryRepository) GetAll(ctx context.Context) ([]model.History, error) {
	var histories []model.History
	err := r.db.WithContext(ctx).Order("created_at DESC").Find(&histories).Error
	return histories, err
}

func (r *HistoryRepository) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.History{}, id).Error
}
