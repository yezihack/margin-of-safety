<template>
  <div class="asset-management">
    <el-row :gutter="20">
      <el-col :span="7">
        <el-card>
          <template #header>
            <span>添加资产</span>
          </template>
          <el-form :model="form" label-width="80px">
            <el-form-item label="基金代码">
              <el-input 
                ref="codeInputRef"
                v-model="form.code" 
                placeholder="如：050027" 
                @blur="handleCodeBlur"
                @keyup.enter="handleQueryFund"
                :loading="loading"
              >
                <template #append>
                  <el-button @click="handleQueryFund" :loading="loading">查询</el-button>
                </template>
              </el-input>
            </el-form-item>
            <el-form-item label="基金名称">
              <el-input v-model="form.name" placeholder="自动获取" readonly />
            </el-form-item>
            <el-form-item label="类型">
              <el-radio-group v-model="form.type">
                <el-radio label="stock">股票</el-radio>
                <el-radio label="bond">债券</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="来源">
              <el-select v-model="form.source" placeholder="请选择">
                <el-option 
                  v-for="source in sources" 
                  :key="source.id" 
                  :label="source.name" 
                  :value="source.name" 
                />
              </el-select>
            </el-form-item>
            <el-form-item label="金额">
              <el-input-number 
                ref="amountInputRef"
                v-model="form.amount" 
                :min="0" 
                :max="100000"
                :precision="2" 
                placeholder="0.00"
                style="width: 100%" 
                @keyup.enter="handleSave"
              />
              <el-slider 
                v-model="form.amount" 
                :min="0" 
                :max="100000" 
                :step="100"
                :show-tooltip="true"
                :format-tooltip="formatSliderTooltip"
                style="margin-top: 10px;"
              />
              <div style="margin-top: 5px; font-size: 12px; color: #909399; display: flex; justify-content: space-between;">
                <span>0 元</span>
                <span style="color: #409eff; font-weight: bold;">{{ (form.amount || 0).toFixed(2) }} 元</span>
                <span>100,000 元</span>
              </div>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="handleSave" :disabled="!form.name">保存</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="17">
        <el-card>
          <template #header>
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <span>资产列表</span>
              <el-input
                v-model="searchText"
                placeholder="搜索代码/名称/类型/来源"
                style="width: 250px"
                clearable
              >
                <template #prefix>
                  <el-icon><Search /></el-icon>
                </template>
              </el-input>
            </div>
          </template>
          <el-table 
            ref="tableRef"
            :data="paginatedAssets" 
            style="width: 100%" 
            border
            @header-dragend="handleHeaderDragend"
          >
            <el-table-column prop="code" label="代码" :width="columnWidths.code" resizable>
              <template #default="scope">
                <el-link 
                  :href="scope.row.url" 
                  target="_blank" 
                  type="primary"
                  v-if="scope.row.url"
                >
                  {{ scope.row.code }}
                </el-link>
                <span v-else>{{ scope.row.code }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="名称" :min-width="columnWidths.name" show-overflow-tooltip resizable />
            <el-table-column prop="type" label="类型" :width="columnWidths.type" resizable>
              <template #default="scope">
                {{ scope.row.type === 'stock' ? '股票' : '债券' }}
              </template>
            </el-table-column>
            <el-table-column prop="source" label="来源" :width="columnWidths.source" resizable />
            <el-table-column prop="amount" label="金额" :width="columnWidths.amount" resizable>
              <template #default="scope">
                {{ scope.row.amount.toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150" fixed="right">
              <template #default="scope">
                <el-button link type="primary" @click="handleEdit(scope.row)">编辑</el-button>
                <el-button link type="danger" @click="handleDelete(scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <div v-if="filteredAssets.length === 0 && searchText" style="text-align: center; padding: 20px; color: #999;">
            未找到匹配的资产
          </div>
          
          <!-- 金额汇总 -->
          <div v-if="filteredAssets.length > 0" style="margin-top: 15px; padding: 10px; background: #f5f7fa; border-radius: 4px; display: flex; justify-content: space-between; align-items: center;">
            <div style="font-size: 14px; color: #606266;">
              <span style="margin-right: 20px;">
                <strong>当前页合计：</strong>
                <span style="color: #409eff; font-weight: bold;">{{ currentPageTotal.toFixed(2) }}</span> 元
              </span>
              <span v-if="filteredAssets.length !== assets.length || paginatedAssets.length !== filteredAssets.length">
                <strong>筛选总计：</strong>
                <span style="color: #67c23a; font-weight: bold;">{{ filteredTotal.toFixed(2) }}</span> 元
              </span>
            </div>
          </div>
          
          <el-pagination
            v-if="filteredAssets.length > 0"
            v-model:current-page="currentPage"
            v-model:page-size="pageSize"
            :page-sizes="[20, 40, 50, 100]"
            :total="filteredAssets.length"
            layout="total, sizes, prev, pager, next, jumper"
            style="margin-top: 20px; justify-content: center;"
            @size-change="handleSizeChange"
          />
        </el-card>
      </el-col>
    </el-row>

    <!-- 编辑资产对话框 -->
    <el-dialog v-model="editDialogVisible" title="编辑资产" width="400px">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="基金代码">
          <el-input v-model="editForm.code" disabled />
        </el-form-item>
        <el-form-item label="基金名称">
          <el-input v-model="editForm.name" disabled />
        </el-form-item>
        <el-form-item label="类型">
          <el-radio-group v-model="editForm.type">
            <el-radio label="stock">股票</el-radio>
            <el-radio label="bond">债券</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="来源">
          <el-select v-model="editForm.source" placeholder="请选择" style="width: 100%">
            <el-option 
              v-for="source in sources" 
              :key="source.id" 
              :label="source.name" 
              :value="source.name" 
            />
          </el-select>
        </el-form-item>
        <el-form-item label="金额">
          <el-input-number 
            v-model="editForm.amount" 
            :min="0" 
            :max="100000"
            :precision="2" 
            placeholder="0.00"
            style="width: 100%" 
            @keyup.enter="handleUpdate"
          />
          <el-slider 
            v-model="editForm.amount" 
            :min="0" 
            :max="100000" 
            :step="100"
            :show-tooltip="true"
            :format-tooltip="formatSliderTooltip"
            style="margin-top: 10px;"
          />
          <div style="margin-top: 5px; font-size: 12px; color: #909399; display: flex; justify-content: space-between;">
            <span>0 元</span>
            <span style="color: #409eff; font-weight: bold;">{{ (editForm.amount || 0).toFixed(2) }} 元</span>
            <span>100,000 元</span>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleUpdate">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import { GetAssets, SaveAsset, GetFundInfo, GetSources, DeleteAsset, UpdateAsset } from '../../wailsjs/go/main/App'

const assets = ref([])
const sources = ref([])
const loading = ref(false)
const editDialogVisible = ref(false)
const searchText = ref('')
const currentPage = ref(1)
const pageSize = ref(20)
const tableRef = ref()
const codeInputRef = ref(null)
const amountInputRef = ref(null)

// 列宽设置（响应式）
const columnWidths = ref({
  code: 100,
  name: 150,
  type: 80,
  source: 100,
  amount: 120
})

// 格式化滑块提示
const formatSliderTooltip = (value) => {
  return `${value.toFixed(2)} 元`
}

// 从 localStorage 加载设置
const loadTableSettings = () => {
  // 加载分页大小
  const savedPageSize = localStorage.getItem('assetTablePageSize')
  if (savedPageSize) {
    pageSize.value = parseInt(savedPageSize)
  }
  
  // 加载列宽
  const savedWidths = localStorage.getItem('assetTableColumnWidths')
  if (savedWidths) {
    try {
      const widths = JSON.parse(savedWidths)
      columnWidths.value = { ...columnWidths.value, ...widths }
    } catch (e) {
      console.error('Failed to load column widths:', e)
    }
  }
}

// 保存分页大小
const savePageSize = (size) => {
  localStorage.setItem('assetTablePageSize', size.toString())
}

const form = reactive({
  code: '',
  name: '',
  url: '',
  type: 'bond',
  source: '',
  amount: null
})

const editForm = reactive({
  id: 0,
  code: '',
  name: '',
  type: 'bond',
  source: '',
  amount: 0
})

// 过滤后的资产列表
const filteredAssets = computed(() => {
  if (!searchText.value) {
    return assets.value
  }
  
  const search = searchText.value.toLowerCase()
  return assets.value.filter(asset => {
    // 搜索代码
    if (asset.code && asset.code.toLowerCase().includes(search)) {
      return true
    }
    // 搜索名称
    if (asset.name && asset.name.toLowerCase().includes(search)) {
      return true
    }
    // 搜索类型
    const typeText = asset.type === 'stock' ? '股票' : '债券'
    if (typeText.includes(search) || asset.type.toLowerCase().includes(search)) {
      return true
    }
    // 搜索来源
    if (asset.source && asset.source.toLowerCase().includes(search)) {
      return true
    }
    return false
  })
})

// 分页后的资产列表
const paginatedAssets = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredAssets.value.slice(start, end)
})

// 计算当前页面显示的资产总金额
const currentPageTotal = computed(() => {
  return paginatedAssets.value.reduce((sum, asset) => sum + asset.amount, 0)
})

// 计算过滤后的所有资产总金额
const filteredTotal = computed(() => {
  return filteredAssets.value.reduce((sum, asset) => sum + asset.amount, 0)
})

// 保存列宽
const handleHeaderDragend = (newWidth, oldWidth, column) => {
  const columnName = column.property
  if (!columnName) return
  
  // 更新响应式列宽
  columnWidths.value[columnName] = newWidth
  
  // 保存到 localStorage
  localStorage.setItem('assetTableColumnWidths', JSON.stringify(columnWidths.value))
}

// 处理分页大小变化
const handleSizeChange = (size) => {
  savePageSize(size)
}

const loadSources = async () => {
  try {
    const sourceList = await GetSources()
    sources.value = sourceList
    // 设置默认来源为第一个
    if (sourceList.length > 0 && !form.source) {
      form.source = sourceList[0].name
    }
  } catch (error) {
    ElMessage.error('加载来源失败：' + error)
  }
}

const loadAssets = async () => {
  try {
    assets.value = await GetAssets()
  } catch (error) {
    ElMessage.error('加载失败：' + error)
  }
}

// 查询基金信息
const handleQueryFund = async () => {
  if (!form.code.trim()) {
    ElMessage.warning('请输入基金代码')
    return
  }

  loading.value = true
  try {
    const info = await GetFundInfo(form.code.trim())
    form.name = info.name
    form.url = info.url
    
    // 根据基金类型自动设置股票/债券
    // 只有当后端返回了类型信息时才更新，否则保留用户上一次的选择
    if (info.type) {
      const typeStr = info.type.toLowerCase()
      // 股票类：股票、指数、混合
      if (typeStr.includes('股票') || typeStr.includes('指数') || typeStr.includes('混合')) {
        form.type = 'stock'
      } 
      // 债券类：债券、债、纯债、货币
      else if (typeStr.includes('债券') || typeStr.includes('债') || typeStr.includes('纯债') || typeStr.includes('货币')) {
        form.type = 'bond'
      }
      // 如果类型为空字符串，保留用户上一次的选择（不修改 form.type）
    }
    
    ElMessage.success('基金信息获取成功')
    
    // 清空金额（设置为 null，这样输入框会显示为空）
    form.amount = null
    
    // 查询成功后，聚焦到金额输入框
    setTimeout(() => {
      if (amountInputRef.value) {
        // 获取 el-input-number 内部的 input 元素
        const inputElement = amountInputRef.value.$el.querySelector('input')
        if (inputElement) {
          inputElement.focus()
          inputElement.select()
        }
      }
    }, 100)
  } catch (error) {
    ElMessage.error('查询失败：' + error)
    form.name = ''
    form.url = ''
  } finally {
    loading.value = false
  }
}

// 代码输入框失焦时自动查询
const handleCodeBlur = () => {
  if (form.code.trim() && !form.name) {
    handleQueryFund()
  }
}

const handleSave = async () => {
  if (!form.code.trim()) {
    ElMessage.warning('请输入基金代码')
    return
  }
  
  if (!form.name.trim()) {
    ElMessage.warning('请先查询基金信息')
    return
  }

  // 处理 null 值
  const amount = form.amount || 0

  // 验证金额
  if (amount < 0) {
    ElMessage.warning('金额不能小于0')
    return
  }

  // 检查是否已存在相同代码和来源的资产
  const existing = assets.value.find(
    asset => asset.code === form.code && asset.source === form.source
  )

  if (existing) {
    try {
      await ElMessageBox.confirm(
        `基金"${form.name}"(${form.code})在"${form.source}"已存在，是否更新金额？`,
        '提示',
        {
          confirmButtonText: '更新',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )
    } catch {
      return // 用户取消
    }
  }

  try {
    await SaveAsset(form.code, form.name, form.url, form.type, form.source, amount)
    ElMessage.success(existing ? '更新成功' : '添加成功')
    await loadAssets()
    
    // 保存当前来源
    const currentSource = form.source
    
    // 清空表单（保留来源）
    form.code = ''
    form.name = ''
    form.url = ''
    form.amount = null
    form.source = currentSource // 保留来源
    
    // 聚焦到基金代码输入框
    if (codeInputRef.value) {
      codeInputRef.value.focus()
    }
  } catch (error) {
    ElMessage.error('保存失败：' + error)
  }
}

// 编辑资产
const handleEdit = (row) => {
  editForm.id = row.id
  editForm.code = row.code
  editForm.name = row.name
  editForm.type = row.type
  editForm.source = row.source
  editForm.amount = row.amount
  editDialogVisible.value = true
}

// 更新资产
const handleUpdate = async () => {
  // 验证金额
  if (editForm.amount < 0) {
    ElMessage.warning('金额不能小于0')
    return
  }

  // 验证来源
  if (!editForm.source) {
    ElMessage.warning('请选择来源')
    return
  }

  try {
    await UpdateAsset(editForm.id, editForm.type, editForm.source, editForm.amount)
    ElMessage.success('更新成功')
    editDialogVisible.value = false
    await loadAssets()
  } catch (error) {
    ElMessage.error('更新失败：' + error)
  }
}

// 删除资产
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除"${row.name}"(${row.code})吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await DeleteAsset(row.id)
    ElMessage.success('删除成功')
    await loadAssets()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败：' + error)
    }
  }
}

onMounted(() => {
  loadTableSettings()
  loadSources()
  loadAssets()
})
</script>
