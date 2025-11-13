"use client";

import { useEffect, useState } from "react";
import { useSettingStore } from "@/store/setting";
import { refreshBalance } from "@/utils/newapi";
import { Coins, AlertTriangle, RefreshCw } from "lucide-react";
import { toast } from "sonner";

const BALANCE_THRESHOLD = 10; // $10
const AUTO_REFRESH_INTERVAL = 5 * 60 * 1000; // 5分钟

export default function BalanceButton() {
  const {
    keyStatus,
    balance,
    apiKey,
    apiProxy,
    setBalance,
    updateBalanceTimestamp,
  } = useSettingStore();

  const [isRefreshing, setIsRefreshing] = useState(false);

  // 自动刷新余额
  useEffect(() => {
    if (keyStatus !== "validated" || !apiKey) {
      return;
    }

    // 立即刷新一次
    handleRefreshBalance();

    // 设置定时器
    const intervalId = setInterval(() => {
      handleRefreshBalance(true); // 静默刷新
    }, AUTO_REFRESH_INTERVAL);

    return () => clearInterval(intervalId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [keyStatus, apiKey]);

  const handleRefreshBalance = async (silent = false) => {
    if (isRefreshing || !apiKey) return;

    setIsRefreshing(true);

    try {
      const newBalance = await refreshBalance(apiKey, apiProxy || "https://off.092420.xyz");
      setBalance(newBalance);
      updateBalanceTimestamp();

      if (!silent) {
        toast.success(`Balance refreshed: $${newBalance.toFixed(2)}`);
      }
    } catch (error) {
      if (!silent) {
        toast.error("Failed to refresh balance");
      }
      console.error("Refresh balance error:", error);
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleBalanceClick = () => {
    if (keyStatus === "validated" && balance <= BALANCE_THRESHOLD) {
      const baseUrl = apiProxy || "https://off.092420.xyz";
      window.open(`${baseUrl}/topup`, "_blank");
    }
  };

  // 未验证状态
  if (keyStatus !== "validated") {
    return (
      <div className="flex items-center gap-2">
        <button
          disabled
          className="flex items-center gap-2 px-3 py-2 rounded-lg bg-secondary/50 text-muted-foreground cursor-not-allowed"
          title="Please set NewAPI token in Settings to see balance"
        >
          <Coins className="w-4 h-4" />
          <span className="text-sm font-medium">--</span>
        </button>
      </div>
    );
  }

  // 余额充足（> $10）
  if (balance > BALANCE_THRESHOLD) {
    return (
      <div className="flex items-center gap-2">
        <div
          className="flex items-center gap-2 px-3 py-2 rounded-lg bg-amber-50 dark:bg-amber-900/20 cursor-default"
          title={`Balance: $${balance.toFixed(2)}`}
        >
          <span className="text-lg">💰</span>
          <span className="text-sm font-medium text-amber-600 dark:text-amber-400">${balance.toFixed(2)}</span>
        </div>
        {/* 刷新按钮 */}
        <button
          onClick={() => handleRefreshBalance()}
          disabled={isRefreshing}
          className="p-2 rounded-lg hover:bg-secondary/80 transition-colors disabled:opacity-50"
          title="Refresh balance"
          aria-label="Refresh balance"
        >
          <RefreshCw
            className={`w-4 h-4 ${isRefreshing ? "animate-spin" : ""}`}
          />
        </button>
      </div>
    );
  }

  // 余额不足（≤ $10）
  return (
    <div className="flex items-center gap-2">
      <button
        onClick={handleBalanceClick}
        className="flex items-center gap-2 px-3 py-2 rounded-lg bg-secondary/80 hover:bg-secondary transition-colors text-muted-foreground hover:text-foreground"
        title="Click to recharge"
      >
        <Coins className="w-4 h-4" />
        <span className="text-sm font-medium">${balance.toFixed(2)}</span>
        <AlertTriangle className="w-4 h-4 text-orange-500" />
      </button>
      {/* 刷新按钮 */}
      <button
        onClick={() => handleRefreshBalance()}
        disabled={isRefreshing}
        className="p-2 rounded-lg hover:bg-secondary/80 transition-colors disabled:opacity-50"
        title="Refresh balance"
        aria-label="Refresh balance"
      >
        <RefreshCw
          className={`w-4 h-4 ${isRefreshing ? "animate-spin" : ""}`}
        />
      </button>
    </div>
  );
}
