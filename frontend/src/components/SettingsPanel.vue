<template>
  <div class="settings-container">
    <!-- 左侧内容区 -->
    <div class="settings-panel" ref="panelRef" @scroll="handleScroll">
      <!-- 滚动提示指示器 -->
      <transition name="fade">
        <div v-if="showScrollHint" class="scroll-hint" @click="scrollToNext">
          <el-icon class="scroll-icon"><ArrowDown /></el-icon>
          <span>向下滚动查看更多</span>
        </div>
      </transition>

    <el-card style="margin-top: 20px;" id="section-indexes">
      <template #header>
        <span>指数显示设置</span>
      </template>
      
      <el-form label-width="120px">
        <el-form-item label="显示指数">
          <el-checkbox-group v-model="selectedIndexes" @change="handleIndexChange">
            <el-checkbox label="000001">上证指数</el-checkbox>
            <el-checkbox label="000300">沪深300</el-checkbox>
            <el-checkbox label="SPX">标普500</el-checkbox>
            <el-checkbox label="NDX">纳斯达克</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item>
          <el-alert 
            title="提示：最多只能选择3个指数同时显示" 
            type="info" 
            :closable="false"
            show-icon
          />
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;" id="section-database">
      <template #header>
        <span>数据库信息</span>
      </template>
      
      <el-descriptions :column="1" border v-loading="dbInfoLoading">
        <el-descriptions-item label="数据目录">
          <el-text type="primary" style="font-family: monospace; font-size: 12px;">
            {{ dbInfo.path || '加载中...' }}
          </el-text>
          <el-button 
            link 
            type="primary" 
            size="small" 
            @click="copyPath"
            style="margin-left: 10px;"
          >
            复制目录路径
          </el-button>
        </el-descriptions-item>
        <el-descriptions-item label="文件大小" v-if="dbInfo.exists">
          {{ formatSize(dbInfo.size) }}
        </el-descriptions-item>
        <el-descriptions-item label="最后修改" v-if="dbInfo.exists">
          {{ dbInfo.modified }}
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="dbInfo.exists ? 'success' : 'info'">
            {{ dbInfo.exists ? '已创建' : '未创建' }}
          </el-tag>
        </el-descriptions-item>
      </el-descriptions>

      <div style="margin-top: 15px; display: flex; gap: 10px;">
        <el-button 
          type="primary" 
          :icon="Download" 
          @click="handleBackup"
          :loading="backupLoading"
          :disabled="!dbInfo.exists"
        >
          备份数据库
        </el-button>
      </div>

      <el-alert 
        style="margin-top: 15px;"
        title="数据目录包含数据库文件（margin.db）及所有资产、历史记录和配置信息，建议定期备份整个目录" 
        type="warning" 
        :closable="false"
        show-icon
      />
    </el-card>

    <el-card style="margin-top: 20px;" id="section-security">
      <template #header>
        <span>安全设置</span>
      </template>
      
      <el-form label-width="120px">
        <el-form-item label="自动锁屏">
          <div style="width: 100%;">
            <el-slider 
              v-model="lockTimeout" 
              :min="0" 
              :max="30" 
              :step="1"
              :marks="lockTimeoutMarks"
              :format-tooltip="formatLockTimeout"
              @change="handleLockTimeoutChange"
              style="width: 400px;"
            />
            <div style="margin-top: 25px; color: #909399; font-size: 13px;">
              当前设置：<span style="color: #409eff; font-weight: bold;">{{ formatLockTimeoutText(lockTimeout) }}</span>
            </div>
          </div>
        </el-form-item>
        
        <el-form-item>
          <el-alert 
            title="设置为 0 表示永不自动锁屏" 
            type="info" 
            :closable="false"
            show-icon
          />
        </el-form-item>

        <el-form-item label="操作">
          <el-space>
            <el-button type="warning" :icon="Lock" @click="handleLockNow">
              立即锁屏
            </el-button>
            <el-button type="danger" :icon="SwitchButton" @click="handleLogout">
              退出登录
            </el-button>
          </el-space>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card id="section-sources">
        <template #header>
          <span>来源管理</span>
        </template>
      
      <el-form inline>
        <el-form-item label="新增来源">
          <el-input 
            v-model="newSourceName" 
            placeholder="如：招商银行"
            style="width: 200px"
            @keyup.enter="handleAddSource"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleAddSource">添加</el-button>
        </el-form-item>
      </el-form>

      <el-divider />

      <el-table :data="sources" style="width: 100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="来源名称" />
        <el-table-column prop="created" label="创建时间" width="200">
          <template #default="scope">
            {{ formatDate(scope.row.created) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template #default="scope">
            <el-button 
              link 
              type="danger" 
              @click="handleDelete(scope.row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card style="margin-top: 20px;" id="section-system">
      <template #header>
        <span>系统信息</span>
      </template>
      
      <el-descriptions :column="1" border v-loading="systemInfoLoading">
        <el-descriptions-item label="软件版本">
          <el-tag type="success">v{{ systemInfo.version }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="构建日期" v-if="systemInfo.buildDate && systemInfo.buildDate !== 'unknown'">
          {{ systemInfo.buildDate }}
        </el-descriptions-item>
        <el-descriptions-item label="操作系统">
          {{ formatOS(systemInfo.os) }}
        </el-descriptions-item>
        <el-descriptions-item label="系统架构">
          {{ formatArch(systemInfo.arch) }}
        </el-descriptions-item>
        <el-descriptions-item label="Go 版本">
          {{ systemInfo.goVersion }}
        </el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>

  <!-- 右侧导航栏 -->
  <div class="settings-nav">
    <div class="nav-title">快速导航</div>
    <el-menu
      :default-active="activeSection"
      class="nav-menu"
      @select="handleNavClick"
    >
      <el-menu-item index="section-indexes">
        <el-icon><TrendCharts /></el-icon>
        <span>指数显示</span>
      </el-menu-item>
      <el-menu-item index="section-database">
        <el-icon><Coin /></el-icon>
        <span>数据库信息</span>
      </el-menu-item>       
      <el-menu-item index="section-security">
        <el-icon><Lock /></el-icon>
        <span>安全设置</span>
      </el-menu-item>
      <el-menu-item index="section-sources">
        <el-icon><Setting /></el-icon>
        <span>来源管理</span>
      </el-menu-item>     
      <el-menu-item index="section-system">
        <el-icon><Monitor /></el-icon>
        <span>系统信息</span>
      </el-menu-item>
    </el-menu>
    
    <!-- 回到顶部按钮 -->
    <transition name="fade">
      <el-button 
        v-if="showBackTop"
        class="back-top-btn"
        circle
        @click="scrollToTop"
        :icon="Top"
      />
    </transition>
  </div>
</div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowDown, Setting, TrendCharts, Coin, Monitor, Top, Download, Lock, SwitchButton } from '@element-plus/icons-vue'
import { GetSources, AddSource, DeleteSource, GetDBInfo, GetSystemInfo, BackupDatabase, Logout } from '../../wailsjs/go/main/App'

const router = useRouter()
const sources = ref([])
const newSourceName = ref('')
const selectedIndexes = ref(['000001', '000300', 'SPX'])
const dbInfo = ref({})
const dbInfoLoading = ref(false)
const backupLoading = ref(false)
const systemInfo = ref({})
const systemInfoLoading = ref(false)
const panelRef = ref(null)
const showScrollHint = ref(false)
const activeSection = ref('section-indexes')
const showBackTop = ref(false)
const lockTimeout = ref(5) // 默认 5 分钟

// 锁屏超时标记（只保留关键标记点，避免拥挤）
const lockTimeoutMarks = {
  0: '永不',
  10: '10分钟',
  30: '30分钟'
}

// 格式化锁屏超时提示
const formatLockTimeout = (value) => {
  if (value === 0) return '永不锁屏'
  return `${value} 分钟`
}

// 格式化锁屏超时文本
const formatLockTimeoutText = (value) => {
  if (value === 0) return '永不自动锁屏'
  return `${value} 分钟后自动锁屏`
}

// 处理锁屏超时变化
const handleLockTimeoutChange = (value) => {
  localStorage.setItem('lockTimeout', value.toString())
  ElMessage.success('自动锁屏设置已保存')
  // 触发自定义事件通知 Dashboard 更新超时设置
  window.dispatchEvent(new CustomEvent('lockTimeoutChanged', { detail: value }))
}

// 立即锁屏
const handleLockNow = async () => {
  try {
    await Logout()
    ElMessage.success('已锁屏')
    router.push('/login')
  } catch (error) {
    ElMessage.error('锁屏失败：' + error)
  }
}

// 退出登录
const handleLogout = async () => {
  try {
    await ElMessageBox.confirm(
      '确定要退出登录吗？',
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await Logout()
    ElMessage.success('已退出登录')
    router.push('/login')
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('退出失败：' + error)
    }
  }
}

const loadSources = async () => {
  try {
    sources.value = await GetSources()
  } catch (error) {
    ElMessage.error('加载失败：' + error)
  }
}

const loadIndexSettings = () => {
  const saved = localStorage.getItem('selectedIndexes')
  if (saved) {
    try {
      selectedIndexes.value = JSON.parse(saved)
    } catch (e) {
      selectedIndexes.value = ['000001', '000300', 'SPX']
    }
  }
}

const handleIndexChange = (value) => {
  // 限制最多选择3个
  if (value.length > 3) {
    ElMessage.warning('最多只能选择3个指数')
    // 使用 nextTick 确保在下一个 DOM 更新周期恢复选择
    nextTick(() => {
      // 找出新增的项（最后一个）
      const lastItem = value[value.length - 1]
      // 移除最后选中的项
      selectedIndexes.value = value.filter(item => item !== lastItem)
    })
    return
  }
  
  selectedIndexes.value = value
  localStorage.setItem('selectedIndexes', JSON.stringify(value))
  ElMessage.success('指数显示设置已保存')
  // 触发自定义事件通知 Dashboard 刷新
  window.dispatchEvent(new CustomEvent('indexSettingsChanged'))
}

const handleAddSource = async () => {
  if (!newSourceName.value.trim()) {
    ElMessage.warning('请输入来源名称')
    return
  }

  try {
    await AddSource(newSourceName.value.trim())
    ElMessage.success('添加成功')
    newSourceName.value = ''
    await loadSources()
  } catch (error) {
    ElMessage.error('添加失败：' + error)
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除来源"${row.name}"吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await DeleteSource(row.id)
    ElMessage.success('删除成功')
    await loadSources()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败：' + error)
    }
  }
}

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN')
}

