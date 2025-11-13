"use client";
import { useTranslation } from "react-i18next";
import { Settings, Github, History, BookText } from "lucide-react";
import { Button } from "@/components/Internal/Button";
import { useGlobalStore } from "@/store/global";
import BalanceButton from "@/components/Internal/BalanceButton";
import ThemeSelector from "@/components/Internal/ThemeSelector";

const VERSION = process.env.NEXT_PUBLIC_VERSION;

function Header() {
  const { t } = useTranslation();
  const { setOpenSetting, setOpenHistory, setOpenKnowledge } = useGlobalStore();

  return (
    <>
      <header className="flex justify-between items-center my-6 max-sm:my-4 print:hidden">
        <a href="https://github.com/u14app/deep-research" target="_blank">
          <h1 className="text-left text-xl font-semibold">
            {t("title")}
            <small className="ml-2 font-normal text-base">v{VERSION}</small>
          </h1>
        </a>
        <div className="flex items-center gap-2">
          {/* 余额按钮 */}
          <BalanceButton />

          {/* 主题选择器 */}
          <ThemeSelector />

          {/* GitHub 链接 */}
          <a href="https://github.com/u14app/deep-research" target="_blank">
            <Button
              className="h-8 w-8"
              title={t("openSource")}
              variant="ghost"
              size="icon"
            >
              <Github className="h-5 w-5" />
            </Button>
          </a>

          {/* 历史记录 */}
          <Button
            className="h-8 w-8"
            variant="ghost"
            size="icon"
            title={t("history.title")}
            onClick={() => setOpenHistory(true)}
          >
            <History className="h-5 w-5" />
          </Button>

          {/* 知识库 */}
          <Button
            className="h-8 w-8"
            variant="ghost"
            size="icon"
            title={t("knowledge.title")}
            onClick={() => setOpenKnowledge(true)}
          >
            <BookText />
          </Button>

          {/* 设置 */}
          <Button
            className="h-8 w-8"
            title={t("setting.title")}
            variant="ghost"
            size="icon"
            onClick={() => setOpenSetting(true)}
          >
            <Settings className="h-5 w-5" />
          </Button>
        </div>
      </header>
    </>
  );
}

export default Header;
