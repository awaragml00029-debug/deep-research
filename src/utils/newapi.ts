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
    // 查询用户信息（包含余额）
    const response = await fetch(`${baseUrl}/api/user/self`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    });

    if (response.status === 200) {
      const data = await response.json();

      // NewAPI 返回格式: { success: true, data: { quota: number, ... } }
      if (data && data.success && data.data) {
        const quota = data.data.quota || 0;
        // quota 是整数，需要除以 500000 转换为美元
        const balance = quota / 500000;

        return {
          balance: balance,
          currency: "USD",
        };
      }
    }

    // 如果查询失败，返回 0
    return {
      balance: 0,
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
