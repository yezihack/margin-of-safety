package main

import (
	"context"
	"fmt"
	"margin/internal/service"
)

func main() {
	// 创建服务实例（不需要数据库）
	indexService := service.NewIndexService(nil)
	ctx := context.Background()

	fmt.Println("=== 测试指数爬虫 ===\n")

	// 测试上证指数
	fmt.Println("1. 上证指数 (000001)")
	data0, err := indexService.GetIndexData(ctx, "000001")
	if err != nil {
		fmt.Printf("   错误: %v\n", err)
	} else {
		printIndexData(data0)
	}

	fmt.Println()

	// 测试沪深300
	fmt.Println("2. 沪深300 (000300)")
	data1, err := indexService.GetIndexData(ctx, "000300")
	if err != nil {
		fmt.Printf("   错误: %v\n", err)
	} else {
		printIndexData(data1)
	}

	fmt.Println()

	// 测试标普500
	fmt.Println("3. 标普500 (SPX)")
	data2, err := indexService.GetIndexData(ctx, "SPX")
	if err != nil {
		fmt.Printf("   错误: %v\n", err)
	} else {
		printIndexData(data2)
	}

	fmt.Println()

	// 测试纳斯达克
	fmt.Println("4. 纳斯达克 (NDX)")
	data3, err := indexService.GetIndexData(ctx, "NDX")
	if err != nil {
		fmt.Printf("   错误: %v\n", err)
	} else {
		printIndexData(data3)
	}

	fmt.Println()

	// 测试获取所有指数
	fmt.Println("5. 获取所有指数")
	allIndexes, err := indexService.GetAllIndexes(ctx)
	if err != nil {
		fmt.Printf("   错误: %v\n", err)
	} else {
		fmt.Printf("   成功获取 %d 个指数\n", len(allIndexes))
	}
}

func printIndexData(data *service.IndexData) {
	fmt.Printf("   名称: %s\n", data.Name)
	fmt.Printf("   点位: %.2f\n", data.Price)
	fmt.Printf("   涨跌: %.2f\n", data.Change)
	fmt.Printf("   涨跌幅: %.2f%%\n", data.ChangeRate)
	fmt.Printf("   更新时间: %s\n", data.UpdateTime)
}