const loadDBInfo = async () => {
  dbInfoLoading.value = true
  try {
    dbInfo.value = await GetDBInfo()
  } catch (error) {
    ElMessage.error('加载数据库信息失败：' + error)
  } finally {
    dbInfoLoading.value = false
  }
}

const formatSize = (bytes) => {
  if (!bytes) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return (bytes / Math.pow(k, i)).toFixed(2) + ' ' + sizes[i]
}

const copyPath = () => {
  if (dbInfo.value.path) {
    navigator.clipboard.writeText(dbInfo.value.path)
      .then(() => {
        ElMessage.success('数据目录路径已复制到剪贴板')
      })
      .catch(() => {
        ElMessage.error('复制失败')
      })
  }
}

const handleBackup = async () => {
  backupLoading.value = true
  try {
    await BackupDatabase()
    ElMessage.success('数据库备份成功')
  } catch (error) {
    if (error) {
      ElMessage.error('备份失败：' + error)
    }
  } finally {
    backupLoading.value = false
  }
}

const loadSystemInfo = async () => {
  systemInfoLoading.value = true
  try {
    systemInfo.value = await GetSystemInfo()
  } catch (error) {
    ElMessage.error('加载系统信息失败：' + error)
  } finally {
    systemInfoLoading.value = false
  }
}

