# King of Sleepers — Android / iOS 登录修复与测试说明

本 ZIP 以 2026-10-20 下载的 `main` 为基础。仅修改登录相关 Dart 文件和原本引用不存在类的测试文件；其余 Nap Spots、地图、Rating 页面保留。

## 本次已修复

- 在 **debug** 构建下，登录错误显示 Firebase SDK 的错误代码、经过简单脱敏的详情（过去一律显示 `Authentication error (unknown)`）；**release** 模式不展示内部诊断信息。
- 登录页底部显示真实运行时 Firebase Project ID，便于确定是否还连着旧项目（只在 debug 构建显示）。
- 邮箱登录/注册时不再对密码自动 `trim()`（含首尾空格的密码必须按原样发送）。
- GoogleSignIn 7.x 初始化一次，初始化失败可以重试，且处理缺失 ID token / 异常。
- 防止异步操作完成后 Widget 已被销毁而调用 `setState`。
- 修复 `test/widget_test.dart` 原先引用不存在的 `SleepingKingApp` 类，改成无网络的错误映射及 Firebase 配置测试。

## Android (Windows + VS Code)

1. **新建测试文件夹**解压 ZIP，VS Code `File > Open Folder` 打开里面有 `pubspec.yaml` 的根目录。**不要覆盖原 GitHub main 文件夹**，先独立测试。
2. 打开 Android Studio `Device Manager` 启动 Pixel 模拟器。模拟器需要能通过 Chrome 访问网页（有网络）。
3. VS Code 终端执行：

   ```powershell
   flutter pub get
   flutter test
   flutter devices
   flutter run -d emulator-5554
   ```

   把 `emulator-5554` 替换为 `flutter devices` 实际显示的 Android 设备 ID。`flutter run` 需保持终端打开以查看日志。
4. 登录页底部确认 `Firebase project: king-of-sleepers-c221d`，用**你自己有权限的测试账号**登录。密码别发到聊天里。如果登录失败，把屏幕上 `Debug: ...` 和后面的消息截图（遮挡私人数据）发来。
5. 需要验证：已知正确密码登录、错误密码提示、重置密码（若邮件可用）、用全新测试邮箱注册、退出后再次登录、Google 登录、登录后 Nap Spots/Rating 是否加载。

## iOS (必须在 Mac 上使用 Xcode)

1. 用同样的 ZIP 在 macOS 上安装 Xcode、CocoaPods 和 Flutter，执行 `flutter doctor`、`flutter pub get`。
2. 启动 iOS Simulator，使用 `flutter devices` 查找 iPhone 设备 ID，再运行 `flutter run -d <设备ID>`。
3. 进行同样的邮箱登录与 Google 登录测试。
4. `ios/Runner/GoogleService-Info.plist` 中项目 ID 是 `king-of-sleepers-c221d`，Bundle ID 为 `com.example.sleepingKing`，已与 `ios/Runner.xcodeproj` 对齐。`ios/Runner/Info.plist` 中也有 iOS Google 登录所需的 `GIDClientID` 与 URL Scheme。

## 若 Google 登录仍然失败

- Firebase Console > Authentication > Sign-in method 中确认 Google 与 Email/Password 都已经启用。
- Android：到 Firebase 项目设置 > Android 应用，确认添加的 **SHA-1 / SHA-256** 与本机 debug key 一致。可在 Windows 的项目目录 `android` 中执行 `./gradlew signingReport` （PowerShell 可用 `.\gradlew.bat signingReport`）；如果 SHA 不同，添加到 Firebase，然后下载新的 `google-services.json`。**不要盲目替换现有配置**。
- 如果错误是 `unknown`，请查看该错误下方更具体的 Debug 信息；单凭 `unknown` 无法断言是旧 Firebase 还是密码错误。
- Google 登录还可能受模拟器 Google Play Services / 网络连接影响。

## 测试范围说明

当前修改环境没有 Flutter SDK、Android 模拟器、macOS/Xcode 或用户登录凭据，因此无法在这里真实运行 `flutter test`、Android/iOS 编译或 Firebase 在线登录。本包做了静态检查与 Android/iOS 的配置一致性检查，但 **不代表已验证登录成功**。请在 VS Code 和 Mac 模拟器进行以上实际验证。

不要分享登录密码、Google ID token、完整账号恢复链接或私有服务账号密钥。
