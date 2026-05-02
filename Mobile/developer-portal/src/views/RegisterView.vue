<script setup>
</script>

<template>
  <div class="login-page">
    <div class="login-card" style="width: 480px;">
      <h1>申请 API 访问权限</h1>
      <p class="login-subtitle">开发者注册</p>

      <div class="card" style="text-align: center; padding: 32px;">
        <p style="font-size: 15px; color: #555; line-height: 1.8;">
          请联系平台管理员申请 API 访问权限
        </p>

        <div style="margin-top: 24px; padding: 16px; background: #f9f9f9; border-radius: 8px; text-align: left;">
          <p style="font-size: 14px; color: #666; line-height: 1.8;">
            <strong>联系方式</strong><br />
            邮箱: api@smart-livestock.com<br />
            电话: 400-888-9999<br />
            工作时间: 周一至周五 9:00-18:00
          </p>
        </div>
      </div>

      <p style="text-align: center; margin-top: 16px; font-size: 13px; color: #aaa;">
        已有账号？
        <router-link to="/login">返回登录</router-link>
      </p>
    </div>
  </div>
</template>
