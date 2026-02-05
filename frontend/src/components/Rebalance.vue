<template>
  <div class="rebalance">
    <el-card>
      <template #header>
        <span>再平衡建议</span>
      </template>
      
      <el-row :gutter="20">
        <el-col :span="8">
          <el-card class="model-card" @click="selectModel(25)">
            <h3>🛡 极度防御型</h3>
            <p>股票：25% | 债券：75%</p>
            <small>适合新手、心理敏感型</small>
          </el-card>
        </el-col>
        <el-col :span="8">
          <el-card class="model-card" @click="selectModel(50)">
            <h3>⚖️ 平衡型</h3>
            <p>股票：50% | 债券：50%</p>
            <small>格雷厄姆推荐</small>
          </el-card>
        </el-col>
        <el-col :span="8">
          <el-card class="model-card" @click="selectModel(70)">
            <h3>⚔️ 进取型</h3>
            <p>股票：70% | 债券：30%</p>
            <small>适合有认知、有纪律</small>
          </el-card>
        </el-col>
      </el-row>

      <el-divider />

      <div class="custom-ratio">
        <h4>自定义比例</h4>
        <el-slider v-model="stockRatio" :min="0" :max="100" show-input @change="handleRatioChange" />
        <p>股票：{{ stockRatio }}% | 债券：{{ 100 - stockRatio }}%</p>
      </div>

      <el-divider />

      <div v-if="advice" class="advice">
        <h4>📊 当前资产状况</h4>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="总资产">
            <strong style="font-size: 18px; color: #409eff;">{{ advice.total_assets.toFixed(2) }}</strong> 元
          </el-descriptions-item>
           <el-descriptions-item label="当前比例">
            股票 <strong style="color: #e6a23c;">{{ advice.current_stock_ratio.toFixed(2) }}%</strong> | 
            债券 <strong style="color: #67c23a;">{{ advice.current_bond_ratio.toFixed(2) }}%</strong>
          </el-descriptions-item>
          <el-descriptions-item label="股票资产">
            {{ advice.current_stock_total.toFixed(2) }} 元
          </el-descriptions-item>
          <el-descriptions-item label="债券资产">
            {{ advice.current_bond_total.toFixed(2) }} 元
          </el-descriptions-item>         
        </el-descriptions>

        <el-divider />

        <h4>🎯 目标配置</h4>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="目标比例">
            股票 <strong style="color: #e6a23c;">{{ advice.target_stock_ratio.toFixed(2) }}%</strong> | 
            债券 <strong style="color: #67c23a;">{{ advice.target_bond_ratio.toFixed(2) }}%</strong>
          </el-descriptions-item>
          <el-descriptions-item label="目标金额">
            股票 {{ advice.target_stock_total.toFixed(2) }} 元 | 
            债券 {{ advice.target_bond_total.toFixed(2) }} 元
          </el-descriptions-item>
        </el-descriptions>

        <el-divider />

        <h4>💡 再平衡建议</h4>
        <el-alert 
          :title="advice.need_rebalance ? '需要再平衡' : '✅ 当前配置合理，无需调整'" 
          :type="advice.need_rebalance ? 'warning' : 'success'"
          :closable="false"
          style="margin-bottom: 15px;"
        />
        
        <div v-if="advice.need_rebalance" class="advice-detail">
          <el-card shadow="hover" style="background: #fef0f0; border-color: #f56c6c;">
            <h3 style="margin-top: 0; color: #f56c6c;">
              <el-icon><TrendCharts /></el-icon>
              操作步骤
            </h3>
            
            <!-- 股票操作 -->
            <div v-if="advice.stock_adjust !== 0" style="margin-bottom: 15px;">
              <div v-if="advice.stock_adjust > 0" style="padding: 12px; background: #e1f3d8; border-left: 4px solid #67c23a; border-radius: 4px;">
                <p style="margin: 0; font-size: 16px;">
                  <strong style="color: #67c23a;">📈 买入股票：</strong>
                  <span style="font-size: 20px; font-weight: bold; color: #67c23a;">{{ advice.stock_adjust.toFixed(2) }}</span> 元
                </p>
                <p style="margin: 8px 0 0 0; font-size: 14px; color: #606266;">
                  原因：当前股票比例 {{ advice.current_stock_ratio.toFixed(2) }}% 低于目标 {{ advice.target_stock_ratio.toFixed(2) }}%
                </p>
              </div>
              <div v-else style="padding: 12px; background: #fef0f0; border-left: 4px solid #f56c6c; border-radius: 4px;">
                <p style="margin: 0; font-size: 16px;">
                  <strong style="color: #f56c6c;">📉 卖出股票：</strong>
                  <span style="font-size: 20px; font-weight: bold; color: #f56c6c;">{{ Math.abs(advice.stock_adjust).toFixed(2) }}</span> 元
                </p>
                <p style="margin: 8px 0 0 0; font-size: 14px; color: #606266;">
                  原因：当前股票比例 {{ advice.current_stock_ratio.toFixed(2) }}% 高于目标 {{ advice.target_stock_ratio.toFixed(2) }}%
                </p>
              </div>
            </div>

            <!-- 债券操作 -->
            <div v-if="advice.bond_adjust !== 0">
              <div v-if="advice.bond_adjust > 0" style="padding: 12px; background: #e1f3d8; border-left: 4px solid #67c23a; border-radius: 4px;">
                <p style="margin: 0; font-size: 16px;">
                  <strong style="color: #67c23a;">📈 买入债券：</strong>
                  <span style="font-size: 20px; font-weight: bold; color: #67c23a;">{{ advice.bond_adjust.toFixed(2) }}</span> 元
                </p>
                <p style="margin: 8px 0 0 0; font-size: 14px; color: #606266;">
                  原因：当前债券比例 {{ advice.current_bond_ratio.toFixed(2) }}% 低于目标 {{ advice.target_bond_ratio.toFixed(2) }}%
                </p>
              </div>
              <div v-else style="padding: 12px; background: #fef0f0; border-left: 4px solid #f56c6c; border-radius: 4px;">
                <p style="margin: 0; font-size: 16px;">
                  <strong style="color: #f56c6c;">📉 卖出债券：</strong>
                  <span style="font-size: 20px; font-weight: bold; color: #f56c6c;">{{ Math.abs(advice.bond_adjust).toFixed(2) }}</span> 元
                </p>
                <p style="margin: 8px 0 0 0; font-size: 14px; color: #606266;">
                  原因：当前债券比例 {{ advice.current_bond_ratio.toFixed(2) }}% 高于目标 {{ advice.target_bond_ratio.toFixed(2) }}%
                </p>
              </div>
            </div>

            <el-divider />

            <div style="background: #ecf5ff; padding: 12px; border-radius: 4px;">
              <p style="margin: 0; font-size: 14px; color: #409eff;">
                <strong>💡 操作说明：</strong>
              </p>
              <p style="margin: 8px 0 0 0; font-size: 13px; color: #606266; line-height: 1.6;">
                {{ getOperationTip() }}
              </p>
            </div>

            <el-divider />

            <div style="text-align: center;">
              <el-button type="success" size="large" @click="handleRebalanced" :icon="Check">
                ✅ 我已完成再平衡
              </el-button>
            </div>
          </el-card>
        </div>
      </div>
    </el-card>

    <!-- 再平衡历史记录 -->
    <el-card style="margin-top: 20px;">
      <template #header>
        <span>📜 再平衡历史记录</span>
      </template>

      <!-- 历史趋势图表（简洁版） -->
      <div v-if="history.length > 0" style="margin-bottom: 20px;">
        <div ref="chartRef" style="width: 100%; height: 300px;"></div>
      </div>

      <el-table :data="history" style="width: 100%" v-loading="historyLoading">
        <el-table-column prop="created_at" label="平衡时间" width="180" />
        <el-table-column label="平衡前比例" width="150">
          <template #default="scope">
            <el-tag type="warning">股 {{ scope.row.stock_ratio.toFixed(2) }}%</el-tag>
            <el-tag type="success" style="margin-left: 5px;">债 {{ scope.row.bond_ratio.toFixed(2) }}%</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="目标比例" width="150">
          <template #default="scope">
            <el-tag type="warning">股 {{ scope.row.target_stock_ratio.toFixed(2) }}%</el-tag>
            <el-tag type="success" style="margin-left: 5px;">债 {{ scope.row.target_bond_ratio.toFixed(2) }}%</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="total_amount" label="总金额" width="120">
          <template #default="scope">
            {{ scope.row.total_amount.toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column label="距今时间" width="150">
          <template #default="scope">
            {{ getTimeSince(scope.row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column prop="note" label="备注" show-overflow-tooltip />
        <el-table-column label="操作" width="100">
          <template #default="scope">
            <el-button link type="danger" @click="handleDeleteRecord(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div v-if="history.length === 0 && !historyLoading" style="text-align: center; padding: 40px; color: #909399;">
        <el-icon style="font-size: 48px; margin-bottom: 10px;"><DocumentCopy /></el-icon>
        <p>暂无再平衡记录</p>
      </div>
    </el-card>

    <!-- 记录再平衡对话框 -->
    <el-dialog v-model="recordDialogVisible" title="记录再平衡" width="500px">
      <el-form :model="recordForm" label-width="100px">
        <el-form-item label="备注">
          <el-input 
            v-model="recordForm.note" 
            type="textarea" 
            :rows="3"
            placeholder="可选：记录本次再平衡的原因或心得"
          />
        </el-form-item>
        <el-form-item>
          <el-alert 
            title="将记录当前的资产配置和目标比例" 
            type="info" 
            :closable="false"
            show-icon
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="recordDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveRecord" :loading="saving">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { TrendCharts, Check, DocumentCopy } from '@element-plus/icons-vue'
import { GetRebalanceAdvice, SaveRebalance, GetRebalanceHistory, DeleteRebalance } from '../../wailsjs/go/main/App'
import * as echarts from 'echarts'

const stockRatio = ref(50)
const advice = ref(null)
const history = ref([])
const historyLoading = ref(false)
const recordDialogVisible = ref(false)
const saving = ref(false)
const recordForm = ref({
  note: ''
})
const chartRef = ref(null)
let chartInstance = null

// 计算距今时间
const getTimeSince = (dateStr) => {
  const date = new Date(dateStr)
  const now = new Date()
  const diff = now - date
  
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
  
  if (days > 0) {
    return `${days} 天前`
  } else if (hours > 0) {
    return `${hours} 小时前`
  } else if (minutes > 0) {
    return `${minutes} 分钟前`
  } else {
    return '刚刚'
  }
}

// 获取操作提示
const getOperationTip = () => {
  if (!advice.value) return ''
  
  if (advice.value.stock_adjust > 0) {
    // 需要买入股票，卖出债券
    return `卖出 ${Math.abs(advice.value.bond_adjust).toFixed(2)} 元债券，用这笔钱买入股票，实现"低买高卖"的自动再平衡。`
  } else if (advice.value.stock_adjust < 0) {
    // 需要卖出股票，买入债券
    return `卖出 ${Math.abs(advice.value.stock_adjust).toFixed(2)} 元股票，用这笔钱买入债券，锁定收益并降低风险。`
  }
  return ''
}

const selectModel = (ratio) => {
  stockRatio.value = ratio
  handleRatioChange()
}

const handleRatioChange = async () => {
  try {
    advice.value = await GetRebalanceAdvice(stockRatio.value)
  } catch (error) {
    ElMessage.error('计算失败：' + error)
  }
}

// 加载历史记录
const loadHistory = async () => {
  historyLoading.value = true
  try {
    history.value = await GetRebalanceHistory()
    // 加载完成后初始化图表
    await nextTick()
    initChart()
  } catch (error) {
    ElMessage.error('加载历史记录失败：' + error)
  } finally {
    historyLoading.value = false
  }
}

// 初始化图表（简洁版）
const initChart = () => {
  if (!chartRef.value || history.value.length === 0) return
  
  // 如果图表已存在，先销毁
  if (chartInstance) {
    chartInstance.dispose()
  }
  
  // 创建图表实例
  chartInstance = echarts.init(chartRef.value)
  
  // 准备数据（按时间正序排列）
  const sortedHistory = [...history.value].reverse()
  const dates = sortedHistory.map(item => {
    const date = new Date(item.created_at)
    return `${date.getMonth() + 1}/${date.getDate()}`
  })
  const stockRatios = sortedHistory.map(item => item.stock_ratio)
  const bondRatios = sortedHistory.map(item => item.bond_ratio)
  
  // 配置图表（简洁版）
  const option = {
    title: {
      text: '资产配置比例变化',
      left: 'center',
      textStyle: {
        fontSize: 14
      }
    },
    tooltip: {
      trigger: 'axis',
      formatter: function(params) {
        let result = `<strong>${params[0].axisValue}</strong><br/>`
        params.forEach(item => {
          result += `${item.marker} ${item.seriesName}: ${item.value.toFixed(2)}%<br/>`
        })
        return result
      }
    },
    legend: {
      data: ['股票', '债券'],
      top: 30
    },
    grid: {
      left: '50px',
      right: '30px',
      bottom: '30px',
      top: 60
    },
    xAxis: {
      type: 'category',
      data: dates
    },
    yAxis: {
      type: 'value',
      name: '比例 (%)',
      min: 0,
      max: 100,
      axisLabel: {
        formatter: '{value}%'
      }
    },
    series: [
      {
        name: '股票',
        type: 'line',
        data: stockRatios,
        smooth: true,
        lineStyle: {
          width: 3,
          color: '#ff6b6b'
        },
        itemStyle: {
          color: '#ff6b6b'
        },
        symbol: 'circle',
        symbolSize: 6
      },
      {
        name: '债券',
        type: 'line',
        data: bondRatios,
        smooth: true,
        lineStyle: {
          width: 3,
          color: '#4ecdc4'
        },
        itemStyle: {
          color: '#4ecdc4'
        },
        symbol: 'circle',
        symbolSize: 6
      }
    ]
  }
  
  chartInstance.setOption(option)
  
  // 监听窗口大小变化
  window.addEventListener('resize', handleResize)
}

// 处理窗口大小变化
const handleResize = () => {
  if (chartInstance) {
    chartInstance.resize()
  }
}

// 监听历史记录变化，更新图表
watch(() => history.value.length, () => {
  if (history.value.length > 0) {
    nextTick(() => {
      initChart()
    })
  }
})

// 处理"已完成再平衡"
const handleRebalanced = () => {
  recordDialogVisible.value = true
  recordForm.value.note = ''
}

// 保存再平衡记录
const handleSaveRecord = async () => {
  if (!advice.value) {
    ElMessage.warning('请先计算再平衡建议')
    return
  }

  saving.value = true
  try {
    await SaveRebalance(
      advice.value.current_stock_ratio,
      advice.value.current_bond_ratio,
      advice.value.total_assets,
      advice.value.current_stock_total,
      advice.value.current_bond_total,
      advice.value.target_stock_ratio,
      advice.value.target_bond_ratio,
      recordForm.value.note
    )
    
    ElMessage.success('再平衡记录已保存')
    recordDialogVisible.value = false
    await loadHistory()
  } catch (error) {
    ElMessage.error('保存失败：' + error)
  } finally {
    saving.value = false
  }
}

// 删除记录
const handleDeleteRecord = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除这条再平衡记录吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await DeleteRebalance(row.id)
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

onUnmounted(() => {
  // 清理图表实例
  if (chartInstance) {
    chartInstance.dispose()
    chartInstance = null
  }
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.model-card {
  cursor: pointer;
  transition: all 0.3s;
}
.model-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}
</style>
