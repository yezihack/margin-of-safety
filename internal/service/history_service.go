package service

import (
	"context"
	"fmt"
	"margin/internal/crypto"
	"margin/internal/model"
	"margin/internal/repo"
	"strconv"

	"gorm.io/gorm"
)

type HistoryService struct {
	db          *gorm.DB
	historyRepo *repo.HistoryRepository
	assetRepo   *repo.AssetRepository
	configRepo  *repo.ConfigRepository
}

func NewHistoryService(db *gorm.DB) *HistoryService {
	return &HistoryService{
		db:          db,
		historyRepo: repo.NewHistoryRepository(db),
		assetRepo:   repo.NewAssetRepository(db),
		configRepo:  repo.NewConfigRepository(db),
	}
}

func (s *HistoryService) SaveSnapshot(ctx context.Context) error {
	assets, err := s.assetRepo.GetAll(ctx)
	if err != nil {
		return err
	}

	encryptKey, err := s.configRepo.Get(ctx, model.ConfigKeyEncryptKey)
	if err != nil {
		return err
	}

	var stockTotal, bondTotal float64
	for _, asset := range assets {
		amountStr, err := crypto.Decrypt(asset.EncryptedAmount, encryptKey.Value)
		if err != nil {
			return err
		}
		amount, _ := strconv.ParseFloat(amountStr, 64)

		if asset.Type == model.AssetTypeStock {
			stockTotal += amount
		} else {
			bondTotal += amount
		}
	}

	total := stockTotal + bondTotal
	if total == 0 {
		return nil
	}

	encryptedStock, err := crypto.Encrypt(fmt.Sprintf("%.2f", stockTotal), encryptKey.Value)
	if err != nil {
		return err
	}

	encryptedBond, err := crypto.Encrypt(fmt.Sprintf("%.2f", bondTotal), encryptKey.Value)
	if err != nil {
		return err
	}

	history := &model.History{
		EncryptedStockTotal: encryptedStock,
		EncryptedBondTotal:  encryptedBond,
		StockRatio:          stockTotal / total * 100,
		BondRatio:           bondTotal / total * 100,
	}

	return s.historyRepo.Create(ctx, history)
}

func (s *HistoryService) GetHistory(ctx context.Context) ([]map[string]interface{}, error) {
	histories, err := s.historyRepo.GetAll(ctx)
	if err != nil {
		return nil, err
	}

	encryptKey, err := s.configRepo.Get(ctx, model.ConfigKeyEncryptKey)
	if err != nil {
		return nil, err
	}

	result := make([]map[string]interface{}, 0, len(histories))
	for _, h := range histories {
		stockStr, err := crypto.Decrypt(h.EncryptedStockTotal, encryptKey.Value)
		if err != nil {
			return nil, err
		}
		bondStr, err := crypto.Decrypt(h.EncryptedBondTotal, encryptKey.Value)
		if err != nil {
			return nil, err
		}

		stockTotal, _ := strconv.ParseFloat(stockStr, 64)
		bondTotal, _ := strconv.ParseFloat(bondStr, 64)

		result = append(result, map[string]interface{}{
			"id":          h.ID,
			"stock_total": stockTotal,
			"bond_total":  bondTotal,
			"stock_ratio": h.StockRatio,
			"bond_ratio":  h.BondRatio,
			"created_at":  h.CreatedAt,
		})
	}

	return result, nil
}

func (s *HistoryService) DeleteHistory(ctx context.Context, id int64) error {
	return s.historyRepo.Delete(ctx, id)
}
