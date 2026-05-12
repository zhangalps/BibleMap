# Bible Map (圣经地图) 🗺️📖

Bible Map 是一款基于 Qt/QML 构建的跨平台应用，旨在帮助用户更直观地结合地理位置来阅读和探索《圣经》。

## ✨ 核心功能 (Features)

- **📍 交互式圣经地图**：直观展示圣经中出现的重要地点，支持缩放、拖拽与点击。内置重要历史路线（如出埃及记、耶稣生平、保罗传道旅程）。
- **📖 沉浸式阅读体验**：集成完整的圣经阅读界面，支持左右滑动翻页，并拥有自动记忆功能，下次打开继续上次的阅读进度。
- **🔍 智能检索与关联**：在地图上点击地点，即可查看曾在该地点发生过的圣经事件和相关经文，并支持一键跳转到详细阅读界面。
- **📱 跨平台支持**：使用 Qt 6 及 QML 技术栈开发，具备出色的性能表现和流畅的手势交互，能完美运行在 Windows、Android 和 iOS 等多个平台。

## 📸 界面预览 (Screenshots)

<div align="center">
  <img width="200" alt="主页地图" src="https://github.com/user-attachments/assets/e4ec1835-4361-4c87-966a-fead65d0afdc" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img width="200" alt="地点概览" src="https://github.com/user-attachments/assets/43603822-e72f-42bd-ab8f-e59cb2544643" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img width="200" alt="相关经文" src="https://github.com/user-attachments/assets/26f93168-e7eb-446a-9cb8-57d66e6fbe11" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img width="200" alt="经文阅读" src="https://github.com/user-attachments/assets/11ddb42c-c39f-40ff-935f-d0eedd985382" />
</div>

<p align="center">
  <i>(从左至右：主页地图视图、点击地点展示弹窗、地点相关经文列表、完整的圣经阅读界面)</i>
</p>

## 🛠️ 技术栈 (Tech Stack)

- **框架引擎**: [Qt 6](https://www.qt.io/)
- **前端开发**: QML (Qt Quick Controls / Layouts / TapHandler)
- **地理信息**: QtLocation / QtPositioning / OSM
- **后端支持**: C++ 
- **本地存储**: SQLite / QtCore Settings
