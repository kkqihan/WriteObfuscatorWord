json = require("Library.Json.json")
require("SDK/FunckHelper")

--读取词库
local wordArrTextPath = "WordLibrary/AllWord.text"
local allWordArr = FunckHelper:ReadWordArrFromFile(wordArrTextPath)

--进行导出的文字字符串生成
local oringinRenameTxtPath = "ObfuscatorText/Origin/RenameMap.json"
local handledRenameTxtPath = "ObfuscatorText/Handled/RenameMap.json"
local usedWordMap = {} --已经使用过的单词Map
local handledRenameTxtStr, renameNum =
    FunckHelper:HandTextFilePerRenameWord(
    oringinRenameTxtPath,
    function()
        return FunckHelper:GenerateRenameWord(allWordArr, usedWordMap)
    end
)
--写入文本
FunckHelper:WriteFile(handledRenameTxtPath, handledRenameTxtStr)
--打印日志
print(string.format("Reaname complete, rename [%d] world!", renameNum))
