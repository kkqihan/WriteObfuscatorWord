require "SDK/FunckHelper"

--读取词库
local wordArrTextPath = "WordLibrary/AllWord.text"
local allWordArr = FunckHelper:ReadWordArrFromFile(wordArrTextPath)

--生成新混淆词的闭包
local usedWordMap = {}
local function generateWord()
    return FunckHelper:GenerateRenameWord(allWordArr, usedWordMap)
end

local mode = arg and arg[1] or "txt"

if mode == "json" then
    print("[Mode] json")
    local originJsonPath = "ObfuscatorText/Origin/RenameMap_Result.json"
    local handledJsonPath = "ObfuscatorText/Handled/RenameMap_Source.json"

    local root, err = FunckHelper:ReadJsonFile(originJsonPath)
    if not root then
        print("Read json failed: "..tostring(err))
        os.exit(1)
    end

    --处理所有 Mapping value
    FunckHelper:ProcessAllMappingValue(root, generateWord, usedWordMap)

    --写回 JSON
    FunckHelper:WriteJsonFile(handledJsonPath, root)
    print("Json Mapping processed and saved to "..handledJsonPath)
else
    print("[Mode] txt")
    --进行导出的文字字符串生成
    local oringinRenameTxtPath = "ObfuscatorText/Origin/RenameMap.txt"
    local handledRenameTxtPath = "ObfuscatorText/Handled/RenameMap.txt"
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
end
