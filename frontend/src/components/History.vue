<template>
  <div class="history">
    <el-card>
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span>历史记录</span>
          <el-button type="primary" @click="handleSnapshot">保存快照</el-button>
        </div>
      </template>
      
      <div ref="chartRef" style="width: 100%; height: 400px; margin-bottom: 20px"></div>
      
      <el-table :data="history" style="width: 100%" border>
        <el-table-column prop="created_at" label="日期" width="200">
          <template #default="scope">
            {{ new Date(scope.row.created_at).toLocaleString() }}
          </template>
        </el-table-column>
        <el-table-column label="总金额" width="150">
          <template #default="scope">
            {{ (scope.row.stock_total + scope.row.bond_total).toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column prop="stock_total" label="股票总额" width="150">
          <template #default="scope">
            {{ scope.row.stock_total.toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column prop="bond_total" label="债券总额" width="150">
          <template #default="scope">
            {{ scope.row.bond_total.toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column prop="stock_ratio" label="股票比例" width="120">
          <template #default="scope">
            {{ scope.row.stock_ratio.toFixed(2) }}%
          </template>
        </el-table-column>
        <el-table-column prop="bond_ratio" label="债券比例" width="120">
          <template #default="scope">
            {{ scope.row.bond_ratio.toFixed(2) }}%
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="scope">
            <el-button link type="danger" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import * as echarts from 'echarts'
import { ElMessage, ElMessageBox } from 'element-plus'
import { GetHistory, SaveSnapshot, DeleteHistory } from '../../wailsjs/go/main/App'

const chartRef = ref()
const history = ref([])

const loadHistory = async () => {
  try {
    history.value = await GetHistory()
    initChart()
  } catch (error) {
    ElMessage.error('加载失败：' + error)
  }
}

const initChart = () => {
  if (!history.value.length) return
  
  const chart = echarts.init(chartRef.value)
  const dates = history.value.map(h => new Date(h.created_at).toLocaleDateString())
  const stockRatios = history.value.map(h => h.stock_ratio)
  const bondRatios = history.value.map(h => h.bond_ratio)
  
  const option = {
    title: {
      text: '资产配置变化趋势',
      left: 'center'
    },
    tooltip: {
      trigger: 'axis'
    },
    legend: {
      data: ['股票比例', '债券比例'],
      top: 30
    },
    xAxis: {
      type: 'category',
      data: dates
    },
    yAxis: {
      type: 'value',
      axisLabel: {
        formatter: '{value}%'
      }
    },
    series: [
      {
        name: '股票比例',
        type: 'line',
        data: stockRatios,
        smooth: true
      },
      {
        name: '债券比例',
        type: 'line',
        data: bondRatios,
        smooth: true
      }
    ]
  }
  
  chart.setOption(option)
}

const handleSnapshot = async () => {
  try {
    await SaveSnapshot()
    ElMessage.success('快照保存成功')
    await loadHistory()
  } catch (error) {
    ElMessage.error('保存失败：' + error)
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除 ${new Date(row.created_at).toLocaleString()} 的历史记录吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await DeleteHistory(row.id)
    ElMessage.success('删除成功')
    await loadHistory()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败：' + error)
    }
  }
}

onMounted(() => {
  loadHistory()
})
</script>
