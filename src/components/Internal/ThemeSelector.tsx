"use client";

import { useEffect, useRef } from "react";
import { useThemeStore, THEME_COLORS, type ThemeColorKey } from "@/store/theme";
import { useSettingStore } from "@/store/setting";
import { Palette } from "lucide-react";

export default function ThemeSelector() {
  const { currentTheme, isOpen, setTheme, toggleOpen, setOpen } =
    useThemeStore();
  const { keyStatus } = useSettingStore();
  const containerRef = useRef<HTMLDivElement>(null);

  // 点击外部区域关闭选择器
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setOpen(false);
      }
    }

    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
      return () => {
        document.removeEventListener("mousedown", handleClickOutside);
      };
    }
  }, [isOpen, setOpen]);

  // 未验证状态
  const isDisabled = keyStatus !== "validated";

  return (
    <div className="relative" ref={containerRef}>
      {/* 调色板按钮 */}
      <button
        onClick={isDisabled ? undefined : toggleOpen}
        disabled={isDisabled}
        className={`p-2 rounded-lg transition-colors ${
          isDisabled
            ? "opacity-50 cursor-not-allowed"
            : "hover:bg-secondary/80"
        }`}
        title={
          isDisabled
            ? "Please validate API Key in Settings to unlock theme picker"
            : "Theme Color Picker"
        }
        aria-label="Theme Color Picker"
      >
        <Palette className="w-5 h-5" />
      </button>

      {/* 颜色选择浮层 - 只有验证后才显示 */}
      {isOpen && !isDisabled && (
        <div className="absolute right-0 top-full mt-2 p-3 bg-background border border-border rounded-lg shadow-lg z-50">
          <div className="flex items-center gap-2">
            {(Object.keys(THEME_COLORS) as ThemeColorKey[]).map((themeKey) => {
              const theme = THEME_COLORS[themeKey];
              const isActive = currentTheme === themeKey;

              return (
                <button
                  key={themeKey}
                  onClick={() => {
                    setTheme(themeKey);
                    setOpen(false);
                  }}
                  className="relative"
                  title={theme.name}
                  aria-label={theme.name}
                >
                  {/* 颜色圆圈 - 调淡透明度 */}
                  <div
                    className={`w-6 h-6 rounded-full transition-all duration-200 ${
                      isActive
                        ? "ring-2 ring-offset-2 ring-offset-background scale-110"
                        : "hover:scale-105 opacity-60 hover:opacity-100"
                    }`}
                    style={{
                      backgroundColor: theme.value,
                      ...(isActive && { "--tw-ring-color": theme.value } as React.CSSProperties),
                    }}
                  />
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
