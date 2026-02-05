package service

import (
	"context"
	"errors"
	"fmt"
	"margin/internal/crypto"
	"margin/internal/model"
	"margin/internal/repo"
	"strconv"

	"gorm.io/gorm"
)

type AssetService struct {
	db         *gorm.DB
	assetRepo  *repo.AssetRepository
	configRepo *repo.ConfigRepository
}

func NewAssetService(db *gorm.DB) *AssetService {
	return &AssetService{
		db:         db,
		assetRepo:  repo.NewAssetRepository(db),
		configRepo: repo.NewConfigRepository(db),
	}
}

func (s *AssetService) GetAssets(ctx context.Context) ([]map[string]interface{}, error) {
	assets, err := s.assetRepo.GetAll(ctx)
	if err != nil {
		return nil, err
	}

	encryptKey, err := s.configRepo.Get(ctx, model.ConfigKeyEncryptKey)
	if err != nil {
		return nil, err
	}

	result := make([]map[string]interface{}, 0, len(assets))
	for _, asset := range assets {
		amountStr, err := crypto.Decrypt(asset.EncryptedAmount, encryptKey.Value)
		if err != nil {
			return nil, err
		}
		amount, _ := strconv.ParseFloat(amountStr, 64)

		result = append(result, map[string]interface{}{
			"id":      asset.ID,
			"code":    asset.Code,
			"name":    asset.Name,
			"url":     asset.URL,
			"type":    asset.Type,
			"source":  asset.Source,
			"amount":  amount,
			"created": asset.CreatedAt,
		})
	}

	return result, nil
}

func (s *AssetService) SaveAsset(ctx context.Context, code, name, url, assetType, source string, amount float64) error {
	if code == "" {
		return errors.New("基金代码不能为空")
	}
	if name == "" {
		return errors.New("基金名称不能为空")
	}

	encryptKey, err := s.configRepo.Get(ctx, model.ConfigKeyEncryptKey)
	if err != nil {
		return err
	}

	amountStr := fmt.Sprintf("%.2f", amount)
	encryptedAmount, err := crypto.Encrypt(amountStr, encryptKey.Value)
	if err != nil {
		return err
	}

	// 检查是否已存在（基于代码+来源）
	existing, err := s.assetRepo.GetByCodeAndSource(ctx, code, source)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	if existing != nil {
		// 已存在，更新金额和其他信息
		existing.Name = name
		existing.URL = url
		existing.Type = assetType
		existing.EncryptedAmount = encryptedAmount
		return s.assetRepo.Update(ctx, existing)
	}

	// 新资产，创建
	asset := &model.Asset{
		Code:            code,
		Name:            name,
		URL:             url,
		Type:            assetType,
		Source:          source,
		EncryptedAmount: encryptedAmount,
	}
	return s.assetRepo.Create(ctx, asset)
}

func (s *AssetService) GetPortfolioRatio(ctx context.Context) (map[string]float64, error) {
	assets, err := s.GetAssets(ctx)
	if err != nil {
		return nil, err
	}

	var stockTotal, bondTotal float64
	for _, asset := range assets {
		amount := asset["amount"].(float64)
		if asset["type"] == model.AssetTypeStock {
			stockTotal += amount
		} else {
			bondTotal += amount
		}
	}

	total := stockTotal + bondTotal
	if total == 0 {
		return map[string]float64{"stock": 0, "bond": 0}, nil
	}

	return map[string]float64{
		"stock": stockTotal / total * 100,
		"bond":  bondTotal / total * 100,
	}, nil
}

func (s *AssetService) GetRebalanceAdvice(ctx context.Context, targetStockRatio float64) (map[string]interface{}, error) {
	assets, err := s.GetAssets(ctx)
	if err != nil {
		return nil, err
	}

	var stockTotal, bondTotal float64
	for _, asset := range assets {
		amount := asset["amount"].(float64)
		if asset["type"] == model.AssetTypeStock {
			stockTotal += amount
		} else {
			bondTotal += amount
		}
	}

	total := stockTotal + bondTotal
	if total == 0 {
		return nil, errors.New("no assets found")
	}

	currentStockRatio := stockTotal / total * 100
	currentBondRatio := bondTotal / total * 100
	targetBondRatio := 100 - targetStockRatio

	targetStockAmount := total * targetStockRatio / 100
	targetBondAmount := total * targetBondRatio / 100

	stockAdjust := targetStockAmount - stockTotal
	bondAdjust := targetBondAmount - bondTotal

	return map[string]interface{}{
		"total_assets":        total,
		"current_stock_total": stockTotal,
		"current_bond_total":  bondTotal,
		"current_stock_ratio": currentStockRatio,
		"current_bond_ratio":  currentBondRatio,
		"target_stock_ratio":  targetStockRatio,
		"target_bond_ratio":   targetBondRatio,
		"target_stock_total":  targetStockAmount,
		"target_bond_total":   targetBondAmount,
		"stock_adjust":        stockAdjust,
		"bond_adjust":         bondAdjust,
		"need_rebalance":      abs(currentStockRatio-targetStockRatio) > 0.01,
	}, nil
}

func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}

// DeleteAsset 删除资产
func (s *AssetService) DeleteAsset(ctx context.Context, id uint) error {
	return s.assetRepo.Delete(ctx, id)
}

// UpdateAssetAmount 更新资产金额
func (s *AssetService) UpdateAssetAmount(ctx context.Context, id uint, amount float64) error {
	// 获取资产
	var asset model.Asset
	if err := s.db.WithContext(ctx).First(&asset, id).Error; err != nil {
		return err
	}

	// 获取加密密钥
	encryptKey, err := s.configRepo.Get(ctx, model.ConfigKeyEncryptKey)
	if err != nil {
		return err
	}

	// 加密新金额
	amountStr := fmt.Sprintf("%.2f", amount)
	encryptedAmount, err := crypto.Encrypt(amountStr, encryptKey.Value)
	if err != nil {
		return err
	}

	// 更新金额
	asset.EncryptedAmount = encryptedAmount
	return s.assetRepo.Update(ctx, &asset)
}

// UpdateAsset 更新资产（包括类型、来源和金额）
func (s *AssetService) UpdateAsset(ctx context.Context, id uint, assetType, source string, amount float64) error {
	// 获取资产
	var asset model.Asset
	if err := s.db.WithContext(ctx).First(&asset, id).Error; err != nil {
		return err
	}

	// 检查新的代码+来源组合是否已存在（排除当前资产）
	existing, err := s.assetRepo.GetByCodeAndSource(ctx, asset.Code, source)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	// 如果存在且不是当前资产，返回错误
	if existing != nil && existing.ID != id {
		return fmt.Errorf("该基金在来源\"%s\"中已存在", source)
	}

	// 获取加密密钥
	encryptKey, err := s.configRepo.Get(ctx, model.ConfigKeyEncryptKey)
	if err != nil {
		return err
	}

	// 加密新金额
	amountStr := fmt.Sprintf("%.2f", amount)
	encryptedAmount, err := crypto.Encrypt(amountStr, encryptKey.Value)
	if err != nil {
		return err
	}

	// 更新类型、来源和金额
	asset.Type = assetType
	asset.Source = source
	asset.EncryptedAmount = encryptedAmount
	return s.assetRepo.Update(ctx, &asset)
}
