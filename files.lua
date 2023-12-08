function scripts.bibliotekarka:exists(path)
    local attrs = lfs.attributes(path)

    if not attrs then
        return false
    end

    return attrs['mode']
end


function scripts.bibliotekarka:getDate(path)
    if not self:exists(path) then
        return false
    end

    local d = lfs.attributes(path, 'modification')
    return os.date('%Y-%m-%d %H-%M', d), d
end


function scripts.bibliotekarka:createTree(path)
    local tree
    local mudlet = getMudletHomeDir()
    local endPath = path:gsub(mudlet..'/', '')
    local dirLine = mudlet

    tree = string.split(endPath, '/')
    
    for _, folder in ipairs(tree) do
        dirLine = dirLine .. '/' .. folder
        local res = self:exists(dirLine)

        if not res then
            lfs.mkdir(dirLine)
        else
            -- print(dirLine .. ": " .. res .. "\n")
        end
    end
end


function scripts.bibliotekarka:addSection(guild, section)
    return self:createTree(string.format('%s/%s/%s', self.path, guild, section))
end


function scripts.bibliotekarka:getDirContent(path, short)
    local result = {}

    for file in lfs.dir(path) do
        local fullPath = path .. '/' .. file
        local res = self:exists(fullPath)
        if res and file ~= "." and file ~= ".." then
            if short then
                table.insert(result, file)
            else
                table.insert(result, fullPath)
            end
        end
    end

    return result
end


function scripts.bibliotekarka:getGuilds(short)
    return self:getDirContent(self.path, short)
end


function scripts.bibliotekarka:getSections(guild, short)
    return self:getDirContent(self.path .. '/' .. guild, short)
end


function scripts.bibliotekarka:getBooks(guild, section, short)
    return self:getDirContent(self.path .. '/' .. guild .. '/' .. section, short)
end


function scripts.bibliotekarka:getBookPath(guild, section, title)
    return string.format('%s/%s/%s/%s.txt', self.path, guild, section, title)
end


function scripts.bibliotekarka:getBook(guild, section, title)
    local filename = self:getBookPath(guild, section, title)
    local body

    if not self:exists(filename) then
        return false
    end

    local f = io.open(filename, 'r')
    if not f then
        return false
    end

    body = f:read()
    f:close()
    return body
end


function scripts.bibliotekarka:saveBook(guild, section, title, body)
    local bookPath = self:getBookPath(guild, section, title)

    for i=1,10,1 do
        body = string.gsub(body, '\n> ', '\n')
        body = string.gsub(body, '^> ', '')
        -- print(string.format("i=%d, body=%d", i, #body))
    end

    -- print(bookPath)

    self:msg('ok', string.format('Zapisuje ksiazke (%d znakow) %s do pliku %s', #body, title, bookPath))
    -- if self:bookExists(guild, section, title) then
    --     return false
    -- end

    local f = io.open(self:getBookPath(guild, section, title), 'w+')
    f:write(body)
    f:close()
    return body
end