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
 * @returns 验证结果
 */
export async function validateNewApiToken(
  token: string,
  baseUrl: string = "https://off.092420.xyz"
): Promise<NewApiValidationResponse> {
  try {
    const response = await fetch(`${baseUrl}/v1/models`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
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
 * @returns 余额信息
 */
export async function getNewApiBalance(
  token: string,
  baseUrl: string = "https://off.092420.xyz"
): Promise<NewApiBalanceResponse | null> {
  try {
    // 1. 获取总额度 (hard_limit_usd)
    const subscriptionResponse = await fetch(
      `${baseUrl}/v1/dashboard/billing/subscription`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
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
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
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
 * @returns 余额信息
 */
export async function refreshBalance(
  token: string,
  baseUrl: string = "https://off.092420.xyz"
): Promise<number> {
  const balanceData = await getNewApiBalance(token, baseUrl);
  return balanceData?.balance ?? 0;
}
