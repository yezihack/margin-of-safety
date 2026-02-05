<template>
  <div class="container">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <h2>欢迎使用 Margin</h2>
          <p class="slogan">Build portfolios that survive uncertainty</p>
        </div>
      </template>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="设置密码" prop="password">
          <el-input 
            v-model="form.password" 
            type="password" 
            show-password 
            placeholder="请输入密码"
            @keyup.enter="handleSubmit"
          />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input 
            v-model="form.confirmPassword" 
            type="password" 
            show-password 
            placeholder="请再次输入密码"
            @keyup.enter="handleSubmit"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="loading" style="width: 100%">
            确认设置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { SetPassword } from '../../wailsjs/go/main/App'

const router = useRouter()
const formRef = ref()
const loading = ref(false)

const form = reactive({
  password: '',
  confirmPassword: ''
})

const validatePass = (rule, value, callback) => {
  if (value === '') {
    callback(new Error('请输入密码'))
  } else if (value.length < 6) {
    callback(new Error('密码长度不能少于6位'))
  } else {
    callback()
  }
}

const validatePass2 = (rule, value, callback) => {
  if (value === '') {
    callback(new Error('请再次输入密码'))
  } else if (value !== form.password) {
    callback(new Error('两次输入密码不一致'))
  } else {
    callback()
  }
}

const rules = {
  password: [{ validator: validatePass, trigger: 'blur' }],
  confirmPassword: [{ validator: validatePass2, trigger: 'blur' }]
}

const handleSubmit = async () => {
  await formRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        await SetPassword(form.password)
        // 清除可能存在的登录标记
        sessionStorage.removeItem('isLoggedIn')
        ElMessage.success('密码设置成功，请登录')
        // 跳转到登录页，让用户输入密码登录
        await router.replace('/login')
      } catch (error) {
        ElMessage.error('设置失败：' + error)
      } finally {
        loading.value = false
      }
    }
  })
}
</script>
