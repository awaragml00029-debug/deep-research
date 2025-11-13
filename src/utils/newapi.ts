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
 * @param token - NewAPI Token
 * @param baseUrl - NewAPI 基础 URL
 * @returns 余额信息
 */
export async function getNewApiBalance(
  token: string,
  baseUrl: string = "https://off.092420.xyz"
): Promise<NewApiBalanceResponse | null> {
  try {
    // 尝试获取订阅信息（包含余额）
    const response = await fetch(
      `${baseUrl}/v1/dashboard/billing/subscription`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (response.status === 200) {
      const data = await response.json();
      // 根据实际API响应结构调整
      // 假设返回格式为 { balance: number } 或类似结构
      if (data && typeof data.balance === "number") {
        return {
          balance: data.balance,
          currency: data.currency || "USD",
        };
      }
      // 如果API返回的是其他格式，可能需要调整
      // 例如：hard_limit_usd, soft_limit_usd 等
      if (data && typeof data.hard_limit_usd === "number") {
        return {
          balance: data.hard_limit_usd,
          currency: "USD",
        };
      }
    }

    // 如果上面的接口不工作，尝试使用模型列表作为验证
    // 并返回默认余额 0
    const validateResponse = await validateNewApiToken(token, baseUrl);
    if (validateResponse.success) {
      return {
        balance: 0,
        currency: "USD",
      };
    }

    return null;
  } catch (error) {
    console.error("Failed to get NewAPI balance:", error);
    return null;
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