const formatOS = (os) => {
  const osMap = {
    'windows': 'Windows',
    'darwin': 'macOS',
    'linux': 'Linux',
    'freebsd': 'FreeBSD',
    'openbsd': 'OpenBSD',
    'netbsd': 'NetBSD',
    'dragonfly': 'DragonFly BSD',
    'solaris': 'Solaris',
    'android': 'Android',
    'ios': 'iOS'
  }
  return osMap[os] || os
}

const formatArch = (arch) => {
  const archMap = {
    'amd64': 'x86_64 (64-bit)',
    '386': 'x86 (32-bit)',
    'arm': 'ARM (32-bit)',
    'arm64': 'ARM64 (64-bit)',
    'mips': 'MIPS',
    'mips64': 'MIPS64',
    'ppc64': 'PowerPC 64-bit',
    'ppc64le': 'PowerPC 64-bit LE',
    's390x': 'IBM System z',
    'riscv64': 'RISC-V 64-bit'
  }
  return archMap[arch] || arch
}

// 检查是否需要显示滚动提示
const checkScrollHint = () => {
  if (panelRef.value) {
    const { scrollHeight, clientHeight, scrollTop } = panelRef.value
    // 如果内容高度大于可视高度，且滚动位置在顶部附近，显示提示
    showScrollHint.value = scrollHeight > clientHeight && scrollTop < 50
    // 显示回到顶部按钮
    showBackTop.value = scrollTop > 300
    
    // 更新当前激活的导航项
    updateActiveSection()
  }
}

