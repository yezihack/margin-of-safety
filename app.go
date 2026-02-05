package main

import (
	"context"
	"fmt"
	"margin/internal/service"
	"margin/pkg/db"
	goruntime "runtime"
	"time"

	"github.com/wailsapp/wails/v2/pkg/runtime"
	"gorm.io/gorm"
)

// App 应用结构
type App struct {
	ctx              context.Context
	db               *gorm.DB
	configService    *service.ConfigService
	assetService     *service.AssetService
	historyService   *service.HistoryService
	fundService      *service.FundService
	sourceService    *service.SourceService
	indexService     *service.IndexService
	rebalanceService *service.RebalanceService
	isAuthenticated  bool // 后端维护的登录状态
}

// NewApp 创建应用实例
func NewApp(db *gorm.DB) *App {
	return &App{
		db:               db,
		configService:    service.NewConfigService(db),
		assetService:     service.NewAssetService(db),
		historyService:   service.NewHistoryService(db),
		fundService:      service.NewFundService(),
		sourceService:    service.NewSourceService(db),
		indexService:     service.NewIndexService(db),
		rebalanceService: service.NewRebalanceService(db),
	}
}

// startup 应用启动时调用
func (a *App) startup(ctx context.Context) {
	a.ctx = ctx

	// 初始化默认来源
	if err := a.sourceService.InitDefaultSources(ctx); err != nil {
		// 记录错误但不中断启动
		println("Failed to init default sources:", err.Error())
	}
}

// IsFirstRun 检查是否首次运行
func (a *App) IsFirstRun() bool {
	return a.configService.IsFirstRun(a.ctx)
}

// SetPassword 设置锁屏密码
func (a *App) SetPassword(password string) error {
	return a.configService.SetPassword(a.ctx, password)
}

// VerifyPassword 验证密码
func (a *App) VerifyPassword(password string) bool {
	result := a.configService.VerifyPassword(a.ctx, password)
	if result {
		// 密码验证成功，设置后端登录状态
		a.isAuthenticated = true
	}
	return result
}

// IsAuthenticated 检查是否已登录（后端状态）
func (a *App) IsAuthenticated() bool {
	return a.isAuthenticated
}

// Logout 登出
func (a *App) Logout() {
	a.isAuthenticated = false
}

// GetAssets 获取所有资产
func (a *App) GetAssets() ([]map[string]interface{}, error) {
	return a.assetService.GetAssets(a.ctx)
}

// GetFundInfo 获取基金信息
func (a *App) GetFundInfo(fundCode string) (map[string]interface{}, error) {
	info, err := a.fundService.GetFundInfo(a.ctx, fundCode)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"code": info.Code,
		"name": info.Name,
		"type": info.Type,
		"url":  info.URL,
	}, nil
}

// SaveAsset 保存资产
func (a *App) SaveAsset(code string, name string, url string, assetType string, source string, amount float64) error {
	return a.assetService.SaveAsset(a.ctx, code, name, url, assetType, source, amount)
}

// GetPortfolioRatio 获取当前组合比例
func (a *App) GetPortfolioRatio() (map[string]float64, error) {
	return a.assetService.GetPortfolioRatio(a.ctx)
}

// GetRebalanceAdvice 获取再平衡建议
func (a *App) GetRebalanceAdvice(targetStockRatio float64) (map[string]interface{}, error) {
	return a.assetService.GetRebalanceAdvice(a.ctx, targetStockRatio)
}

// SaveSnapshot 保存历史快照
func (a *App) SaveSnapshot() error {
	return a.historyService.SaveSnapshot(a.ctx)
}

// GetHistory 获取历史记录
func (a *App) GetHistory() ([]map[string]interface{}, error) {
	return a.historyService.GetHistory(a.ctx)
}

// DeleteHistory 删除历史记录
func (a *App) DeleteHistory(id int64) error {
	return a.historyService.DeleteHistory(a.ctx, id)
}

// GetSources 获取所有来源
func (a *App) GetSources() ([]map[string]interface{}, error) {
	return a.sourceService.GetSources(a.ctx)
}

// AddSource 添加来源
func (a *App) AddSource(name string) error {
	return a.sourceService.AddSource(a.ctx, name)
}

