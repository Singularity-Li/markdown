# Markdown 语法演示

这是一个覆盖全部常用与冷门 Markdown 语法的示例文件。右上角开关可切换「预览 / 编辑」，右上角按钮可打开文件或文件夹。

## 中英文切换示例

[中文](#zh) | [English](#en)

<h2 id="zh">中文版</h2>

这是中文内容。点击上方 **English**，会跳转到文末的英文版；在英文版点击 **中文** 可返回这里。

此示例使用 Markdown 链接和 HTML 自定义锚点，可离线使用。

---

## 1. 标题层级

# 一级标题 H1
## 二级标题 H2
### 三级标题 H3
#### 四级标题 H4
##### 五级标题 H5
###### 六级标题 H6

---

## 2. 文本样式

这是**加粗文本**，这是*斜体文本*，这是***加粗+斜体***，这是~~删除线~~，这是`行内代码`，还有 <u>下划线</u> 与 <mark>高亮</mark>。

转义字符：\* 星号 \# 井号 \` 反引号，以及下标 H~2~O / 上标 x^2^。

---

## 3. 列表

### 无序列表

- 苹果
- 香蕉
  - 嵌套一级
    - 嵌套二级
- 樱桃

### 有序列表

1. 打开文件
2. 编辑内容
3. 按 `Cmd + S` 保存
   1. 嵌套子步骤
   2. 继续子步骤

### 任务列表

- [x] 已完成的任务
- [ ] 未完成的任务
- [ ] 还有一项待办

---

## 4. 引用

> 这是一个引用块。
>
> > 这是嵌套引用，可以有多层。液态玻璃效果让阅读更舒适。

---

## 5. 代码块

### Swift（带语法高亮）

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Hello, Liquid Glass")
                .glassEffect()
            Button("点击我") { print("hi") }
                .buttonStyle(.glass)
        }
        .padding()
    }
}
```

### Python

```python
def fibonacci(n: int) -> list[int]:
    a, b = 0, 1
    result = []
    for _ in range(n):
        result.append(a)
        a, b = b, a + b
    return result


print(fibonacci(10))
```

### 无语言标注的代码

```
这是一个没有语言标注的代码块，
Markdown 会以等宽字体原样展示。
```

---

## 6. 表格

| 特性         | 支持情况 | 说明             |
| ------------ | :------: | ---------------- |
| 表格         |    ✅    | 含对齐           |
| 代码高亮     |    ✅    | 40+ 语言         |
| 任务列表     |    ✅    | 复选框           |
| 图片         |    ✅    | 相对/远程路径    |

### 对齐示例

| 左对齐 | 居中 | 右对齐 |
| :----- | :--: | -----: |
| a      |  b   |     10 |
| 长内容 |  x   |    100 |

---

## 7. 链接与自动链接

- [Markdown 官方说明](https://daringfireball.net/projects/markdown/)
- [Apple Developer](https://developer.apple.com/)
- 自动链接：https://www.apple.com
- 邮箱链接：<someone@example.com>
- 锚点跳转：[回到顶部](#markdown-语法演示)

---

## 8. 图片

### 相对路径图片（与本文件同目录的 sample.png）

![本地示例图片](sample.png)

### 远程图片（需联网）

![远程占位图](https://picsum.photos/seed/markdown/640/320)

---

## 9. 分割线

上面是一条分割线。

***

下面是另一条（三个星号形式）。

---

## 10. HTML 内嵌

<p style="color:#ff6b6b;font-weight:bold;">这是内嵌 HTML 的彩色段落。</p>

<details>
<summary>点击展开折叠内容</summary>

这里是折叠区内的 Markdown 内容，同样支持 **加粗** 与 `代码`。

</details>

---

## 11. 其他冷门写法

- 定义列表（部分渲染器支持）：

: 这是一个术语
: 术语的解释写在这里

- 脚注占位示例：这是一个句子[^1]。

[^1]: 脚注内容（注意：GFM 默认渲染器可能不显示脚注，属正常现象）。

---

> **试试看**：切到「编辑」模式随意修改，再切回「预览」观察变化；按 `Cmd + S` 保存；关闭前若未保存会弹出提醒。

---

<h2 id="en">English version</h2>

[中文](#zh) | [English](#en)

This is the English version. Click **中文** to return to the Chinese section near the top.

Language links use explicit HTML anchors and work offline in preview mode.
