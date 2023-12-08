function scripts.bibliotekarka:setGuild(guild)
    self.guild = guild
    self:msg('info', 'Aktualna gildia ustawiona na ' .. guild)

    lfs.mkdir(getMudletHomeDir() .. '/bibliotekarka/' .. guild)
end


function scripts.bibliotekarka:setSection(matches)
    local section

    if not self.guild then
        self:msg('error', 'Przed ustawieniem dzialu, ustaw gildie komenda /bib_gildia')
        return
    end

    if matches[1] == "Przestajesz sie koncentrowac na dzialach szczegolowych." then
        section = 'glowny'
    else
        section = matches[2]
    end

    self.section = section
    self:createTree(string.format('%s/%s/%s', self.path, self.guild, section))
    self:msg('ok', string.format('\nAktualny dzial: %s', self.section))
end


function scripts.bibliotekarka:setTitle(title)
    if not self.guild then
        self:msg('error', 'Przed ustawieniem tytulu, ustaw gildie komenda /bib_gildia.')
        return
    end

    if not self.guild then
        self:msg('error', 'Przed ustawieniem tytulu, ustaw dzial komenda /bib_dzial lub wybierajac go z listy w bibliotece.')
        return
    end

    self.title = title

    if self:exists(self:getBookPath(self.guild, self.section, title)) then
        self:msg('warn', string.format('Ksiazka o tytule "%s" juz istnieje i moze zostac nadpisana.', title))
    end

    print("")
    self:msg('ok', string.format('Aktualna ksiazka: %s', self.title))
    self.tmpBody = ""
end


function scripts.bibliotekarka:checkGuild()
    if not self.guild then
        self:msg('error', 'Brak wybranej gildii.')
        return false
    end

    return true
end


function scripts.bibliotekarka:cmdSetGuild(data)
    if #data == 0 then
        self:msg('error', 'Poprawne uzycie: ' .. matches[1] .. ' [gildia]')
        return
    end

    self:setGuild(matches[2])
end


function scripts.bibliotekarka:cmdSetSection(data)
    if #data == 0 then
        self:msg('error', 'Poprawne uzycie: ' .. matches[1] .. ' [dzial]')
        return
    end

    self:setSection(matches)
end


function scripts.bibliotekarka:cmdSetTitle(data)
    if #data == 0 then
        self:msg('error', 'Poprawne uzycie: ' .. matches[1] .. ' [tytul]')
        return
    end

    self:setTitle(matches[2])
end


function scripts.bibliotekarka:cmdHelp()
    local helpLine = function(cmd, args, desc)
        if #cmd > 0 then
            cmd = '_' .. cmd
        end

        hecho(string.format('- #ffffff/bib%s %s#r - %s\n', cmd, args, desc))
    end

    self:msg('ok', 'Pomoc dotyczaca modulu "Bibliotekarka":')
    helpLine('pomoc', '', 'ta pomoc')
    helpLine('c/czytaj', '', 'czyta posiadana ksiazke i przetwarza ja')
    helpLine('dzialy/spis', '', 'pobiera liste ksiazek w aktualnym dziale')
    echo('')
    helpLine('', '', 'aktualne ustawienia Bibliotekarki')
    helpLine('gildia', '<gildia>', 'ustawia aktualna gildie')
    helpLine('dzial', '<dzial>', 'ustawia aktualny dzial, jesli nie stanie sie to automatycznie')
    helpLine('tytul', '<tytul>', 'ustawia tytul ksiazki, ktora bedzie czytana, jesli nie stanie sie to automatycznie')
    helpLine('gildia', '<gildia>', 'ustawia aktualna gildie')
end


function scripts.bibliotekarka:cmdStatus()
    self:msg('ok', 'Aktualne ustawienia Bibliotekarki:')
    echo("Gildia:  ")
    if not self.guild then
        hecho("#ff0000BRAK#r - ustaw komenda /bib_gildia\n")
    else
        hecho("#00ff00"..self.guild.."#r\n")
    end

    echo("Dzial:   ")
    if not self.section then
        hecho("#ff0000BRAK#r - ustaw komenda /bib_dzial\n")
    else
        hecho("#00ff00"..self.section.."#r\n")
    end
    
    echo("Ksiazka: ")
    if not self.title then
        hecho("#ff0000BRAK#r - ustaw komenda /bib_ksiazka\n")
    else
        hecho("#00ff00"..self.title.."#r\n")
    end
end


function scripts.bibliotekarka:cmdGetSections()
    if not scripts.bibliotekarka:checkGuild() then
        return
    end
    
    enableTrigger('bibliotekarka_lista_ksiazek')
    enableTrigger('bibliotekarka_dzial')
    enableTrigger('bibliotekarka_breaker')

    send('spis')
