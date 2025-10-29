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

--简易JSON解析: 仅支持本项目需要的对象/字符串/嵌套结构，不支持转义复杂情况
--返回Lua表
function FunckHelper:ReadJsonFile(path)
    local file = io.open(path, "r")
    if not file then return nil, "open json file failed" end
    local content = file:read("*a")
    file:close()

    -- 去掉注释（如果有）
    content = content:gsub("//%[%].-\n", "")

    local pos = 1
    local len = #content

    local function skipWs()
        while true do
            local c = content:sub(pos,pos)
            if c == '' then break end
            if c == ' ' or c == '\n' or c=='\r' or c=='\t' then
                pos = pos + 1
            else
                break
            end
        end
    end

    local function parseString()
        local quote = content:sub(pos,pos)
        if quote ~= '"' then return nil, 'expect quote' end
        pos = pos + 1
        local startPos = pos
        local buf = {}
        while pos <= len do
            local ch = content:sub(pos,pos)
            if ch == '"' then
                local s = table.concat(buf)
                pos = pos + 1
                return s
            elseif ch == '\\' then
                -- 简化: 只处理 \" 和 \\ 两种
                local nextc = content:sub(pos+1,pos+1)
                if nextc == '"' or nextc == '\\' then
                    table.insert(buf, nextc)
                    pos = pos + 2
                else
                    -- 其它转义直接略过
                    table.insert(buf, nextc)
                    pos = pos + 2
                end
            else
                table.insert(buf, ch)
                pos = pos + 1
            end
        end
        return nil, 'unterminated string'
    end

    local function parseNumber()
        local startPos = pos
        while pos <= len do
            local c = content:sub(pos,pos)
            if c == '' or (not c:match("[0-9%+%-%e%E%.]")) then
                break
            end
            pos = pos + 1
        end
        local numStr = content:sub(startPos, pos-1)
        local num = tonumber(numStr)
        return num
    end

    local function parseLiteral(lit, val)
        if content:sub(pos, pos + #lit -1) == lit then
            pos = pos + #lit
            return val
        end
        return nil, 'bad literal'
    end

    local parseValue

    local function parseArray()
        local arr = {}
        pos = pos + 1 -- skip [
        skipWs()
        if content:sub(pos,pos) == ']' then
            pos = pos + 1
            return arr
        end
        while true do
            skipWs()
            local v,err = parseValue()
            if err then return nil, err end
            table.insert(arr, v)
            skipWs()
            local c = content:sub(pos,pos)
            if c == ',' then
                pos = pos + 1
            elseif c == ']' then
                pos = pos + 1
                break
            else
                return nil, 'expected , or ]'
            end
        end
        return arr
    end

    local function parseObject()
        local obj = {}
        local order = {}
        pos = pos + 1 -- skip {
        skipWs()
        if content:sub(pos,pos) == '}' then
            pos = pos + 1
            obj.__key_order = order
            return obj
        end
        while true do
            skipWs()
            local key,err = parseString()
            if err then return nil, err end
            skipWs()
            if content:sub(pos,pos) ~= ':' then return nil, 'expected :' end
            pos = pos + 1
            skipWs()
            local val,err2 = parseValue()
            if err2 then return nil, err2 end
            obj[key] = val
            table.insert(order, key)
            skipWs()
            local c = content:sub(pos,pos)
            if c == ',' then
                pos = pos + 1
            elseif c == '}' then
                pos = pos + 1
                break
            else
                return nil, 'expected , or }'
            end
        end
        obj.__key_order = order
        return obj
    end

    parseValue = function()
        skipWs()
        local c = content:sub(pos,pos)
    if c == '"' then return parseString() end
    if c == '-' or c:match('%d') then return parseNumber() end
    if c == '{' then return parseObject() end
    if c == '[' then return parseArray() end
        if content:sub(pos,pos+3) == 'true' then return parseLiteral('true', true) end
        if content:sub(pos,pos+4) == 'false' then return parseLiteral('false', false) end
        if content:sub(pos,pos+3) == 'null' then return parseLiteral('null', nil) end
        return nil, 'unexpected char '..c
    end

    local result, err = parseValue()
    if err then
        return nil, err
    end
    return result
end

--序列化简单 JSON（对象/数组/字符串/数字/布尔/nil）
local function encodeJson(val, buf)
    buf = buf or {}
    local t = type(val)
    if t == 'table' then
        -- 判断是否数组
        local isArray = true
        local idx = 1
        for k,_ in pairs(val) do
            if type(k) ~= 'number' then isArray = false break end
        end
        if isArray then
            table.insert(buf, '[')
            local first = true
            local maxIdx = #val
            for i=1,maxIdx do
                if not first then table.insert(buf, ',') end
                encodeJson(val[i], buf)
                first = false
            end
            table.insert(buf, ']')
        else
            table.insert(buf, '{')
            local first = true
            local order = val.__key_order
            if order and type(order)=='table' then
                for _,k in ipairs(order) do
                    if k ~= '__key_order' then
                        local v = val[k]
                        if not first then table.insert(buf, ',') end
                        table.insert(buf, '"'..k..'":')
                        encodeJson(v, buf)
                        first = false
                    end
                end
            else
                for k,v in pairs(val) do
                    if k ~= '__key_order' then
                        if not first then table.insert(buf, ',') end
                        table.insert(buf, '"'..k..'":')
                        encodeJson(v, buf)
                        first = false
                    end
                end
            end
            table.insert(buf, '}')
        end
    elseif t == 'string' then
        -- 简化不处理特殊转义
        table.insert(buf, '"'..val..'"')
    elseif t == 'number' then
        table.insert(buf, tostring(val))
    elseif t == 'boolean' then
        table.insert(buf, val and 'true' or 'false')
    elseif t == 'nil' then
        table.insert(buf, 'null')
    else
        table.insert(buf, 'null')
    end
    return table.concat(buf)
end

function FunckHelper:WriteJsonFile(path, val)
    local jsonStr = encodeJson(val)
    self:WriteFile(path, jsonStr)
end

--遍历表, 找到 key == 'Mapping' 的对象, 对其子键值进行替换
function FunckHelper:ProcessAllMappingValue(rootTable, generateFunc, usedWordMap)
    if type(rootTable) ~= 'table' then return end
    for k,v in pairs(rootTable) do
        if k == 'Mapping' and type(v) == 'table' then
            for mapKey, mapVal in pairs(v) do
                if type(mapVal) == 'string' and self:IsKeyWord(mapVal) then
                    local newWord = generateFunc()
                    v[mapKey] = newWord
                    usedWordMap[newWord] = true
                end
            end
        elseif type(v) == 'table' then
            self:ProcessAllMappingValue(v, generateFunc, usedWordMap)
        end
    end
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

    --检查字符内容
    local wordLength = #word
    for charIdx = 1, wordLength do
        local char = string.sub(word, charIdx, charIdx)
        if (char >= "a" and char <= "z") or (char >= "A" and char <= "Z") then
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
function FunckHelper:GenerateRenameWord(allWordArr, usedWordMap)
    local newWord

    --进行合成
    local composeWord = ""
    local allWordNum = #allWordArr
    local tryComposeCount = 2
    while (true) do
        --单词拼接
        for _ = 1, tryComposeCount, 1 do
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

    return newWord
end
