FunckHelper = {}

--设置随机种子
math.randomseed(os.time())

function FunckHelper:Test()
    print("FunckHelper:Test()")
end

--从文本读取词库
function FunckHelper:ReadWordArrFromFile(path)
    local wordArr = {}

    --读取文件
    ----打开文件
    local file = io.open(path, "r")
    ----逐行读取
    while (true) do
        local word = file:read("*l")
        if word then
            -- print(word)
            table.insert(wordArr, word)
        else
            break
        end
    end
    ----关闭文件
    io.close(file)
    ----打印
    print(
        string.format(
            'File[%s] read end. Have [%d] word. etc "%s","%s", ... "%s"',
            path,
            #wordArr,
            wordArr[1],
            wordArr[2],
            wordArr[#wordArr]
        )
    )

    return wordArr
end

--写入文件
function FunckHelper:WriteFile(path, content)
    local file = io.open(path, "w")
    file:write(content)
    file:close()
end

--一行一行的处理文本
function FunckHelper:HandTextFilePerLine(path, handleFunc)
    --读取文件
    ----打开文件
    local file = io.open(path, "r")
    ----逐行读取
    while (true) do
        local lineStr = file:read("*l")
        if lineStr then
            handleFunc(lineStr)
        else
            break
        end
    end
    ----关闭文件
    io.close(file)
end

--浅拷贝数组
function FunckHelper:ShallowCopyArr(arr)
    local copyArr = {}

    for key, val in pairs(arr) do
        copyArr[key] = val
    end

    return copyArr
end

--是否时需要重写的关键字
function FunckHelper:IsKeyWord(word)
    local isKeyWord = true

    --检查长度
    local wordLength = #word
    if wordLength > 5 then
        isKeyWord = false
    end
    --检查字符内容
    for charIdx = 1, wordLength do
        local char = string.sub(word, charIdx, charIdx)
        if char >= "a" and char <= "z" then
        else
            isKeyWord = false
            break
        end
    end

    -- if not isKeyWord then
    --     print(string.format("%s false!!!!", word))
    -- end

    return isKeyWord
end

--生成重命名的单词
function FunckHelper:GenerateRenameWord(allWordArr, unuseWordArr, usedWordMap)
    local newWord = nil

    --寻找新单词
    local unuseWordLengh = #unuseWordArr
    if unuseWordLengh > 0 then --先从没用过的单词数组中找
        local wordIdx = math.random(1, unuseWordLengh)
        newWord = table.remove(unuseWordArr, wordIdx)
    else --没有就组合生成
        --进行合成
        local composeWord = ""
        local allWordNum = #allWordArr
        local tryComposeCount = 2
        while (true) do
            --单词拼接
            for composeIdx = 1, tryComposeCount, 1 do
                local wordIdx = math.random(1, allWordNum)
                composeWord = composeWord .. allWordArr[wordIdx]
            end
            --判断是否合格
            if usedWordMap[composeWord] then --已经使用过，则增加长度，继续组合
                tryComposeCount = tryComposeCount + 1
            else --没有用过，则采用
                newWord = composeWord
                break
            end
        end

        --更新已经使用过单词的列表,防止生成时重复
        usedWordMap[newWord] = true
    end

    return newWord
end
