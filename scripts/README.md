# 基金信息爬虫

## 功能说明

从天天基金网（fund.eastmoney.com）爬取基金信息，包括：
- 基金代码
- 基金名称
- 基金类型（股票型、债券型、混合型、货币型等）

## 使用方法

### 运行测试
```bash
go run scripts/fund_crawler.go
```

### 代码示例

```go
package main

import (
    "fmt"
    "log"
)

func main() {
    // 创建爬虫实例（debug=false 关闭调试输出）
    crawler := NewFundCrawler(false)
    
    // 查询单个基金
    info, err := crawler.GetFundInfo("050027")
    if err != nil {
        log.Fatal(err)
    }
    
    fmt.Printf("基金代码: %s\n", info.Code)
    fmt.Printf("基金名称: %s\n", info.Name)
    fmt.Printf("基金类型: %s\n", info.Type)
}
```

## 技术特点

### 1. 模拟浏览器请求
- 设置完整的 User-Agent 和请求头
- 避免被反爬虫机制拦截

### 2. 多种解析方法
- **名称提取**：
  - 从 `<title>` 标签提取
  - 从 JavaScript 变量 `fS_name` 提取
  - 从 meta 标签提取

- **类型识别**：
  - 从页面标题关键词推断（股票、债券、混合等）
  - 从基金名称关键词推断
  - 从 JavaScript 变量提取

### 3. 智能类型识别
支持识别以下基金类型：
- 股票型
- 债券型
- 混合型
- 货币型
- 指数型
- QDII
- FOF

## 测试结果

```
✓ 050027 - 博时信用债纯债债券A - 债券型
✓ 000001 - 华夏成长混合 - 混合型
✓ 110022 - 易方达消费行业股票 - 股票型
```

## 注意事项

1. **请求频率**：建议每次请求间隔 2 秒以上，避免被封 IP
2. **错误处理**：网络异常或页面结构变化可能导致解析失败
3. **类型推断**：部分基金类型通过关键词推断，可能不完全准确

## 依赖

```bash
go get github.com/PuerkitoBio/goquery
```

## 后续集成

可以将此爬虫集成到主应用中：
1. 在添加资产时，输入基金代码自动获取名称和类型
2. 批量导入基金信息
3. 定期更新基金数据
