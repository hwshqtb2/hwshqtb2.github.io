---
layout: test

title: 测试
main_part: -1

# 编辑器初始代码（声明后页面正文引入组件即可使用；省略此项则用组件内置的 Hello World 示例）
code: |
  #include <stdio.h>
  int main() {
      printf("Hello, World!\n");
      return 0;
  }
---

{% include code.html %}
