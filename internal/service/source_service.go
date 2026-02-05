package service

import (
	"context"
	"errors"
	"margin/internal/model"
	"margin/internal/repo"

	"gorm.io/gorm"
)

type SourceService struct {
	db         *gorm.DB
	sourceRepo *repo.SourceRepository
}

func NewSourceService(db *gorm.DB) *SourceService {
	return &SourceService{
		db:         db,
		sourceRepo: repo.NewSourceRepository(db),
	}
}

// GetSources 获取所有来源
func (s *SourceService) GetSources(ctx context.Context) ([]map[string]interface{}, error) {
	sources, err := s.sourceRepo.GetAll(ctx)
	if err != nil {
		return nil, err
	}

	result := make([]map[string]interface{}, 0, len(sources))
	for _, source := range sources {
		result = append(result, map[string]interface{}{
			"id":      source.ID,
			"name":    source.Name,
			"created": source.CreatedAt,
		})
	}

	return result, nil
}

// AddSource 添加来源
func (s *SourceService) AddSource(ctx context.Context, name string) error {
	if name == "" {
		return errors.New("来源名称不能为空")
	}

	// 检查是否已存在
	_, err := s.sourceRepo.GetByName(ctx, name)
	if err == nil {
		return errors.New("来源已存在")
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	source := &model.Source{Name: name}
	return s.sourceRepo.Create(ctx, source)
}

// DeleteSource 删除来源
func (s *SourceService) DeleteSource(ctx context.Context, id uint) error {
	return s.sourceRepo.Delete(ctx, id)
}

// InitDefaultSources 初始化默认来源
func (s *SourceService) InitDefaultSources(ctx context.Context) error {
	return s.sourceRepo.InitDefaultSources(ctx)
}
