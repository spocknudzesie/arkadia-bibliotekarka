scripts.bibliotekarka = scripts.bibliotekarka or {
    name = 'bibliotekarka',
    path = getMudletHomeDir() .. '/bibliotekarka',
    pluginName = 'arkadia-bibliotekarka',
    eventHandler = nil,
    keyHandler = nil,
    guild = nil,
    section = nil,
    title = nil,
    tmpBody = nil,
    triggers = {},
}


function scripts.bibliotekarka:msg(t, text)
    local prefix = "*"
    local color = "#ffffff"
    local formats = {
        info = {
            prefix = '*',
            color = '#ffffff'
        },
        warn = {
            prefix = '!',
            color = '#ffff00'
        },
        ok = {
            prefix = '+',
            color = '#00ff00'
        },
        error = {
            prefix = '-',
            color = '#ff0000'
        }
    }

    text = string.format("(%s) [%s] %s%s#r\n", formats[t].prefix, string.upper(self.name), formats[t].color, text)
    hecho(text)

end



function scripts.bibliotekarka:bindKey(callback)
    if self.keyHandler then
        -- self:msg('ok', 'Usuwam przypisanie klawisza ' .. self.keyHandler)
        killKey(self.keyHandler)
        self.keyHandler = nil
    end

    if not self.keyHandler then
        -- self:msg('ok', "Klawisz przypisany")
        self.keyHandler = tempKey(mudlet.keymodifier.Control, mudlet.key.B, function()
            callback()
        end)    
    end
end


function scripts.bibliotekarka:killEventHandler()
    if self.eventHandler then
        killAnonymousEventHandler(self.eventHandler)
    end
end


function scripts.bibliotekarka:saveData(gildia)
    local file = self:getDataFile(gildia)
    -- self:msg('info', string.format("Zapisuje dane gildii %s do pliku %s", gildia, file))
    -- print(dump_table(self.data.guilds[gildia]))
    if not self.data.guilds[gildia] then
        self.data.guilds[gildia] = {}
    end
    table.save(file, self.data.guilds[gildia])
end


function scripts.bibliotekarka:loadData(gildia)
    local filename = self:getDataFile(gildia)
    local f = io.open(filename, 'r')
    local data = {}

    if not f then
        self:msg('error', 'Brak gildii "' .. gildia .. '". Uzyj komendy /bib_gildia, aby ustawic obecna gildie.')
        self:saveData(gildia)
    else
        io.close(f)
    end

    self:msg('warn', string.format('Wczytuje dane gildii %s z pliku %s', gildia, filename))
    table.load(filename, data)
    print("Dane wczytane:")
    print(dump_table(data))
    self.data.guilds[gildia] = data
    return data

end


function scripts.bibliotekarka:init()
    lfs.mkdir(getMudletHomeDir() .. '/bibliotekarka')
    self:killEventHandler()
    self:msg('ok', "Plugin zaladowany. Uzyj komendy /bib_pomoc, aby zapoznac sie z dzialanie.")
end


function scripts.bibliotekarka:reload(debug)
    echo(dump_table(self.triggers))
    for name, id in ipairs(self.triggers) do
        self:msg('ok', string.format('Killing trigger %d (%s)', id, name))
        killTrigger(id)
    end
    local p = self.pluginName
    -- self:killEventHandler()
    scripts[self.name] = nil
    load_plugin('dev/' .. p)
end


tempTimer(1, [[scripts.bibliotekarka:init()]])
