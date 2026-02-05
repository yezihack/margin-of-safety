<template>
  <div class="dashboard">
    <el-container>
      <el-header>
        <div class="header-content">
          <div class="header-left">
            <h1>Margin</h1>
            <span class="slogan">Margin of Safety</span>
          </div>
        </div>
      </el-header>
      
      <!-- 投资名言 -->
      <div class="quote-banner">
        <el-icon class="quote-icon"><ChatDotRound /></el-icon>
        <span class="quote-text">{{ currentQuote }}</span>
      </div>
      
      <el-main>
        <el-tabs v-model="activeTab" @tab-change="handleTabChange">
          <el-tab-pane label="资产管理" name="assets">
            <AssetManagement v-if="activeTab === 'assets'" />
          </el-tab-pane>
          <el-tab-pane label="组合分析" name="analysis">
            <PortfolioAnalysis v-if="activeTab === 'analysis'" ref="portfolioRef" />
          </el-tab-pane>
          <el-tab-pane label="再平衡" name="rebalance">
            <Rebalance v-if="activeTab === 'rebalance'" />
          </el-tab-pane>
          <el-tab-pane label="历史记录" name="history">
            <History v-if="activeTab === 'history'" />
          </el-tab-pane>
          <el-tab-pane label="设置" name="settings">
            <SettingsPanel v-if="activeTab === 'settings'" />
          </el-tab-pane>
        </el-tabs>
      </el-main>
      
      <!-- 指数行情栏 -->
      <el-footer height="auto" class="index-footer">
        <div class="index-bar">
          <div 
            v-for="index in indexes" 
            :key="index.code" 
            class="index-item"
            :class="{ 'index-up': index.change > 0, 'index-down': index.change < 0 }"
          >
            <span class="index-name">{{ index.name }}</span>
            <span class="index-price">{{ index.price.toFixed(2) }}</span>
            <span class="index-change">
              {{ index.change >= 0 ? '+' : '' }}{{ index.change.toFixed(2) }}
            </span>
            <span class="index-rate">
              {{ index.change_rate >= 0 ? '+' : '' }}{{ index.change_rate.toFixed(2) }}%
            </span>
          </div>
          <div class="index-update">
            <el-button 
              link 
              size="small" 
              @click="loadIndexes" 
              :loading="indexLoading"
              :icon="Refresh"
            >
              刷新
            </el-button>
            <span class="update-time" v-if="indexes.length > 0">
              {{ indexes[0].update_time }}
            </span>
          </div>
        </div>
      </el-footer>
    </el-container>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ChatDotRound, Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import AssetManagement from '../components/AssetManagement.vue'
import PortfolioAnalysis from '../components/PortfolioAnalysis.vue'
import Rebalance from '../components/Rebalance.vue'
import History from '../components/History.vue'
import SettingsPanel from '../components/SettingsPanel.vue'
import { GetAllIndexes, IsAuthenticated, Logout } from '../../wailsjs/go/main/App'

const router = useRouter()
const activeTab = ref('assets')
const portfolioRef = ref()
const currentQuote = ref('')
const indexes = ref([])
const indexLoading = ref(false)
const selectedIndexCodes = ref(['000001', '000300', 'SPX'])
let lockTimer = null // 锁屏定时器
let lockTimeout = 5 // 默认 5 分钟