end


function scripts.bibliotekarka:echoSectionLink(section)
    deleteLine()
    hecho(string.format('\n - %s', section))
    hechoLink(" #ffffff[WYBIERZ]#r", function()
        self:clickSection(section)
    end, string.format('Wybierz dzial "%s"', section), true)
    
    if #self:getBooks(self.guild, section, true) > 0 then
        hecho(string.format(' (zapisane: %d)', #self:getBooks(self.guild, section, true)))
    else
        self:addSection(self.guild, section)
    end
    
    hecho("\n")
end


function scripts.bibliotekarka:bindReadBook()
    self:bindKey(function()
        self:cmdReadBook()
    end)
    self:msg('ok', '\nNacisnij Ctrl+B, aby przeczytac ksiazke')
end


function scripts.bibliotekarka:bindViewSection()
    self:bindKey(function()
        self:cmdGetSections()
    end)
    self:msg('ok', 'Nacisnij Ctrl+B, aby przejrzec dzial\n')
end


function scripts.bibliotekarka:bindReturnBook()
    self:bindKey(function()
        self:cmdReturnBook()
    end)
    self:msg('ok', 'Nacisnij Ctrl+B, aby zwrocic ksiazke\n')
end


function scripts.bibliotekarka:cmdReturnBook()
    send("zwroc ksiazke")
end


function scripts.bibliotekarka:clickSection(section)
    send('wybierz dzial ' .. section)
    enableTrigger('bibliotekarka_wybor_dzialu')
    enableTrigger('bibliotekarka_lista_ksiazek')
end


function scripts.bibliotekarka:cmdRentBook(number)
    send('wypozycz ksiazke ' .. number)
    enableTrigger('bibliotekarka_podaje_ksiazke')
end


function scripts.bibliotekarka:writeBody(text)
    if not self.title then
        return
    end

    if not self.tmpBody then
        self.tmpBody = ""        
    end

    if string.match(text, '^%[linia %d+/%d+') then
        return
    end

    self.tmpBody = self.tmpBody .. text .. "\n"
    -- print("BODY LEN=" .. #self.tmpBody)
end


function scripts.bibliotekarka:cmdReadBook()
    if not self.guild then
        self:msg('error', 'Najpierw ustaw gildie komenda /bib_gildia.')
        return
    end

    if not self.section then
        self:msg('error', 'Najpierw ustaw dzial komenda /bib_dzial lub przegladajac dzial w bibliotece.')
        return
    end

    -- enableTrigger('bibliotekarka_breaker')
    enableTrigger('bibliotekarka_okladka')
    send('ob ksiazke')
    send('przeczytaj ksiazke')
    tempTimer(0.2, function() send(' ') end)

end


function scripts.bibliotekarka:startReading()
    self:msg('ok', "Rozpoczynam czytanie ksiazki '" .. self.title .. "'...")
    self.reader = 0
end


function scripts.bibliotekarka:waitForFinalPrompt()
    -- print("READER = " .. self.reader)
    -- print(dump_table(gmcp.gmcp_msgs))
    if gmcp.gmcp_msgs.type == 'other' then
        local text = ansi2string(gmcp.gmcp_msgs.decoded)
        if string.match(text, '%[linia %d+') then
            send(" ")
            -- print("GMCP: " .. text)
            -- deleteLine()
        end
    end
    
    if gmcp.gmcp_msgs.type == 'prompt' then
        self.reader = self.reader + 1
        -- print("PROMPT: " .. ansi2string(gmcp.gmcp_msgs.decoded))
    end

    if self.reader >= 2 then
        self:finishReading()
    end
end


function scripts.bibliotekarka:finishReading()
    disableTrigger('bibliotekarka_prompt')
    disableTrigger('bibliotekarka_zapisuj')
    self:bindReturnBook()
    self:msg('ok', "Czytanie ksiazki '" .. self.title .. "' zakonczone.")
    self:saveBook(self.guild, self.section, self.title, self.tmpBody)
end


function scripts.bibliotekarka:echoBookLink(number, title)
    local path
    path = self:getBookPath(self.guild, self.section, title)
    -- print("BOOK LINK " .. title)

    if not self.section then
        return
    end

    deleteLine()
    
    hecho(string.format("\n%2d - %s", number, title))
    
    hechoLink(' #ffffff[WYPOZYCZ]#r', function()
        self:cmdRentBook(number)
    end, string.format('Wypozycz ksiazke "%s"', title), true)

    -- print(dump_table({self.guild, self.section, title}))

    if not self:exists(path) then
        hecho(' #ffff00-- nowa ksiazka --#r')
    else
        hecho(' -- dodana ' .. self:getDate(path))
    end

    hecho("\n")

    -- tempTimer()
end
