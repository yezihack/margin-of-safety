package service

import (
	"context"
	"errors"
	"margin/internal/crypto"
	"margin/internal/model"
	"margin/internal/repo"

	"gorm.io/gorm"
)

type ConfigService struct {
	repo *repo.ConfigRepository
}

func NewConfigService(db *gorm.DB) *ConfigService {
	return &ConfigService{
		repo: repo.NewConfigRepository(db),
	}
}

func (s *ConfigService) IsFirstRun(ctx context.Context) bool {
	_, err := s.repo.Get(ctx, model.ConfigKeyPasswordHash)
	return errors.Is(err, gorm.ErrRecordNotFound)
}

func (s *ConfigService) SetPassword(ctx context.Context, password string) error {
	// 生成密码哈希
	passwordHash := crypto.HashPassword(password)
	if err := s.repo.Set(ctx, model.ConfigKeyPasswordHash, passwordHash); err != nil {
		return err
	}

	// 生成加密密钥
	encryptKey, err := crypto.GenerateKey()
	if err != nil {
		return err
	}
	return s.repo.Set(ctx, model.ConfigKeyEncryptKey, encryptKey)
}

func (s *ConfigService) VerifyPassword(ctx context.Context, password string) bool {
	config, err := s.repo.Get(ctx, model.ConfigKeyPasswordHash)
	if err != nil {
		return false
	}
	return config.Value == crypto.HashPassword(password)
}

func (s *ConfigService) GetEncryptKey(ctx context.Context) (string, error) {
	config, err := s.repo.Get(ctx, model.ConfigKeyEncryptKey)
	if err != nil {
		return "", err
	}
	return config.Value, nil
}