// 投资名言列表
const quotes = [
  '从短期来看，市场是一台投票机；但从长期来看，它是一台称重机。',
  '价格是你付出的，价值才是你得到的。',
  '投资操作是基于全面分析、确保本金安全并获得适当回报的行为。不符合这些条件的操作就是投机。',
  '投机本身并非罪恶，但当普通人以为自己在投资，实际上却在投机时，就非常危险。',
  '安全边际是投资成功的基石。',
  '在别人贪婪时恐惧，在别人恐惧时贪婪。',
  '风险来自于你不知道自己在做什么。',
  '时间是优秀企业的朋友，是平庸企业的敌人。',
  '投资的第一条准则是不要赔钱；第二条准则是永远不要忘记第一条。',
  '成功的投资需要时间、纪律和耐心，无论你的才能或努力如何。',
  '真正的投资必须始终以安全边际为基础；没有安全边际的投资，不过是赌博。',
  '大多数投资者其实更适合做‘防御型投资者’——他们追求的是避免重大错误，而非击败市场。',
  '如果你不愿意持有一只股票十年，那就不要持有它十分钟。',
  '最大的投资风险不是股价波动，而是永久性资本损失。',
  '投资者的主要问题，甚至最大敌人，往往是他自己。',
  '投资艺术的精髓，在于用简单的方法应对复杂的市场。',
  '通过定期投资指数基金，一个什么都不懂的业余投资者往往能战胜大多数专业基金经理。',
  '聪明的投资者，不在于智力超群，而在于性格稳定。',
  '别希望自己每次都正确，如果犯了错，越快止损越好。',
  '牛市使人破产的方式，是让他相信自己很聪明。',
  '从短期来看，市场是一台投票机；但从长期来看，它是一台称重机。',
  '价格是你付出的，价值才是你得到的。',
  '投资操作是基于全面分析、确保本金安全并获得适当回报的行为。不符合这些条件的操作就是投机。',
  '投机本身并非罪恶，但当普通人以为自己在投资，实际上却在投机时，就非常危险。',
  '设想你拥有一家私营企业的股份，每天都有一个名叫“市场先生”的人来报价，他情绪极不稳定——有时极度乐观，愿高价买入；有时又极度悲观，愿低价卖出。你是否该听他的？',
  '你的优势在于：你可以选择不理睬他（市场先生），而不是被他牵着鼻子走。',
  '安全边际是投资成功的基石。',
  '真正的投资必须始终以安全边际为基础；没有安全边际的投资，不过是赌博。',
  '大多数投资者其实更适合做“防御型投资者”——他们追求的是避免重大错误，而非击败市场。',
  '如果你不愿意持有一只股票十年，那就不要持有它十分钟。',
  '最大的投资风险不是股价波动，而是永久性资本损失。',
  '投资者的主要问题，甚至最大敌人，往往是他自己。',
  '投资艺术的精髓，在于用简单的方法应对复杂的市场。',
  '聪明的投资者，不在于智力超群，而在于性格稳定。',
  '股票不是一张可以随意交易的纸片，而是企业所有权的一部分。',
  '投资者不必每次都正确，他只需要避免犯下代价高昂的错误。',
  '牛市使人破产的方式，是让他相信自己很聪明。',
  '如果你无法承受50%的下跌，那你就不该持有股票。',
  '不要因为股价上涨就认为你的判断正确，也不要因为下跌就认为你错了。唯一重要的是你的买入逻辑是否依然成立。',
  '多元化不是为了提高收益，而是为了承认自己的无知。',
  '一个公司的过去表现，并不能保证其未来结果；但若没有良好的历史记录，我们更不应对其未来抱有幻想。',
  '在投资中，“做些什么”的冲动往往是灾难的开始；而“什么都不做”常常是最明智的选择。',
  '当人们都急于买入时，你应该思考卖出；当人们恐慌抛售时，你才应考虑买入.',
  '投资的目标不是赚最多的钱，而是在睡得安稳的前提下，获得满意的回报。',
  '债券的安全性并非来自其名称，而是来自发行人的偿债能力。',
  '成长股投资看似诱人，但其估值往往已透支未来十年的乐观预期，一旦现实不及幻想，损失将极其惨重。',
  '投资不需要天才，只需要常识、纪律和耐心。聪明的投资者，不是预测风暴的人，而是造好方舟的人。'
]

// 随机选择一条名言
const getRandomQuote = () => {
  const randomIndex = Math.floor(Math.random() * quotes.length)
  currentQuote.value = quotes[randomIndex]
}

// 加载指数数据
const loadIndexes = async () => {
  indexLoading.value = true
  try {
    const allData = await GetAllIndexes()
    // 根据设置过滤显示的指数
    indexes.value = allData.filter(index => selectedIndexCodes.value.includes(index.code))
  } catch (error) {
    ElMessage.error('加载指数数据失败：' + error)
  } finally {
    indexLoading.value = false
  }
}

// 加载指数显示设置
const loadIndexSettings = () => {
  const saved = localStorage.getItem('selectedIndexes')
  if (saved) {
    try {
      selectedIndexCodes.value = JSON.parse(saved)
    } catch (e) {
      selectedIndexCodes.value = ['000001', '000300', 'SPX']
    }
  }
}

// 监听设置变化
const handleIndexSettingsChanged = () => {
  loadIndexSettings()
  loadIndexes()
}

