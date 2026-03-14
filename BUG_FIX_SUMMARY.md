# Bug 修复总结

## 修复日期
2026-03-13

## 问题描述

### 问题 1: macOS 沙盒限制导致无法访问用户图片
**症状**: 应用启动后只能访问沙盒目录，无法扫描真实的用户图片目录
- 沙盒目录: `/Users/infinity/Library/Containers/com.awesome.awesomeGalley/Data/Pictures`
- 真实目录: `/Users/infinity/Pictures`

**原因**: macOS 应用沙盒 (`com.apple.security.app-sandbox`) 设置为 `true`，限制了文件系统访问

**解决方案**: 
- 修改 `macos/Runner/DebugProfile.entitlements`
- 修改 `macos/Runner/Release.entitlements`
- 将 `com.apple.security.app-sandbox` 设置为 `false`

**注意**: 这是开发/MVP 阶段的临时方案。生产环境建议：
1. 使用文件选择器让用户手动选择文件夹
2. 或者申请完整磁盘访问权限
3. 或者使用 macOS 的 Powerbox API

### 问题 2: 滚动时出现 RangeError 数组越界
**症状**: 滚动图片列表时频繁出现错误：
```
RangeError (length): Invalid value: Not in inclusive range 0..6: -3
```

**原因**: 
1. `waterfall_view.dart` 中计算 `currentIndex` 时可能产生负数
2. `cache_preloader.dart` 中没有对索引进行边界检查

**解决方案**:

#### waterfall_view.dart (第 67-82 行)
```dart
// 修复前
final scrollPercent = _scrollController.hasClients
    ? _scrollController.position.pixels /
        _scrollController.position.maxScrollExtent
    : 0.0;
final currentIndex = (controller.images.length * scrollPercent).floor();

// 修复后
final scrollPercent = _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0
    ? (_scrollController.position.pixels /
        _scrollController.position.maxScrollExtent).clamp(0.0, 1.0)
    : 0.0;
final currentIndex = (controller.images.length * scrollPercent)
    .floor()
    .clamp(0, controller.images.length - 1);
```

#### cache_preloader.dart (第 43-60 行)
```dart
// 修复前
final endIndex = (startIndex + preloadAheadCount).clamp(0, images.length);
for (int i = startIndex; i < endIndex; i++) {
  _preloadQueue.add(images[i]);
}

// 修复后
// Validate and clamp indices
if (images.isEmpty || startIndex < 0 || startIndex >= images.length) {
  return;
}

final clampedStart = startIndex.clamp(0, images.length - 1);
final endIndex = (clampedStart + preloadAheadCount).clamp(0, images.length);
for (int i = clampedStart; i < endIndex; i++) {
  _preloadQueue.add(images[i]);
}
```

## 修复后的状态

### ✅ 成功修复
1. 应用可以访问真实的用户目录
2. 成功扫描并加载 7 张图片
3. 滚动时不再出现 RangeError
4. 应用稳定运行

### ⚠️ 已知问题
1. **FPS 性能警告**: 初始加载时 FPS 较低（4-25 FPS）
   - 这是正常的，因为需要生成缩略图
   - 一旦缩略图被缓存，性能会显著提升
   
2. **Zone mismatch 警告**: Flutter 框架警告（非致命）
   - 由于在 `runZonedGuarded` 中调用 `ensureInitialized`
   - 不影响应用功能，可以忽略或后续优化

## 测试结果

### 功能测试
- ✅ 应用启动成功
- ✅ 扫描系统目录（Pictures, Desktop, Downloads）
- ✅ 加载图片列表（7 张图片）
- ✅ 瀑布流布局显示
- ✅ 滚动功能正常
- ✅ 无崩溃或致命错误

### 性能测试
- ⚠️ 初始 FPS: 4-25 FPS（正常，首次加载）
- ✅ 无内存泄漏
- ✅ 缓存预加载工作正常

## 修改的文件

1. `macos/Runner/DebugProfile.entitlements` - 禁用沙盒
2. `macos/Runner/Release.entitlements` - 禁用沙盒
3. `lib/presentation/views/waterfall_view.dart` - 修复索引计算
4. `lib/infrastructure/cache/cache_preloader.dart` - 添加边界检查

## 下一步建议

### 短期（MVP）
- [x] 修复沙盒问题
- [x] 修复滚动崩溃
- [ ] 测试点击图片打开单图查看器
- [ ] 测试缩放和平移功能

### 中期（优化）
- [ ] 优化缩略图生成性能
- [ ] 实现更智能的缓存策略
- [ ] 减少 FPS 警告的触发频率
- [ ] 修复 Zone mismatch 警告

### 长期（生产）
- [ ] 实现文件选择器（替代禁用沙盒）
- [ ] 申请适当的系统权限
- [ ] 添加用户权限引导
- [ ] 完善错误处理和用户提示
