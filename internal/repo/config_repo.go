package repo

import (
	"context"
	"margin/internal/model"

	"gorm.io/gorm"
)

type ConfigRepository struct {
	db *gorm.DB
}

func NewConfigRepository(db *gorm.DB) *ConfigRepository {
	return &ConfigRepository{db: db}
}

func (r *ConfigRepository) Get(ctx context.Context, key string) (*model.Config, error) {
	var config model.Config
	err := r.db.WithContext(ctx).Where("key = ?", key).First(&config).Error
	if err != nil {
		return nil, err
	}
	return &config, nil
}

func (r *ConfigRepository) Set(ctx context.Context, key, value string) error {
	config := &model.Config{Key: key, Value: value}
	return r.db.WithContext(ctx).
		Where("key = ?", key).
		Assign(model.Config{Value: value}).
		FirstOrCreate(config).Error
}
