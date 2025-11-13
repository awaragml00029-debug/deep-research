/**
 * NewAPI 验证和余额查询工具函数
 */

export interface NewApiValidationResponse {
  success: boolean;
  message?: string;
  data?: any;
}

export interface NewApiBalanceResponse {
  balance: number;
  currency?: string;
}

/**
 * 验证 NewAPI Token
 * @param token - NewAPI Token
 * @param baseUrl - NewAPI 基础 URL
 * @param useGoogleFormat - 是否使用 Google API 格式（默认自动检测）
 * @returns 验证结果
 */
export async function validateNewApiToken(
  token: string,
  baseUrl: string = "https://off.092420.xyz",
  useGoogleFormat?: boolean
): Promise<NewApiValidationResponse> {
  try {
    // 自动检测：如果 baseUrl 包含 generativelanguage.googleapis.com，使用 Google 格式
    const isGoogleApi = useGoogleFormat ?? baseUrl.includes("generativelanguage.googleapis.com");

    const endpoint = isGoogleApi ? `${baseUrl}/v1beta/models` : `${baseUrl}/v1/models`;
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };

    // Google API 使用 x-goog-api-key，OpenAI 兼容 API 使用 Authorization Bearer
    if (isGoogleApi) {
      headers["x-goog-api-key"] = token;
    } else {
      headers["Authorization"] = `Bearer ${token}`;
    }

    const response = await fetch(endpoint, {
      method: "GET",
      headers,
    });

    if (response.status === 200) {
      const data = await response.json();
      return {
        success: true,
        message: "Token validated successfully",
        data,
      };
    } else {
      const errorText = await response.text();
      return {
        success: false,
        message: `Validation failed: ${response.status} ${errorText}`,
      };
    }
  } catch (error) {
    return {
      success: false,
      message: `Network error: ${error instanceof Error ? error.message : "Unknown error"}`,
    };
  }
}

/**
 * 获取 NewAPI 账户余额
 * 计算逻辑：剩余额度 = 总额度 - 已用额度
 * @param token - NewAPI Token
 * @param baseUrl - NewAPI 基础 URL
 * @param useGoogleFormat - 是否使用 Google API 格式（默认自动检测）
 * @returns 余额信息
 */
export async function getNewApiBalance(
  token: string,
  baseUrl: string = "https://off.092420.xyz",
  useGoogleFormat?: boolean
): Promise<NewApiBalanceResponse | null> {
  try {
    // 自动检测：如果 baseUrl 包含 generativelanguage.googleapis.com，使用 Google 格式
    const isGoogleApi = useGoogleFormat ?? baseUrl.includes("generativelanguage.googleapis.com");

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };

    // Google API 使用 x-goog-api-key，OpenAI 兼容 API 使用 Authorization Bearer
    if (isGoogleApi) {
      headers["x-goog-api-key"] = token;
    } else {
      headers["Authorization"] = `Bearer ${token}`;
    }

    // 1. 获取总额度 (hard_limit_usd)
    // 注意：Google Generative AI API 没有 billing 端点，这仅适用于 OpenAI 兼容 API
    const subscriptionResponse = await fetch(
      `${baseUrl}/v1/dashboard/billing/subscription`,
      {
        method: "GET",
        headers,
      }
    );

    if (subscriptionResponse.status !== 200) {
      console.error("Failed to fetch subscription");
      return {
        balance: 0,
        currency: "USD",
      };
    }

    const subscriptionData = await subscriptionResponse.json();
    const hardLimitUsd = subscriptionData.hard_limit_usd || 100; // 满额默认100

    // 特殊情况：100000000 表示无限额度
    if (hardLimitUsd === 100000000) {
      return {
        balance: Infinity,
        currency: "USD",
      };
    }

    // 2. 获取已用额度 (total_usage / 100)
    const usageResponse = await fetch(
      `${baseUrl}/v1/dashboard/billing/usage`,
      {
        method: "GET",
        headers,
      }
    );

    if (usageResponse.status !== 200) {
      console.error("Failed to fetch usage");
      // 如果获取使用量失败，返回总额度
      return {
        balance: hardLimitUsd,
        currency: "USD",
      };
    }

    const usageData = await usageResponse.json();
    const totalUsage = (usageData.total_usage || 0) / 100;

    // 3. 计算剩余额度
    const remainingBalance = hardLimitUsd - totalUsage;

    return {
      balance: Math.max(0, remainingBalance), // 确保不为负数
      currency: "USD",
    };
  } catch (error) {
    console.error("Failed to get NewAPI balance:", error);
    return {
      balance: 0,
      currency: "USD",
    };
  }
}

/**
 * 刷新余额（获取最新余额）
 * @param token - NewAPI Token
 * @param baseUrl - NewAPI 基础 URL
 * @param useGoogleFormat - 是否使用 Google API 格式（默认自动检测）
 * @returns 余额信息
 */
export async function refreshBalance(
  token: string,
  baseUrl: string = "https://off.092420.xyz",
  useGoogleFormat?: boolean
): Promise<number> {
  const balanceData = await getNewApiBalance(token, baseUrl, useGoogleFormat);
  return balanceData?.balance ?? 0;
}
