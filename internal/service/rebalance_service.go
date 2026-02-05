package service

import (
	"context"
	"margin/internal/model"
	"margin/internal/repo"

	"gorm.io/gorm"
)

type RebalanceService struct {
	db            *gorm.DB
	rebalanceRepo *repo.RebalanceRepository
}

func NewRebalanceService(db *gorm.DB) *RebalanceService {
	return &RebalanceService{
		db:            db,
		rebalanceRepo: repo.NewRebalanceRepository(db),
	}
}

// SaveRebalance 保存再平衡记录
func (s *RebalanceService) SaveRebalance(ctx context.Context, stockRatio, bondRatio, totalAmount, stockAmount, bondAmount, targetStockRatio, targetBondRatio float64, note string) error {
	rebalance := &model.Rebalance{
		StockRatio:       stockRatio,
		BondRatio:        bondRatio,
		TotalAmount:      totalAmount,
		StockAmount:      stockAmount,
		BondAmount:       bondAmount,
		TargetStockRatio: targetStockRatio,
		TargetBondRatio:  targetBondRatio,
		Note:             note,
	}
	return s.rebalanceRepo.Create(ctx, rebalance)
}

// GetRebalanceHistory 获取再平衡历史记录
func (s *RebalanceService) GetRebalanceHistory(ctx context.Context) ([]map[string]interface{}, error) {
	rebalances, err := s.rebalanceRepo.GetAll(ctx)
	if err != nil {
		return nil, err
	}

	result := make([]map[string]interface{}, 0, len(rebalances))
	for _, r := range rebalances {
		result = append(result, map[string]interface{}{
			"id":                 r.ID,
			"stock_ratio":        r.StockRatio,
			"bond_ratio":         r.BondRatio,
			"total_amount":       r.TotalAmount,
			"stock_amount":       r.StockAmount,
			"bond_amount":        r.BondAmount,
			"target_stock_ratio": r.TargetStockRatio,
			"target_bond_ratio":  r.TargetBondRatio,
			"note":               r.Note,
			"created_at":         r.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	return result, nil
}

// GetLatestRebalance 获取最新的再平衡记录
func (s *RebalanceService) GetLatestRebalance(ctx context.Context) (map[string]interface{}, error) {
	rebalance, err := s.rebalanceRepo.GetLatest(ctx)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}

	return map[string]interface{}{
		"id":                 rebalance.ID,
		"stock_ratio":        rebalance.StockRatio,
		"bond_ratio":         rebalance.BondRatio,
		"total_amount":       rebalance.TotalAmount,
		"stock_amount":       rebalance.StockAmount,
		"bond_amount":        rebalance.BondAmount,
		"target_stock_ratio": rebalance.TargetStockRatio,
		"target_bond_ratio":  rebalance.TargetBondRatio,
		"note":               rebalance.Note,
		"created_at":         rebalance.CreatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// DeleteRebalance 删除再平衡记录
func (s *RebalanceService) DeleteRebalance(ctx context.Context, id uint) error {
	return s.rebalanceRepo.Delete(ctx, id)
}