// 处理标签页切换
const handleTabChange = async (tabName) => {
  if (tabName === 'analysis') {
    // 切换到组合分析时，等待渲染完成后调整图表大小
    await nextTick()
    setTimeout(() => {
      portfolioRef.value?.resizeCharts()
    }, 100)
    setTimeout(() => {
      portfolioRef.value?.resizeCharts()
    }, 300)
  }
}

// 检查认证状态
const checkAuth = async () => {
  try {
    const authenticated = await IsAuthenticated()
    if (!authenticated) {
      // 未登录，跳转到登录页
      router.replace('/login')
    }
  } catch (error) {
    console.error('检查登录状态失败:', error)
    router.replace('/login')
  }
}

// 重置锁屏定时器
const resetLockTimer = () => {
  // 清除旧定时器
  if (lockTimer) {
    clearTimeout(lockTimer)
    lockTimer = null
  }
  
  // 如果设置为 0，不启动定时器
  if (lockTimeout === 0) {
    return
  }
  
  // 启动新定时器
  lockTimer = setTimeout(async () => {
    try {
      await Logout()
      router.push('/login')
    } catch (error) {
      console.error('自动锁屏失败:', error)
    }
  }, lockTimeout * 60 * 1000) // 转换为毫秒
}

// 处理用户活动
const handleUserActivity = () => {
  resetLockTimer()
}

// 加载锁屏超时设置
const loadLockTimeout = () => {
  const saved = localStorage.getItem('lockTimeout')
  if (saved) {
    lockTimeout = parseInt(saved)
  }
  resetLockTimer()
}

// 处理锁屏超时变化
const handleLockTimeoutChanged = (event) => {
  lockTimeout = event.detail
  resetLockTimer()
}

onMounted(() => {
  // 检查登录状态
  checkAuth()
  
  getRandomQuote()
  loadIndexSettings()
  loadIndexes()
  loadLockTimeout()
  
  // 每5分钟自动刷新一次指数数据
  setInterval(loadIndexes, 5 * 60 * 1000)
  
  // 监听设置变化
  window.addEventListener('indexSettingsChanged', handleIndexSettingsChanged)
  window.addEventListener('lockTimeoutChanged', handleLockTimeoutChanged)
  
  // 监听用户活动，重置锁屏定时器
  window.addEventListener('mousemove', handleUserActivity)
  window.addEventListener('keydown', handleUserActivity)
  window.addEventListener('click', handleUserActivity)
  window.addEventListener('scroll', handleUserActivity)
})

onUnmounted(() => {
  window.removeEventListener('indexSettingsChanged', handleIndexSettingsChanged)
  window.removeEventListener('lockTimeoutChanged', handleLockTimeoutChanged)
  window.removeEventListener('mousemove', handleUserActivity)
  window.removeEventListener('keydown', handleUserActivity)
  window.removeEventListener('click', handleUserActivity)
  window.removeEventListener('scroll', handleUserActivity)
  
  // 清除定时器
  if (lockTimer) {
    clearTimeout(lockTimer)
  }
})
</script>

<style scoped>
.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.quote-banner {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 12px 30px;
  display: flex;
  align-items: center;
  gap: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  font-size: 14px;
  line-height: 1.6;
}

.quote-icon {
  font-size: 20px;
  flex-shrink: 0;
}

.quote-text {
  font-style: italic;
  letter-spacing: 0.5px;
}

.index-footer {
  background: #2c3e50;
  color: white;
  padding: 0;
  border-top: 2px solid #34495e;
}

.index-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 20px;
  gap: 30px;
}

.index-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 13px;
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 4px;
  transition: all 0.3s;
}

.index-item:hover {
  background: rgba(255, 255, 255, 0.1);
}

.index-name {
  font-weight: bold;
  color: #ecf0f1;
  min-width: 70px;
}

.index-price {
  font-size: 15px;
  font-weight: bold;
  min-width: 70px;
  text-align: right;
}

.index-change {
  min-width: 60px;
  text-align: right;
}

.index-rate {
  min-width: 60px;
  text-align: right;
  font-weight: bold;
}

.index-up {
  color: #67c23a;
}

.index-up .index-price {
  color: #67c23a;
}

.index-down {
  color: #f56c6c;
}

.index-down .index-price {
  color: #f56c6c;
}

.index-update {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-left: auto;
}

.update-time {
  font-size: 12px;
  color: #95a5a6;
}
</style>
