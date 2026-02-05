package main

import (
	"fmt"
	"io"
	"net/http"
	"time"
)

func main() {
	url := "https://quote.eastmoney.com/zs000300.html"

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	html := string(body)

	// 打印前2000个字符
	if len(html) > 2000 {
		fmt.Println(html[:2000])
	} else {
		fmt.Println(html)
	}
}
