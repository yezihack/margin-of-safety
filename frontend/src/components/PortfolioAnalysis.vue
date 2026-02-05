<template>
  <div class="portfolio-analysis">
    <el-row :gutter="20">
      <!-- 饼图 -->
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>资产配置比例</span>
              <el-button size="small" @click="refreshData" :loading="loading">
                <el-icon><Refresh /></el-icon>
                刷新
              </el-button>
            </div>
          </template>
          <div ref="pieChartRef" style="width: 100%; height: 500px; min-height: 500px;"></div>
        </el-card>
      </el-col>

      <!-- 柱状图 -->
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>资产金额对比</span>
            </div>
          </template>
          <div ref="barChartRef" style="width: 100%; height: 500px; min-height: 500px;"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, defineExpose } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { GetPortfolioRatio, GetAssets } from '../../wailsjs/go/main/App'

const pieChartRef = ref()
const barChartRef = ref()
const loading = ref(false)

let pieChart = null
let barChart = null

// 初始化饼图
const initPieChart = async () => {
  await nextTick() // 等待 DOM 更新
  
  const ratio = await GetPortfolioRatio()
  
  if (!pieChart && pieChartRef.value) {
    pieChart = echarts.init(pieChartRef.value)
  }
  
  if (!pieChart) return
  
  const option = {
    title: {
      text: '当前配置比例',
      left: 'center',
      top: 20,
      textStyle: {
        fontSize: 20,
        fontWeight: 'bold',
        color: '#333'
      }
    },
    tooltip: {
      trigger: 'item',
      formatter: (params) => {
        return `${params.name}: ${params.value.toFixed(2)}%`
      },
      confine: true,
      backgroundColor: 'rgba(50, 50, 50, 0.9)',
      borderColor: '#333',
      borderWidth: 1,
      textStyle: {
        color: '#fff',
        fontSize: 16
      },
      padding: [12, 20]
    },
    series: [
      {
        name: '资产配置',
        type: 'pie',
        radius: '60%',
        center: ['50%', '55%'],
        data: [
          { 
            value: ratio.stock, 
            name: '股票',
            itemStyle: { 
              color: '#5470c6',
              borderColor: '#fff',
              borderWidth: 3
            }
          },
          { 
            value: ratio.bond, 
            name: '债券',
            itemStyle: { 
              color: '#91cc75',
              borderColor: '#fff',
              borderWidth: 3
            }
          }
        ],
        label: {
          show: true,
          position: 'outside',
          formatter: (params) => {
            return `${params.name}\n${params.value.toFixed(2)}%`
          },
          fontSize: 16,
          fontWeight: 'bold',
          color: '#333',
          lineHeight: 22
        },
        labelLine: {
          show: true,
          length: 25,
          length2: 15,
          lineStyle: {
            width: 2
          }
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 18,
            fontWeight: 'bold'
          },
          itemStyle: {
            shadowBlur: 20,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }
    ]
  }
  
  pieChart.setOption(option, true)
  // 强制调整大小
  setTimeout(() => {
    pieChart?.resize()
  }, 100)
}

// 初始化柱状图
const initBarChart = async () => {
  await nextTick() // 等待 DOM 更新
  
  const assets = await GetAssets()
  
  if (!barChart && barChartRef.value) {
    barChart = echarts.init(barChartRef.value)
  }
  
  if (!barChart) return
  
  // 计算股票和债券总额
  let stockTotal = 0
  let bondTotal = 0
  
  assets.forEach(asset => {
    if (asset.type === 'stock') {
      stockTotal += asset.amount
    } else {
      bondTotal += asset.amount
    }
  })
  
  const option = {
    title: {
      text: '资产金额（元）',
      left: 'center',
      top: 20,
      textStyle: {
        fontSize: 20,
        fontWeight: 'bold',
        color: '#333'
      }
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      },
      formatter: (params) => {
        const value = params[0].value.toFixed(2)
        return `${params[0].name}: ${value} 元`
      },
      backgroundColor: 'rgba(50, 50, 50, 0.9)',
      borderColor: '#333',
      borderWidth: 1,
      textStyle: {
        color: '#fff',
        fontSize: 16
      },
      padding: [12, 20]
    },
    grid: {
      left: '10%',
      right: '10%',
      top: '25%',
      bottom: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: ['股票', '债券'],
      axisLabel: {
        fontSize: 16,
        fontWeight: 'bold',
        color: '#333'
      },
      axisLine: {
        lineStyle: {
          color: '#ddd',
          width: 2
        }
      }
    },
    yAxis: {
      type: 'value',
      name: '金额（元）',
      nameTextStyle: {
        fontSize: 14,
        color: '#666'
      },
      axisLabel: {
        fontSize: 14,
        color: '#666',
        formatter: '{value}'
      },
      splitLine: {
        lineStyle: {
          color: '#f0f0f0'
        }
      }
    },
    series: [
      {
        name: '金额',
        type: 'bar',
        data: [
          {
            value: stockTotal,
            itemStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#5470c6' },
                { offset: 1, color: '#7b8fd6' }
              ]),
              borderRadius: [8, 8, 0, 0]
            }
          },
          {
            value: bondTotal,
            itemStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#91cc75' },
                { offset: 1, color: '#a8d88f' }
              ]),
              borderRadius: [8, 8, 0, 0]
            }
          }
        ],
        barWidth: '50%',
        label: {
          show: true,
          position: 'top',
          formatter: (params) => {
            return params.value.toFixed(2) + ' 元'
          },
          fontSize: 16,
          fontWeight: 'bold',
          color: '#333'
        },
        emphasis: {
          itemStyle: {
            shadowBlur: 20,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }
    ]
  }
  
  barChart.setOption(option, true)
  // 强制调整大小
  setTimeout(() => {
    barChart?.resize()
  }, 100)
}

// 刷新数据
const refreshData = async () => {
  loading.value = true
  try {
    await Promise.all([initPieChart(), initBarChart()])
  } finally {
    loading.value = false
  }
}

// 调整图表大小
const resizeCharts = () => {
  if (pieChart) {
    pieChart.resize()
  }
  if (barChart) {
    barChart.resize()
  }
}

// 初始化所有图表
const initCharts = async () => {
  await nextTick()
  // 延迟初始化，确保容器完全渲染
  setTimeout(async () => {
    await refreshData()
    // 多次调整大小确保正确显示
    setTimeout(resizeCharts, 50)
    setTimeout(resizeCharts, 200)
    setTimeout(resizeCharts, 500)
  }, 100)
  
  // 响应式调整
  window.addEventListener('resize', resizeCharts)
}

onMounted(() => {
  initCharts()
})

// 暴露方法给父组件调用
defineExpose({
  resizeCharts
})
</script>

<style scoped>
.portfolio-analysis {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
}
</style>
