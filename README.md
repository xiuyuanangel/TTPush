# TTPush

## 项目简介

TTPush是一个基于HarmonyOS的应用程序，可以通过将消息推送到手机。

## 项目结构

```
TTPush/
├── AppScope/            # 应用级配置文件
├── entry/               # 应用入口模块
│   ├── src/             # 源代码目录
│   ├── build/           # 构建输出目录
│   └── resources/       # 资源文件目录
├── build/               # 项目构建输出目录
├── oh_modules/          # 依赖模块目录
└── hvigor/              # 构建工具配置
```

## 开发环境要求

- DevEco Studio 3.0或更高版本
- HarmonyOS SDK 3.0或更高版本
- Node.js 12.0或更高版本

## 安装与运行

1. 克隆项目到本地
   ```bash
   git clone <repository-url>
   ```

2. 使用DevEco Studio打开项目

3. 同步项目依赖
   ```bash
   npm install
   ```

4. 构建项目
   ```bash
   hvigor build
   ```

5. 运行项目
   在DevEco Studio中选择一个模拟器或真机设备，点击"运行"按钮。

## 依赖项

项目使用了以下华为AGConnect服务：
- @hw-agconnect/auth-ohos: ^1.1.2
- @hw-agconnect/api-ohos: ^1.1.2
- @hw-agconnect/core-ohos: ^1.1.2

## 许可证

本项目采用Apache 2.0许可证。详情请参阅[LICENSE](LICENSE)文件。