// 更新当前激活的导航项
const updateActiveSection = () => {
  if (!panelRef.value) return
  
  const sections = ['section-indexes', 'section-database', 'section-security', 'section-sources', 'section-system']
  const scrollTop = panelRef.value.scrollTop
  
  for (const sectionId of sections) {
    const element = document.getElementById(sectionId)
    if (element) {
      const rect = element.getBoundingClientRect()
      const panelRect = panelRef.value.getBoundingClientRect()
      
      // 如果元素在视口中间位置
      if (rect.top <= panelRect.top + 100 && rect.bottom >= panelRect.top + 100) {
        activeSection.value = sectionId
        break
      }
    }
  }
}

// 处理滚动事件
const handleScroll = () => {
  checkScrollHint()
}

// 处理导航点击
const handleNavClick = (index) => {
  console.log('Navigation clicked:', index)
  
  const element = document.getElementById(index)
  if (!element) {
    console.error('Element not found:', index)
    return
  }
  
  if (!panelRef.value) {
    console.error('Panel ref not found')
    return
  }
  
  console.log('Scrolling to element:', element)
  console.log('Panel ref:', panelRef.value)
  
  // 方法1: 使用 scrollIntoView（在父容器中滚动）
  try {
    element.scrollIntoView({
      behavior: 'smooth',
      block: 'start'
    })
    
    // 微调偏移
    setTimeout(() => {
      if (panelRef.value) {
        panelRef.value.scrollTop -= 20
      }
    }, 100)
  } catch (error) {
    console.error('Scroll error:', error)
    
    // 方法2: 备用方案 - 直接计算滚动位置
    try {
      const containerRect = panelRef.value.getBoundingClientRect()
      const elementRect = element.getBoundingClientRect()
      const scrollOffset = elementRect.top - containerRect.top + panelRef.value.scrollTop - 20
      
      panelRef.value.scrollTo({
        top: scrollOffset,
        behavior: 'smooth'
      })
    } catch (err) {
      console.error('Fallback scroll error:', err)
    }
  }
}

