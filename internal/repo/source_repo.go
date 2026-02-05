package repo

import (
	"context"
	"margin/internal/model"

	"gorm.io/gorm"
)

type SourceRepository struct {
	db *gorm.DB
}

func NewSourceRepository(db *gorm.DB) *SourceRepository {
	return &SourceRepository{db: db}
}

// GetAll 获取所有来源
func (r *SourceRepository) GetAll(ctx context.Context) ([]model.Source, error) {
	var sources []model.Source
	err := r.db.WithContext(ctx).Order("created_at ASC").Find(&sources).Error
	return sources, err
}

// Create 创建来源
func (r *SourceRepository) Create(ctx context.Context, source *model.Source) error {
	return r.db.WithContext(ctx).Create(source).Error
}

// Delete 删除来源
func (r *SourceRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&model.Source{}, id).Error
}

// GetByName 根据名称查询来源
func (r *SourceRepository) GetByName(ctx context.Context, name string) (*model.Source, error) {
	var source model.Source
	err := r.db.WithContext(ctx).Where("name = ?", name).First(&source).Error
	if err != nil {
		return nil, err
	}
	return &source, nil
}

// InitDefaultSources 初始化默认来源
func (r *SourceRepository) InitDefaultSources(ctx context.Context) error {
	for _, name := range model.DefaultSources {
		// 检查是否已存在
		_, err := r.GetByName(ctx, name)
		if err == gorm.ErrRecordNotFound {
			// 不存在则创建
			source := &model.Source{Name: name}
			if err := r.Create(ctx, source); err != nil {
				return err
			}
		}
	}
	return nil
}
