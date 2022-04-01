require "SDK/FunckHelper"

--读取词库
local wordArrTextPath = "WordLibrary/AllWord.text"
local allWordArr = FunckHelper:ReadWordArrFromFile(wordArrTextPath)

--进行导出的文字字符串生成
local oringinRenameTxtPath = "ObfuscatorText/Origin/RenameMap.txt"
local handledRenameTxtPath = "ObfuscatorText/Handled/RenameMap.txt"
local usedWordMap = {} --已经使用过的单词Map
local handledRenameTxtStr = nil
FunckHelper:HandTextFilePerLine(
    oringinRenameTxtPath,
    function(word)
        --获取替换词
        local renameWord = word
        if FunckHelper:IsKeyWord(word) then
            renameWord = FunckHelper:GenerateRenameWord(allWordArr, usedWordMap)
        end
        --写入文本字符串
        if handledRenameTxtStr then
            handledRenameTxtStr = string.format("%s\n%s", handledRenameTxtStr, renameWord)
        else
            handledRenameTxtStr = renameWord
        end
    end
)
--写入文本
FunckHelper:WriteFile(handledRenameTxtPath, handledRenameTxtStr)
