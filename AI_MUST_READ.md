# AI Must Read - 关键开发文档

## NewAPI 集成关键要点

### 1. 双重 API 格式架构 ⚠️ 极其重要

NewAPI 代理服务器使用**两种不同的 API 格式**，必须分别处理：

#### 验证端点（Validation）- Google AI Studio 格式
```typescript
// 端点: /v1beta/models 或 /v1/models (取决于 baseUrl)
// 认证方式: x-goog-api-key 头部
headers: {
  "x-goog-api-key": token
}
```

#### 余额查询端点（Balance）- OpenAI 格式
```typescript
// 端点: /v1/dashboard/billing/subscription 和 /v1/dashboard/billing/usage
// 认证方式: Authorization Bearer 头部
headers: {
  "Authorization": `Bearer ${token}`
}
```

**关键代码位置:**
- `src/utils/newapi.ts:23-69` - validateNewApiToken 函数（支持自动检测格式）
- `src/utils/newapi.ts:79-169` - getNewApiBalance 函数（强制使用 OpenAI 格式）

### 2. 余额查询必需参数

余额使用量 API **必须**包含日期范围参数，否则请求会失败：

```typescript
// 错误示例（缺少参数）
`${baseUrl}/v1/dashboard/billing/usage`

// 正确示例（包含日期范围）
const startDate = new Date(now.getTime() - 100 * 24 * 60 * 60 * 1000);
const startDateStr = startDate.toISOString().split("T")[0];
const endDateStr = now.toISOString().split("T")[0];
`${baseUrl}/v1/dashboard/billing/usage?start_date=${startDateStr}&end_date=${endDateStr}`
```

**参考实现:** `src/utils/newapi.ts:124-133`

### 3. 余额计算逻辑

```typescript
// 1. 查询总额度
const subscriptionData = await fetch(`${baseUrl}/v1/dashboard/billing/subscription`);
const hardLimitUsd = subscriptionData.hard_limit_usd || 100; // 默认 100

// 2. 查询已用额度
const usageData = await fetch(`${baseUrl}/v1/dashboard/billing/usage?start_date=...&end_date=...`);
const totalUsage = (usageData.total_usage || 0) / 100; // 注意除以 100

// 3. 计算剩余额度
const balance = hardLimitUsd - totalUsage;
```

**特殊情况:**
- `hard_limit_usd === 100000000` 表示无限额度

### 4. Provider 支持矩阵

| Provider | API Key 字段 | API Proxy 字段 | 默认 Base URL | 支持余额查询 |
|----------|-------------|---------------|--------------|------------|
| modai | modAIApiKey | modAIApiProxy | https://generativelanguage.googleapis.com | ✅ |
| openai | apiKey | apiProxy | https://off.092420.xyz | ✅ |
| google | apiKey | apiProxy | https://generativelanguage.googleapis.com | ❌ |
| anthropic | anthropicApiKey | anthropicApiProxy | - | ❌ |

**关键代码位置:**
- `src/components/Internal/BalanceButton.tsx:27-34` - Provider 检测逻辑
- `src/components/Setting.tsx:324-342` - 验证时的 Provider 检测

### 5. 默认模型配置

所有 modAI provider 的默认模型已统一为 `gemini-2.5-flash`：

**需要同步更新的文件:**
1. `Dockerfile` - ARG 变量
2. `build-docker.sh` - 交互式提示默认值
3. `src/store/setting.ts` - Zustand store 默认值
4. `.env.example` - 环境变量示例（如果存在）

### 6. 主题和样式

#### 背景色配置
```css
/* src/app/globals.css */
:root {
  --background: 240 100% 99%; /* #fafbff */
}
```

**注意:** HSL 格式，不是 RGB！

## 常见问题排查

### 问题 1: 余额查询返回 0 或失败
**可能原因:**
1. 缺少日期范围参数
2. 使用了错误的认证格式（应该用 OpenAI Bearer 格式）
3. BaseUrl 错误

**解决方案:** 检查 `src/utils/newapi.ts:129-133`

### 问题 2: 分发版中余额按钮不工作
**可能原因:**
1. BalanceButton 没有检测到正确的 provider
2. 没有使用 modAI provider 的 API key 字段

**解决方案:** 确保 `src/components/Internal/BalanceButton.tsx:27-31` 正确选择 API key

### 问题 3: 验证失败但 API key 是正确的
**可能原因:**
1. BaseUrl 自动检测错误
2. 使用了错误的端点（应该是 /v1beta/models 或 /v1/models）

**解决方案:** 检查 `src/utils/newapi.ts:29-32` 的自动检测逻辑

## Git Commit 历史

关键提交记录：

1. **4a094d6** - 添加余额查询日期范围参数
2. **3b0c848** - 分离 API 格式并更新默认模型
3. **bbedcea** - 添加 Google Generative AI API 格式支持

## 代码审查清单

在修改 NewAPI 相关代码时，请确保：

- [ ] 验证端点使用正确的认证格式（Google 或 OpenAI）
- [ ] 余额查询始终使用 OpenAI 格式
- [ ] 余额查询包含 start_date 和 end_date 参数
- [ ] 支持 modai 和 openai provider
- [ ] 默认 URL 配置正确
- [ ] 错误处理完善（网络失败、API 错误等）
- [ ] 更新所有配置文件中的默认模型

## 参考实现

如需参考完整实现，请查看：
- NewAPI 官方文档的 LogsTable 组件
- OpenAI API 规范
- Google Generative AI API 规范

---

**最后更新:** 2025-11-13
**维护者:** Claude AI Assistant
