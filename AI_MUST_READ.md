# AI Must Read - 关键开发文档

## NewAPI 集成关键要点

### 1. modAI Provider 使用 Gemini 原生格式 ⚠️ 最重要

**关键理解：** modAI provider 必须使用 **Gemini 原生格式**，而不是 OpenAI 格式。

#### 为什么 modAI 使用 Gemini 格式？

modAI provider 是对 Google Generative AI SDK 的封装，连接到 NewAPI 代理服务器。虽然名为"NewAPI"，但 modAI 必须使用 Gemini 的原生 API 格式：

- **SDK**: 使用 `@ai-sdk/google` 的 `createGoogleGenerativeAI`
- **端点**: `/v1beta/models/{model}:generateContent`（Gemini 格式）
- **认证**: `x-goog-api-key` 头部（Gemini 格式）
- **请求体**: Gemini 原生请求格式
- **响应**: Gemini 原生响应格式（`GeminiChatResponse`）

#### modAI Provider 关键配置

在任何需要区分 provider 的地方，modAI 必须与 google/google-vertex 归为一类：

```typescript
// ✅ 正确：modai 与 google 归为一类
if (["google", "google-vertex", "modai"].includes(provider)) {
  // 使用 Gemini 特性
}

// ❌ 错误：将 modai 与 OpenAI 归为一类
if (["openai", "modai"].includes(provider)) {
  // 这是错误的！
}
```

**关键代码位置：**
- `src/utils/deep-research/provider.ts:30-36` - modAI 使用 createGoogleGenerativeAI
- `src/hooks/useDeepResearch.ts:75` - modAI 包含在 Gemini provider 检查中
- `src/utils/deep-research/index.ts:98` - modAI 使用 Gemini search grounding
- `src/app/api/ai/modai/[...slug]/route.ts:38-41` - 使用 x-goog-api-key 头部

### 2. 双重 API 格式架构（仅用于余额查询）

