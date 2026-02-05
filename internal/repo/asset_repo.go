package repo

import (
	"context"
	"margin/internal/model"

	"gorm.io/gorm"
)

type AssetRepository struct {
	db *gorm.DB
}

func NewAssetRepository(db *gorm.DB) *AssetRepository {
	return &AssetRepository{db: db}
}

func (r *AssetRepository) GetAll(ctx context.Context) ([]model.Asset, error) {
	var assets []model.Asset
	err := r.db.WithContext(ctx).Find(&assets).Error
	return assets, err
}

func (r *AssetRepository) Create(ctx context.Context, asset *model.Asset) error {
	return r.db.WithContext(ctx).Create(asset).Error
}

func (r *AssetRepository) Update(ctx context.Context, asset *model.Asset) error {
	return r.db.WithContext(ctx).Save(asset).Error
}

func (r *AssetRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&model.Asset{}, id).Error
}

func (r *AssetRepository) GetByTypeAndSource(ctx context.Context, assetType, source string) (*model.Asset, error) {
	var asset model.Asset
	err := r.db.WithContext(ctx).
		Where("type = ? AND source = ?", assetType, source).
		First(&asset).Error
	if err != nil {
		return nil, err
	}
	return &asset, nil
}

func (r *AssetRepository) GetByNameAndSource(ctx context.Context, name, source string) (*model.Asset, error) {
	var asset model.Asset
	err := r.db.WithContext(ctx).
		Where("name = ? AND source = ?", name, source).
		First(&asset).Error
	if err != nil {
		return nil, err
	}
	return &asset, nil
}

func (r *AssetRepository) GetByCodeAndSource(ctx context.Context, code, source string) (*model.Asset, error) {
	var asset model.Asset
	err := r.db.WithContext(ctx).
		Where("code = ? AND source = ?", code, source).
		First(&asset).Error
	if err != nil {
		return nil, err
	}
	return &asset, nil
}
