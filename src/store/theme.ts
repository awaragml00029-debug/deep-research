import { create } from "zustand";
import { persist } from "zustand/middleware";
import { useSettingStore } from "./setting";

// 预设主题颜色
export const THEME_COLORS = {
  oceanBlue: {
    name: "Ocean Blue",
    value: "#3b82f6",
    primary: "#3b82f6",
    secondary: "#2563eb",
    accent: "#1d4ed8",
  },
  forestGreen: {
    name: "Forest Green",
    value: "#10b981",
    primary: "#10b981",
    secondary: "#059669",
    accent: "#047857",
  },
  royalPurple: {
    name: "Royal Purple",
    value: "#8b5cf6",
    primary: "#8b5cf6",
    secondary: "#7c3aed",
    accent: "#6d28d9",
  },
  sunsetOrange: {
    name: "Sunset Orange",
    value: "#f97316",
    primary: "#f97316",
    secondary: "#ea580c",
    accent: "#c2410c",
  },
  cherryPink: {
    name: "Cherry Pink",
    value: "#ec4899",
    primary: "#ec4899",
    secondary: "#db2777",
    accent: "#be185d",
  },
} as const;

export type ThemeColorKey = keyof typeof THEME_COLORS;

export interface ThemeStore {
  currentTheme: ThemeColorKey;
  isOpen: boolean;
}

export interface ThemeActions {
  setTheme: (theme: ThemeColorKey) => void;
  setRandomTheme: () => void;
  toggleOpen: () => void;
  setOpen: (isOpen: boolean) => void;
}

export const useThemeStore = create(
  persist<ThemeStore & ThemeActions>(
    (set, get) => ({
      currentTheme: "oceanBlue",
      isOpen: false,

      setTheme: (theme: ThemeColorKey) => {
        set({ currentTheme: theme });
        applyTheme(theme);
      },

      setRandomTheme: () => {
        const themes = Object.keys(THEME_COLORS) as ThemeColorKey[];
        const currentTheme = get().currentTheme;
        // 排除当前主题，从剩余主题中随机选择
        const availableThemes = themes.filter((t) => t !== currentTheme);
        const randomTheme =
          availableThemes[Math.floor(Math.random() * availableThemes.length)];
        get().setTheme(randomTheme);
      },

      toggleOpen: () => set((state) => ({ isOpen: !state.isOpen })),
      setOpen: (isOpen: boolean) => set({ isOpen }),
    }),
    {
      name: "theme",
      onRehydrateStorage: () => (state) => {
        // 恢复主题时检查验证状态
        if (state?.currentTheme) {
          const { keyStatus } = useSettingStore.getState();
          if (keyStatus === "validated") {
            applyTheme(state.currentTheme);
          } else {
            // 未验证时使用默认黑色（不应用主题）
            removeTheme();
          }
        }
      },
    }
  )
);

// 将主题应用到DOM
function applyTheme(theme: ThemeColorKey) {
  const colors = THEME_COLORS[theme];
  const root = document.documentElement;

  // 设置CSS变量
  root.style.setProperty("--theme-primary", colors.primary);
  root.style.setProperty("--theme-secondary", colors.secondary);
  root.style.setProperty("--theme-accent", colors.accent);

  // 设置data-theme属性，方便CSS选择器使用
  root.setAttribute("data-theme", theme);
}

// 移除主题，恢复默认
function removeTheme() {
  const root = document.documentElement;
  root.style.removeProperty("--theme-primary");
  root.style.removeProperty("--theme-secondary");
  root.style.removeProperty("--theme-accent");
  root.removeAttribute("data-theme");
}
