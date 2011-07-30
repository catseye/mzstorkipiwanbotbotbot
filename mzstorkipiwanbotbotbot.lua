#!/usr/bin/env lua

-- An IRC bot with no plan or purpose, written in Lua.
-- This work is in the public domain.

require "config"

--[[ GLOBALS ]]--

local MSG_PATTERN = "^" .. BOTNAME .. "%s*[:,!]%s*(.-)%s*$"
local CMD_PATTERN = "^%|%s*(.-)%s*$"

math.randomseed(os.time())

-- variable scopes

local server -- for server scope
local room   -- for channel scope 
local user   -- for nick scope

-- syntax error messages

local snark = {
    "?SYNTAX ERROR",
    "omg u errored teh syntax!!1!",
    "What is this I don't even",
    "wat.",
    "I disagree!",
    "That's wonderful for you!",
}

--[[ FUNCTIONS ]]--

local p = function(s)
    io.stderr:write(">>> " .. s .. "\n")
    io.stdout:write(s)
    io.stdout:write("\n")
    io.stdout:flush()
end

local eval
eval = function(expr, nick, channel, context, reply)

    context.iter = context.iter + 1
    if context.iter > 10000 then
        reply('Out of stack space!  Well no, but I stopped it anyway.')
        return nil
    end

    -- define the user's space
    local userspace = user[nick]
    if userspace == nil then
        userspace = {}
        user[nick] = userspace
    end

    -- FIRST, we find and reduce any expressions.
    expr = string.gsub(expr, "(%b[])", function (subexpr)
        subexpr = string.sub(subexpr, 2, -2)
        local value = eval(subexpr, nick, channel, context, reply)
        if value == nil then
            return ''
        else
            return value
        end
    end)

    -- Assignment to server variable
    local match, _, name, value = string.find(expr, "^%/(%a-)%s*%=%s*(.-)$")
    if match then
        server[name] = value
        return value
    end

    -- Assignment to channel variable
    local match, _, name, value = string.find(expr, "^%#(%a-)%s*%=%s*(.-)$")
    if match then
        if room[channel] == nil then room[channel] = {} end
        room[channel][name] = value
        return value
    end

    -- Assignment to user variable
    local match, _, name, value = string.find(expr, "^%~%/(%a-)%s*%=%s*(.-)$")
    if match then
        userspace[name] = value
        return value
    end

    -- Print
    local match, _, value = string.find(expr, "^print%s*(.-)%s*$")
    if match then
        reply(value)
        return nil
    end

    -- Goto
    local match, _, newexpr = string.find(expr, "^goto%s*(.-)%s*$")
    if match then
        return eval(newexpr, nick, channel, context, reply)
    end

    -- Reading a server variable's value
    local match, _, name = string.find(expr, '^%/(%a-)$')
    if match then
        return server[name] or ''
    end

    -- Reading a channel variable's value
    local match, _, name = string.find(expr, '^%#(%a-)$')
    if match then
        local roomspace = room[channel]
        if roomspace == nil then return '' end
        return roomspace[name] or ''
    end

    -- Reading this user variable's value
    local match, _, name = string.find(expr, '^%~%/(%a-)$')
    if match then
        return userspace[name] or ''
    end

    -- Reading any user variable's value
    local match, _, fromnick, name = string.find(expr, '^%~([%w_]-)%/(%a-)$')
    if match then
        local userspace = user[fromnick]
        if userspace == nil then return '' end
        return userspace[name] or ''
    end

    -- Head and tail
    local match, _, fst = string.find(expr, '^hd%s*(.).*$')
    if match then
        return fst
    end
    local match, _, rst = string.find(expr, '^tl%s*.(.*)$')
    if match then
        return rst
    end

    -- tell
    local match, _, to_nick, msg = string.find(expr, "^tell%s+(.-)%s+(.-)$")
    if match then
        message = {from=nick, msg=msg}
        if user[to_nick] == nil then user[to_nick] = {} end
        if type(user[to_nick].msgs) ~= table then
            user[to_nick].msgs = {}
        end
        table.insert(user[to_nick].msgs, message)
        reply("Consider it noted.")
        return
    end

    -- source code
    local match = string.find(expr, "^source%s*$")
    if match then
        reply("http://bitbucket.org/catseye/mzstorkipiwanbotbotbot/src/tip/mzstorkipiwanbotbotbot.lua")
        return
    end

    -- save state
    local match = string.find(expr, "^save%s*$")
    if match then
        -- TODO save state here
        -- reply("State saved.")
        return
    end

    -- Help
    local match, _, topic = string.find(expr, "^help%s*(.-)$")
    if match then
        if string.find(topic, '^ass') then
            reply("Assign a nick-scope variable with ~/foo=1.  Assign a server-scope variable with /bar=1.  Assign a channel-scope variable with #baz=1.")
            return
        elseif string.find(topic, '^exp') then
            reply("All items in [brackets] are replaced by their value, in a recursive, depth-first manner.")
            return
        elseif string.find(topic, '^pr') then
            reply("To print a string, issue the command 'print string'.")
            return
        elseif string.find(topic, '^go') then
            reply("To evaluate a string as a command, issue 'goto command'.  This discards control context.")
            return
        elseif string.find(topic, '^tell') then
            reply("To enqueue a message for another user, which they will see publicly when they next speak up, issue the comand 'tell nick <stuff>'.")
            return
        elseif string.find(topic, '^sou') then
            reply("To get a link to the source code for this bot, issue the command 'source'.")
            return
        elseif string.find(topic, '^err') then
            reply("To get more interesting error messages, set ~/errmsgs=snark.")
            return
        else
            reply("Help is available for: assignment expressions print goto tell source errors")
            return
        end
    end

    -- Syntax error
    if userspace.errmsgs == 'snark' then
        reply(snark[math.random(#snark)])
    else
        reply("Unknown command.  Type '|help' for help.")
    end
end

--[[ MAIN ]]--

local done = False
if state == nil then state = 0 end

server = {}
room = {}
user = {}
user[BOTNAME] = {
    BRA="[",
    KET="]"
}

while not done do
    local line = io.stdin:read("*line")
    line = string.gsub(line, "[\r\n]+$", "") -- chomp
    io.stderr:write("--- " .. line .. "\n")
    if state == 0 then
        if string.find(line, "No Ident response") then
            p(string.format("USER %s %s %s %s", BOTNAME, BOTNAME, BOTNAME, BOTNAME))
            p(string.format("NICK %s", BOTNAME))
            if PASSWORD ~= nil then
                p(string.format("PRIVMSG NickServ :identify %s", PASSWORD))
            end
            for i,channel in ipairs(CHANNELS) do
                p(string.format("JOIN %s", channel))
            end
            state = 1
        end
    else -- state == 1
        local match, _, nick, channel, chatline = string.find(line, '^%:(.-)%!.-%s+PRIVMSG%s*(.-)%s*%:(.-)$')
        if match and string.find(channel, '^\#') then
            -- someone said something in the channel we're in.
            local reply = function(s)
                if s ~= nil then
                    if type(s) == "table" then s = "<table>" end -- TODO:  table.tostring(s)
                    p(string.format("PRIVMSG %s :%s: %s", channel, nick, s))
                end
            end

            -- was it someone I have a message for?
            if user[nick] ~= nil and type(user[nick].msgs) == "table" then
                local c = 0
                for key,message in pairs(user[nick].msgs) do
                    c = c + 1
                    if c > 5 then
                        reply("And there's more.  I'll tell you later.")
                        break
                    else
                        reply(string.format("%s told me to tell you: %s", message.from, message.msg))
                        user[nick].msgs[key] = nil
                    end
                end
            end

            -- was it addressed to me?
            match, _, msg = string.find(chatline, MSG_PATTERN)
            if not match then
                match, _, msg = string.find(chatline, CMD_PATTERN)
            end
            if match then
                local context = { iter=0 }
                reply(eval(msg, nick, channel, context, reply))
            end
        end
        local match, _, nick, botname, msg = string.find(line, '^%:(.-)%!.-%s+PRIVMSG%s+(.-)%s*%:%s*(.-)%s*$')
        if match then
            if botname == BOTNAME and nick ~= BOTNAME then
                local context = { iter=0 }
                local reply = function(s)
                    if s ~= nil then
                        p(string.format("PRIVMSG %s :%s", nick, s))
                    end
                end
                reply(eval(msg, nick, nil, context, reply))
            end
        end
        local match, _, serv = string.find(line, "^PING%s+%:(.-)$")
        if match then
            p(string.format("PONG :%s", serv))
            -- TODO save state here
        end
    end
end

