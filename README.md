# CircleMinder

**CircleMinder** 是一款适用于 macOS 的极简风格提醒工具。它拥有精致的“毛玻璃 (Glassmorphism)”视觉效果，通过美观且非侵入式的浮窗提醒，帮助您专注于工作流的同时不错过重要事项。

## 主要功能

*   **优雅的浮窗提醒**：提醒窗口以精美的半透明浮层形式出现，置顶但不抢占焦点，支持点击穿透。
*   **灵活的时间间隔**：支持自定义循环提醒周期（例如：每 5 分钟提醒一次）。
*   **智能自动消失**：提醒浮窗会在设定时长后自动淡出，无需手动关闭。
*   **休眠感知**：针对 macOS 休眠机制优化，避免系统唤醒时弹出“积压”的过期提醒。
*   **原生体验**：完全遵循 macOS 设计规范，完美融入您的桌面环境。

## 安装指南

请在 GitHub 的 [Releases](releases) 页面下载最新的 `.dmg` 安装包，或者选择从源码编译。

## 从源码构建

CircleMinder 采用 Swift 和 SwiftUI 开发。

1.  克隆仓库：
    ```bash
    git clone https://github.com/yourname/CircleMinder.git
    cd CircleMinder
    ```

2.  使用 Swift Package Manager 运行：
    ```bash
    swift run
    ```

3.  编译 Release 版本：
    ```bash
    swift build -c release
    ```

## 系统要求

*   macOS 14.0 (Sonoma) 或更高版本。

## 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。
