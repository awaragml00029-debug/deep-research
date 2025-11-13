"use client";

import { useEffect, useRef } from "react";
import { useThemeStore, THEME_COLORS, type ThemeColorKey } from "@/store/theme";
import { Palette } from "lucide-react";

export default function ThemeSelector() {
  const { currentTheme, isOpen, setTheme, toggleOpen, setOpen } =
    useThemeStore();
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

  return (
    <div className="relative" ref={containerRef}>
      {/* 调色板按钮 */}
      <button
        onClick={toggleOpen}
        className="p-2 rounded-lg hover:bg-secondary/80 transition-colors"
        title="Theme Color Picker"
        aria-label="Theme Color Picker"
      >
        <Palette className="w-5 h-5" />
      </button>

      {/* 颜色选择浮层 */}
      {isOpen && (
        <div className="absolute right-0 top-full mt-2 p-4 bg-background border border-border rounded-lg shadow-lg z-50 min-w-[240px]">
          <div className="text-sm font-medium mb-3">Choose Theme Color</div>
          <div className="flex flex-wrap gap-3">
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
                  className="group relative flex flex-col items-center gap-2"
                  title={theme.name}
                  aria-label={theme.name}
                >
                  {/* 颜色圆圈 */}
                  <div
                    className={`w-6 h-6 rounded-full transition-all duration-200 ${
                      isActive
                        ? "ring-2 ring-offset-2 ring-offset-background scale-110"
                        : "hover:scale-105"
                    }`}
                    style={{
                      backgroundColor: theme.value,
                      ...(isActive && { "--tw-ring-color": theme.value } as React.CSSProperties),
                    }}
                  />
                  {/* 颜色名称 */}
                  <span className="text-xs text-muted-foreground group-hover:text-foreground transition-colors">
                    {theme.name.split(" ")[0]}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