// 滚动到下一个区域
const scrollToNext = () => {
  const sections = ['section-indexes', 'section-database', 'section-security', 'section-sources', 'section-system']
  const currentIndex = sections.indexOf(activeSection.value)
  const nextIndex = Math.min(currentIndex + 1, sections.length - 1)
  handleNavClick(sections[nextIndex])
}

// 回到顶部
const scrollToTop = () => {
  if (panelRef.value) {
    panelRef.value.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }
}

onMounted(() => {
  loadSources()
  loadIndexSettings()
  loadDBInfo()
  loadSystemInfo()
  
  // 加载锁屏超时设置
  const savedTimeout = localStorage.getItem('lockTimeout')
  if (savedTimeout) {
    lockTimeout.value = parseInt(savedTimeout)
  }
  
  // 等待内容加载完成后检查是否需要显示滚动提示
  nextTick(() => {
    setTimeout(() => {
      checkScrollHint()
    }, 500)
  })
})

onUnmounted(() => {
  // 清理
})
</script>

<style scoped>
.settings-container {
  display: flex;
  height: 100%;
  gap: 20px;
  position: relative;
  overflow: hidden;
}

.settings-panel {
  flex: 1;
  padding: 20px;
  padding-right: 10px;
  height: 100%;
  overflow-y: auto;
  position: relative;
  scroll-behavior: smooth;
}

.settings-nav {
  width: 200px;
  padding: 20px 20px 20px 10px;
  position: sticky;
  top: 20px;
  align-self: flex-start;
  height: auto;
  max-height: calc(100vh - 40px);
  overflow-y: auto;
}

.nav-title {
  font-size: 14px;
  font-weight: bold;
  color: #606266;
  margin-bottom: 15px;
  padding-left: 10px;
}

.nav-menu {
  border: none;
  background: transparent;
}

.nav-menu .el-menu-item {
  height: 45px;
  line-height: 45px;
  border-radius: 8px;
  margin-bottom: 5px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  cursor: pointer;
}

.nav-menu .el-menu-item:hover {
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
  transform: translateX(5px);
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.15);
}

.nav-menu .el-menu-item.is-active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  transform: translateX(5px);
}

.nav-menu .el-menu-item.is-active .el-icon {
  color: white;
}

.back-top-btn {
  position: fixed;
  bottom: 80px;
  right: 40px;
  z-index: 999;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.back-top-btn:hover {
  transform: scale(1.1);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.5);
}

/* 滚动提示 */
.scroll-hint {
  position: fixed;
  bottom: 30px;
  left: 50%;
  transform: translateX(-50%);
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 12px 24px;
  border-radius: 25px;
  display: flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
  z-index: 1000;
  cursor: pointer;
  animation: bounce 2s infinite;
  font-size: 14px;
  font-weight: 500;
}

.scroll-hint:hover {
  transform: translateX(-50%) scale(1.05);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.5);
}

.scroll-icon {
  font-size: 18px;
  animation: arrow-bounce 1.5s infinite;
}

/* 淡入淡出动画 */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 弹跳动画 */
@keyframes bounce {
  0%, 100% {
    transform: translateX(-50%) translateY(0);
  }
  50% {
    transform: translateX(-50%) translateY(-5px);
  }
}

/* 箭头弹跳动画 */
@keyframes arrow-bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(3px);
  }
}

/* 自定义滚动条样式 */
.settings-panel::-webkit-scrollbar,
.settings-nav::-webkit-scrollbar {
  width: 6px;
}

.settings-panel::-webkit-scrollbar-track,
.settings-nav::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.settings-panel::-webkit-scrollbar-thumb,
.settings-nav::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 3px;
}

.settings-panel::-webkit-scrollbar-thumb:hover,
.settings-nav::-webkit-scrollbar-thumb:hover {
  background: #555;
}
</style>
