package main

import "time"

// Version 软件版本号
const Version = "1.0.0"

// BuildDate 构建日期（编译时自动生成）
var BuildDate = time.Now().Format("2006-01-02")

// GitCommit Git 提交哈希（构建时注入）
var GitCommit = "unknown"
