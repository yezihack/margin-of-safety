package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/PuerkitoBio/goquery"
)

// FundInfo 基金信息
type FundInfo struct {
	Code string // 基金代码
	Name string // 基金名称
	Type string // 基金类型
}

// FundCrawler 基金爬虫
type FundCrawler struct {
	client *http.Client
	debug  bool
}

// NewFundCrawler 创建爬虫实例
func NewFundCrawler(debug bool) *FundCrawler {
	return &FundCrawler{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		debug: debug,
	}
}

// GetFundInfo 获取基金信息
func (c *FundCrawler) GetFundInfo(fundCode string) (*FundInfo, error) {
	url := fmt.Sprintf("https://fund.eastmoney.com/%s.html", fundCode)

	if c.debug {
		fmt.Printf("请求 URL: %s\n", url)
	}

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
	resp, err := c.client.Do(req)
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

	if c.debug {
		fmt.Printf("响应长度: %d 字节\n", len(htmlContent))

		// 查找包含"基金类型"的所有文本
		if idx := strings.Index(htmlContent, "基金类型"); idx > 0 {
			start := idx - 100
			if start < 0 {
				start = 0
			}
			end := idx + 200
			if end > len(htmlContent) {
				end = len(htmlContent)
			}
			fmt.Printf("\n找到'基金类型'关键词，上下文:\n%s\n\n", htmlContent[start:end])
		}
	}

	// 解析 HTML
	doc, err := goquery.NewDocumentFromReader(strings.NewReader(htmlContent))
	if err != nil {
		return nil, fmt.Errorf("解析 HTML 失败: %w", err)
	}

	fundInfo := &FundInfo{
		Code: fundCode,
	}

	// 提取基金名称
	// 方法1: 从 title 标签提取
	title := doc.Find("title").Text()
	if c.debug {
		fmt.Printf("页面标题: %s\n", title)
	}

	// 标题格式：基金名称(代码)基金净值_估值_行情走势—天天基金网
	if strings.Contains(title, "(") {
		parts := strings.Split(title, "(")
		if len(parts) > 0 {
			fundInfo.Name = strings.TrimSpace(parts[0])
		}
	}

	// 方法2: 使用正则表达式从 HTML 中提取
	if fundInfo.Name == "" {
		re := regexp.MustCompile(`var\s+fS_name\s*=\s*"([^"]+)"`)
		matches := re.FindStringSubmatch(htmlContent)
		if len(matches) > 1 {
			fundInfo.Name = matches[1]
		}
	}

	// 提取基金类型（详细类型，如"债券型-长债"）
	// 方法1: 从 JavaScript 变量提取（最准确）
	reType := regexp.MustCompile(`var\s+fS_type\s*=\s*"([^"]+)"`)
	matchesType := reType.FindStringSubmatch(htmlContent)
	if len(matchesType) > 1 {
		fundInfo.Type = matchesType[1]
		if c.debug {
			fmt.Printf("从 JS 变量提取类型: %s\n", fundInfo.Type)
		}
	}

	// 方法2: 从 HTML 表格中提取
	if fundInfo.Type == "" {
		doc.Find(".infoOfFund table tbody tr").Each(func(i int, s *goquery.Selection) {
			th := strings.TrimSpace(s.Find("th").Text())
			td := strings.TrimSpace(s.Find("td").Text())

			if c.debug && th != "" {
				fmt.Printf("表格行 %d: %s = %s\n", i, th, td)
			}

			if strings.Contains(th, "基金类型") {
				fundInfo.Type = td
			}
		})
	}

	// 方法3: 从 dataItem 区域提取
	if fundInfo.Type == "" {
		doc.Find(".dataOfFund .dataItem").Each(func(i int, s *goquery.Selection) {
			label := strings.TrimSpace(s.Find("label").Text())
			span := strings.TrimSpace(s.Find("span").Text())

			if c.debug && label != "" {
				fmt.Printf("dataItem %d: %s = %s\n", i, label, span)
			}

			if strings.Contains(label, "基金类型") {
				fundInfo.Type = span
			}
		})
	}

	// 方法4: 尝试其他可能的选择器
	if fundInfo.Type == "" {
		doc.Find(".fundInfoItem").Each(func(i int, s *goquery.Selection) {
			label := strings.TrimSpace(s.Find(".label").Text())
			value := strings.TrimSpace(s.Find(".value").Text())

			if c.debug && label != "" {
				fmt.Printf("fundInfoItem %d: %s = %s\n", i, label, value)
			}

			if strings.Contains(label, "类型") {
				fundInfo.Type = value
			}
		})
	}

	if c.debug {
		fmt.Printf("最终提取结果 - 名称: %s, 类型: %s\n", fundInfo.Name, fundInfo.Type)
	}

	if fundInfo.Name == "" {
		return nil, fmt.Errorf("未找到基金名称")
	}

	// 如果没有类型，设置为"未知"
	if fundInfo.Type == "" {
		fundInfo.Type = "未知"
	}

	return fundInfo, nil
}

func main() {
	// 启用调试模式
	crawler := NewFundCrawler(true)

	// 测试基金代码
	testCode := "050027"

	fmt.Println("========== 天天基金爬虫测试 ==========\n")
	fmt.Printf("正在查询基金: %s\n", testCode)
	fmt.Println(strings.Repeat("-", 60))

	info, err := crawler.GetFundInfo(testCode)
	if err != nil {
		log.Fatalf("❌ 查询失败: %v\n", err)
	}

	fmt.Printf("\n✓ 查询成功!\n")
	fmt.Printf("  基金代码: %s\n", info.Code)
	fmt.Printf("  基金名称: %s\n", info.Name)
	fmt.Printf("  基金类型: %s\n", info.Type)
	fmt.Println()

	fmt.Println(strings.Repeat("=", 60))
	fmt.Println("测试完成")
}
