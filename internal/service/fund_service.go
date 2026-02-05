package service

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/PuerkitoBio/goquery"
)

// FundInfo 基金信息
type FundInfo struct {
	Code string `json:"code"` // 基金代码
	Name string `json:"name"` // 基金名称
	Type string `json:"type"` // 基金类型
	URL  string `json:"url"`  // 基金详情页 URL
}

// FundService 基金服务
type FundService struct {
	client *http.Client
}

// NewFundService 创建基金服务实例
func NewFundService() *FundService {
	return &FundService{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// GetFundInfo 获取基金信息
func (s *FundService) GetFundInfo(ctx context.Context, fundCode string) (*FundInfo, error) {
	url := fmt.Sprintf("https://fund.eastmoney.com/%s.html", fundCode)

	// 创建请求
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("创建请求失败: %w", err)
	}

	// 模拟浏览器请求头
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
	req.Header.Set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
	req.Header.Set("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8")
	req.Header.Set("Connection", "keep-alive")
	req.Header.Set("Referer", "https://fund.eastmoney.com/")

	// 发送请求
	resp, err := s.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("请求失败: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP 状态码错误: %d", resp.StatusCode)
	}

	// 读取响应体
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取响应失败: %w", err)
	}

	htmlContent := string(body)

	// 解析 HTML
	doc, err := goquery.NewDocumentFromReader(strings.NewReader(htmlContent))
	if err != nil {
		return nil, fmt.Errorf("解析 HTML 失败: %w", err)
	}

	fundInfo := &FundInfo{
		Code: fundCode,
		URL:  url,
	}

	// 提取基金名称
	title := doc.Find("title").Text()

	// 标题格式：基金名称(代码)基金净值_估值_行情走势—天天基金网
	if strings.Contains(title, "(") {
		parts := strings.Split(title, "(")
		if len(parts) > 0 {
			fundInfo.Name = strings.TrimSpace(parts[0])
		}
	}

	// 备用方法：从 JavaScript 变量提取
	if fundInfo.Name == "" {
		re := regexp.MustCompile(`var\s+fS_name\s*=\s*"([^"]+)"`)
		matches := re.FindStringSubmatch(htmlContent)
		if len(matches) > 1 {
			fundInfo.Name = matches[1]
		}
	}

	// 提取基金类型
	// 方法1: 从 JavaScript 变量提取
	reType := regexp.MustCompile(`var\s+fS_type\s*=\s*"([^"]+)"`)
	matchesType := reType.FindStringSubmatch(htmlContent)
	if len(matchesType) > 1 {
		fundInfo.Type = matchesType[1]
	}

	// 方法2: 从页面标题推断
	if fundInfo.Type == "" {
		if strings.Contains(title, "股票") || strings.Contains(title, "指数") || strings.Contains(title, "混合") {
			fundInfo.Type = "股票型"
		} else if strings.Contains(title, "债券") || strings.Contains(title, "纯债") || strings.Contains(title, "债") || strings.Contains(title, "货币") {
			fundInfo.Type = "债券型"
		}
	}

	// 方法3: 从基金名称推断
	if fundInfo.Type == "" && fundInfo.Name != "" {
		if strings.Contains(fundInfo.Name, "股票") || strings.Contains(fundInfo.Name, "指数") || strings.Contains(fundInfo.Name, "混合") {
			fundInfo.Type = "股票型"
		} else if strings.Contains(fundInfo.Name, "债券") || strings.Contains(fundInfo.Name, "纯债") || strings.Contains(fundInfo.Name, "债") || strings.Contains(fundInfo.Name, "货币") {
			fundInfo.Type = "债券型"
		}
	}

	if fundInfo.Name == "" {
		return nil, fmt.Errorf("未找到基金信息，请检查代码是否正确")
	}

	// 如果没有识别出类型，返回空字符串（前端会保留上一次的值）
	if fundInfo.Type == "" {
		fundInfo.Type = ""
	}

	return fundInfo, nil
}
