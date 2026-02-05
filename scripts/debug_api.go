package main

import (
	"fmt"
	"io"
	"net/http"
	"time"
)

func main() {
	url := "https://push2.eastmoney.com/api/qt/stock/get?secid=1.000300&fields=f43,f44,f45,f46,f47,f48,f49,f50,f51,f52,f57,f58,f60,f107,f152,f162,f169,f170,f171"

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
	fmt.Println(string(body))
}
