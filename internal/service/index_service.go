package service

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"time"

	"gorm.io/gorm"
)

type IndexService struct {
	db *gorm.DB
}

type IndexData struct {
	Code       string  `json:"code"`        // 指数代码
	Name       string  `json:"name"`        // 指数名称
	Price      float64 `json:"price"`       // 当前点位
	Change     float64 `json:"change"`      // 涨跌点
	ChangeRate float64 `json:"change_rate"` // 涨跌幅(%)
	UpdateTime string  `json:"update_time"` // 更新时间
}

func NewIndexService(db *gorm.DB) *IndexService {
	return &IndexService{
		db: db,
	}
}

// GetIndexData 获取指数数据
func (s *IndexService) GetIndexData(ctx context.Context, indexCode string) (*IndexData, error) {
	var url string
	var name string

	switch indexCode {
	case "000001":
		url = "https://quote.eastmoney.com/zs000001.html"
		name = "上证指数"
	case "000300":
		url = "https://quote.eastmoney.com/zs000300.html"
		name = "沪深300"
	case "SPX":
		url = "https://quote.eastmoney.com/gb/zsSPX.html"
		name = "标普500"
	case "NDX":
		url = "https://quote.eastmoney.com/gb/zsNDX.html"
		name = "纳斯达克"
	default:
		return nil, fmt.Errorf("unsupported index code: %s", indexCode)
	}

	data, err := s.fetchIndexData(url, indexCode, name)
	if err != nil {
		return nil, err
	}

	return data, nil
}

// GetAllIndexes 获取所有指数数据
func (s *IndexService) GetAllIndexes(ctx context.Context) ([]*IndexData, error) {
	indexes := []string{"000001", "000300", "SPX", "NDX"}
	result := make([]*IndexData, 0, len(indexes))

	for _, code := range indexes {
		data, err := s.GetIndexData(ctx, code)
		if err != nil {
			continue
		}
		result = append(result, data)
	}

	return result, nil
}

// fetchIndexData 爬取指数数据
func (s *IndexService) fetchIndexData(url, code, name string) (*IndexData, error) {
	// 东方财富网的数据是通过API获取的，不是直接在HTML中
	// 使用他们的行情API
	var apiURL string

	switch code {
	case "000001":
		// 上证指数的API
		apiURL = "https://push2.eastmoney.com/api/qt/stock/get?secid=1.000001&fields=f43,f44,f45,f46,f47,f48,f49,f50,f51,f52,f57,f58,f60,f107,f152,f162,f169,f170,f171"
	case "000300":
		// 沪深300的API
		apiURL = "https://push2.eastmoney.com/api/qt/stock/get?secid=1.000300&fields=f43,f44,f45,f46,f47,f48,f49,f50,f51,f52,f57,f58,f60,f107,f152,f162,f169,f170,f171"
	case "SPX":
		// 标普500的API
		apiURL = "https://push2.eastmoney.com/api/qt/stock/get?secid=100.SPX&fields=f43,f44,f45,f46,f47,f48,f49,f50,f51,f52,f57,f58,f60,f107,f152,f162,f169,f170,f171"
	case "NDX":
		// 纳斯达克的API
		apiURL = "https://push2.eastmoney.com/api/qt/stock/get?secid=100.NDX&fields=f43,f44,f45,f46,f47,f48,f49,f50,f51,f52,f57,f58,f60,f107,f152,f162,f169,f170,f171"
	}

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
	req.Header.Set("Referer", url)

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	// 解析JSON响应
	// API返回格式: {"rc":0,"rt":4,"svr":...,"data":{"f43":465417,"f169":-4451,"f170":-95,...}}
	// f43: 最新价（需要除以100）
	// f169: 涨跌点（需要除以100）
	// f170: 涨跌幅（需要除以100）
	jsonStr := string(body)

	data := &IndexData{
		Code:       code,
		Name:       name,
		UpdateTime: time.Now().Format("2006-01-02 15:04:05"),
	}

	// 提取价格 f43 (需要除以100)
	priceRe := regexp.MustCompile(`"f43":([0-9.]+)`)
	if matches := priceRe.FindStringSubmatch(jsonStr); len(matches) > 1 {
		price, _ := strconv.ParseFloat(matches[1], 64)
		data.Price = price / 100
	}

	// 提取涨跌点 f169 (需要除以100)
	changeRe := regexp.MustCompile(`"f169":([+-]?[0-9.]+)`)
	if matches := changeRe.FindStringSubmatch(jsonStr); len(matches) > 1 {
		change, _ := strconv.ParseFloat(matches[1], 64)
		data.Change = change / 100
	}

	// 提取涨跌幅 f170 (需要除以100)
	changeRateRe := regexp.MustCompile(`"f170":([+-]?[0-9.]+)`)
	if matches := changeRateRe.FindStringSubmatch(jsonStr); len(matches) > 1 {
		rate, _ := strconv.ParseFloat(matches[1], 64)
		data.ChangeRate = rate / 100
	}

	return data, nil
}
