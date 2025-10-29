# WriteObfuscatorWord
## 简介
  处理Unity插件Obfuscator-Free生成的RenameMap.txt，针对重命名的函数名、字段等，使用更有意义的单词，替换掉a、b、c、d...等。
  
## 工程说明
ObfuscatorText目录为处理Rename文件的存放目录
WordLibrary目录为自定义词库目录

## 使用方法
安装Lua环境后：

1. 处理原始 RenameMap.txt （默认模式）
  lua main.lua
  输出: ObfuscatorText/Handled/RenameMap.txt

2. 处理 RenameMap_Result.json （仅替换所有层级中 key == "Mapping" 的对象里字符串值, 且值是纯字母时才替换）
  lua main.lua json
  输出: ObfuscatorText/Handled/RenameMap_Result.json

词库来源: `WordLibrary/AllWord.text`，生成时会组合随机词避免重复。
