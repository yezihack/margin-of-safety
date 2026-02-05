<template>
  <div class="container">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <h2>Margin</h2>
          <p class="slogan">用结构对抗情绪</p>
        </div>
      </template>
      <el-form :model="form" ref="formRef" label-width="0" @submit.prevent="handleLogin">
        <el-form-item>
          <el-input 
            v-model="form.password" 
            type="password" 
            show-password 
            placeholder="请输入密码"
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleLogin" :loading="loading" style="width: 100%">
            解锁
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { IsFirstRun, VerifyPassword } from '../../wailsjs/go/main/App'

const router = useRouter()
const formRef = ref()
const loading = ref(false)

const form = reactive({
  password: ''
})

onMounted(async () => {
  try {
    // 只检查是否首次运行
    const isFirst = await IsFirstRun()
    if (isFirst) {
      await router.replace('/set-password')
    }
  } catch (error) {
    console.error('检查状态失败:', error)
  }
})

const handleLogin = async () => {
  // 防止重复提交
  if (loading.value) {
    return
  }
  
  if (!form.password) {
    ElMessage.warning('请输入密码')
    return
  }
  
  loading.value = true
  try {
    const result = await VerifyPassword(form.password)
    
    if (result) {
      // 登录成功，直接跳转
      router.push('/dashboard')
    } else {
      ElMessage.error('密码错误')
      form.password = ''
    }
  } catch (error) {
    ElMessage.error('验证失败：' + error)
    form.password = ''
  } finally {
    loading.value = false
  }
}
</script>