NewAPI 代理服务器在**余额查询**端点使用不同的格式：

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
// 认证方式: Authorization Bearer 头部（注意：即使是 modAI provider 也用这个格式）
headers: {
  "Authorization": `Bearer ${token}`
}
```

**重要说明：** 余额查询是 NewAPI 代理服务器特有的端点，不是 Google API 的一部分。因此即使是 modAI provider，余额查询也必须使用 OpenAI 格式的 Bearer token。

**关键代码位置:**
- `src/utils/newapi.ts:23-69` - validateNewApiToken 函数（支持自动检测格式）
- `src/utils/newapi.ts:79-169` - getNewApiBalance 函数（强制使用 OpenAI 格式）
- `src/components/Internal/BalanceButton.tsx:27-31` - 根据 provider 选择正确的 API key

### 3. 余额查询必需参数

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

### 4. 余额计算逻辑

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

### 5. Provider 支持矩阵

| Provider | API Key 字段 | API Proxy 字段 | 默认 Base URL | 支持余额查询 |
|----------|-------------|---------------|--------------|------------|
| modai | modAIApiKey | modAIApiProxy | https://generativelanguage.googleapis.com | ✅ |
| openai | apiKey | apiProxy | https://off.092420.xyz | ✅ |
| google | apiKey | apiProxy | https://generativelanguage.googleapis.com | ❌ |
| anthropic | anthropicApiKey | anthropicApiProxy | - | ❌ |

**关键代码位置:**
- `src/components/Internal/BalanceButton.tsx:27-34` - Provider 检测逻辑
- `src/components/Setting.tsx:324-342` - 验证时的 Provider 检测

### 6. 默认模型配置

所有 modAI provider 的默认模型已统一为 `gemini-2.5-flash`：

**需要同步更新的文件:**
1. `Dockerfile` - ARG 变量（builder 和 runner 阶段都需要）
2. `build-docker.sh` - 交互式提示默认值
3. `src/store/setting.ts` - Zustand store 默认值
4. `.env.example` - 环境变量示例（如果存在）

#### 重要：localStorage 缓存问题 ⚠️

**问题症状：**
- 重新构建 Docker 镜像并设置了新的模型配置
- 但浏览器中看到的还是旧的模型配置
- 需要清除浏览器缓存或使用隐私模式才能看到新配置

**根本原因：**
Zustand 的 persist 中间件会将所有设置保存到浏览器的 localStorage 中。当用户重新访问应用时，persist 会从 localStorage 恢复之前保存的设置，这些设置会覆盖环境变量中的默认值。

**解决方案：**
在 `src/store/setting.ts` 中添加了自定义 merge 策略，确保环境变量中的模型配置始终优先：

```typescript
{
  name: "setting",
  merge: (persistedState, currentState) => {
    const merged = {
      ...currentState,
      ...(persistedState as Partial<SettingStore>),
    };

    // 强制使用环境变量中的模型配置
    if (process.env.NEXT_PUBLIC_MODAI_THINKING_MODEL) {
      merged.modAIThinkingModel = process.env.NEXT_PUBLIC_MODAI_THINKING_MODEL;
    }
    if (process.env.NEXT_PUBLIC_MODAI_NETWORKING_MODEL) {
      merged.modAINetworkingModel = process.env.NEXT_PUBLIC_MODAI_NETWORKING_MODEL;
    }
    if (process.env.NEXT_PUBLIC_MODAI_API_BASE_URL) {
      merged.modAIApiProxy = process.env.NEXT_PUBLIC_MODAI_API_BASE_URL;
    }

    return merged;
  },
}
```

这样，即使 localStorage 中有旧的配置，环境变量的值也会强制覆盖，无需清除浏览器缓存。

**关键代码位置:** `src/store/setting.ts:200-222`

### 7. 主题和样式

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

### 问题 4: Docker 构建后模型配置没有生效 ⚠️ 最常见
**症状:**
- 运行 `build-docker.sh` 时设置了自定义 thinking/networking model
- 但启动容器后，浏览器中看到的还是默认的 gemini-2.5-flash
- 需要清除浏览器缓存或使用隐私模式才能看到新配置

**根本原因:**
Zustand persist 中间件会将设置保存到浏览器 localStorage，旧的 localStorage 数据会覆盖新的环境变量配置。

**解决方案:**
已在 `src/store/setting.ts:200-222` 中添加自定义 merge 策略，环境变量配置会强制覆盖 localStorage。更新到最新代码后无需清除缓存。

**临时解决方案（如果使用旧版本）:**
1. 清除浏览器缓存和 localStorage
2. 或使用隐私/无痕模式打开
3. 或在浏览器开发者工具中手动删除 localStorage 中的 "setting" key

## Git Commit 历史

关键提交记录：

1. **78cbfbb** - 添加 modAI 对 Gemini 原生特性的支持（search grounding）
2. **a13be80** - 添加关键开发文档
3. **4a094d6** - 添加余额查询日期范围参数
4. **3b0c848** - 分离 API 格式并更新默认模型
5. **bbedcea** - 添加 Google Generative AI API 格式支持

## 代码审查清单

在修改 modAI/NewAPI 相关代码时，请确保：

- [ ] **modAI 使用 Gemini 格式**：在任何 provider 检查中，modai 必须与 google/google-vertex 归为一类
- [ ] **验证端点格式**：验证端点使用正确的认证格式（Google 的 x-goog-api-key）
- [ ] **余额查询格式**：余额查询始终使用 OpenAI 格式的 Authorization Bearer
- [ ] **日期范围参数**：余额查询包含 start_date 和 end_date 参数
- [ ] **Provider 支持**：支持 modai 和 openai provider 的余额查询
- [ ] **默认配置**：默认 URL 配置正确（modai 用 Gemini base URL）
- [ ] **错误处理**：错误处理完善（网络失败、API 错误等）
- [ ] **默认模型**：更新所有配置文件中的默认模型
- [ ] **Gemini 特性**：modai 可以使用 Gemini 原生特性（如 search grounding）

## 参考实现

如需参考完整实现，请查看：
- **NewAPI Gemini Handler (Go)**: 提供了 Gemini 原生格式的完整处理示例
  - 使用 `dto.GeminiChatResponse` 处理响应
  - 使用 `UsageMetadata` 计算 token 使用量
  - 直接发送 Gemini 格式响应，不转换为 OpenAI 格式
- **NewAPI 官方文档**: LogsTable 组件展示了余额查询的完整实现
- **OpenAI API 规范**: 余额查询端点格式参考
- **Google Generative AI API 规范**: 验证端点和请求格式参考

---

**最后更新:** 2025-11-13
**维护者:** Claude AI Assistant