// DeleteSource 删除来源
func (a *App) DeleteSource(id uint) error {
	return a.sourceService.DeleteSource(a.ctx, id)
}

// DeleteAsset 删除资产
func (a *App) DeleteAsset(id uint) error {
	return a.assetService.DeleteAsset(a.ctx, id)
}

// UpdateAssetAmount 更新资产金额
func (a *App) UpdateAssetAmount(id uint, amount float64) error {
	return a.assetService.UpdateAssetAmount(a.ctx, id, amount)
}

// UpdateAsset 更新资产（包括类型、来源和金额）
func (a *App) UpdateAsset(id uint, assetType, source string, amount float64) error {
	return a.assetService.UpdateAsset(a.ctx, id, assetType, source, amount)
}

// GetIndexData 获取单个指数数据
func (a *App) GetIndexData(code string) (map[string]interface{}, error) {
	data, err := a.indexService.GetIndexData(a.ctx, code)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"code":        data.Code,
		"name":        data.Name,
		"price":       data.Price,
		"change":      data.Change,
		"change_rate": data.ChangeRate,
		"update_time": data.UpdateTime,
	}, nil
}

// GetAllIndexes 获取所有指数数据
func (a *App) GetAllIndexes() ([]map[string]interface{}, error) {
	indexes, err := a.indexService.GetAllIndexes(a.ctx)
	if err != nil {
		return nil, err
	}

	result := make([]map[string]interface{}, 0, len(indexes))
	for _, data := range indexes {
		result = append(result, map[string]interface{}{
			"code":        data.Code,
			"name":        data.Name,
			"price":       data.Price,
			"change":      data.Change,
			"change_rate": data.ChangeRate,
			"update_time": data.UpdateTime,
		})
	}

	return result, nil
}

// GetDBInfo 获取数据库信息
func (a *App) GetDBInfo() (map[string]interface{}, error) {
	return db.GetDBInfo()
}

// GetSystemInfo 获取系统信息
func (a *App) GetSystemInfo() map[string]interface{} {
	return map[string]interface{}{
		"os":        goruntime.GOOS,
		"arch":      goruntime.GOARCH,
		"version":   Version,
		"buildDate": BuildDate,
		"gitCommit": GitCommit,
		"goVersion": goruntime.Version(),
	}
}

// BackupDatabase 备份数据库
func (a *App) BackupDatabase() error {
	// 使用 Wails runtime 打开保存文件对话框
	savePath, err := runtime.SaveFileDialog(a.ctx, runtime.SaveDialogOptions{
		DefaultFilename: fmt.Sprintf("margin_backup_%s.db", time.Now().Format("20060102_150405")),
		Title:           "保存数据库备份",
		Filters: []runtime.FileFilter{
			{
				DisplayName: "数据库文件 (*.db)",
				Pattern:     "*.db",
			},
		},
	})

	if err != nil {
		return fmt.Errorf("failed to open save dialog: %w", err)
	}

	// 用户取消了对话框
	if savePath == "" {
		return nil
	}

	// 执行备份
	if err := db.BackupDB(savePath); err != nil {
		return fmt.Errorf("failed to backup database: %w", err)
	}

	return nil
}

// SaveRebalance 保存再平衡记录
func (a *App) SaveRebalance(stockRatio, bondRatio, totalAmount, stockAmount, bondAmount, targetStockRatio, targetBondRatio float64, note string) error {
	return a.rebalanceService.SaveRebalance(a.ctx, stockRatio, bondRatio, totalAmount, stockAmount, bondAmount, targetStockRatio, targetBondRatio, note)
}

// GetRebalanceHistory 获取再平衡历史记录
func (a *App) GetRebalanceHistory() ([]map[string]interface{}, error) {
	return a.rebalanceService.GetRebalanceHistory(a.ctx)
}

// GetLatestRebalance 获取最新的再平衡记录
func (a *App) GetLatestRebalance() (map[string]interface{}, error) {
	return a.rebalanceService.GetLatestRebalance(a.ctx)
}

// DeleteRebalance 删除再平衡记录
func (a *App) DeleteRebalance(id uint) error {
	return a.rebalanceService.DeleteRebalance(a.ctx, id)
}
