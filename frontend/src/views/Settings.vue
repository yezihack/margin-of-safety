<template>
  <div class="settings">
    <el-page-header @back="goBack" title="返回">
      <template #content>
        <span class="page-title">设置</span>
      </template>
    </el-page-header>
    
    <el-card style="margin-top: 20px">
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
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { GetSources, AddSource, DeleteSource } from '../../wailsjs/go/main/App'

const router = useRouter()
const sources = ref([])
const newSourceName = ref('')

const goBack = () => {
  router.push('/dashboard')
}

const loadSources = async () => {
  try {
    sources.value = await GetSources()
  } catch (error) {
    ElMessage.error('加载失败：' + error)
  }
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

onMounted(() => {
  loadSources()
})
</script>

<style scoped>
.settings {
  padding: 20px;
}

.page-title {
  font-size: 18px;
  font-weight: bold;
}
</style>
