﻿--- Library functions for Lilia's Logs
-- @module lia.log
lia.log.types = lia.log.types or {}
-- @type function lia.log.loadTables()
-- Used to load tables into the database
-- @realm server
-- @internal
function lia.log.loadTables()
    file.CreateDir("lilia/logs")
    file.CreateDir("lilia/netlogs")
    file.CreateDir("lilia/concommandlogs")
end

-- @type function lia.log.resetTables()
-- Used to reset tables into database
-- @realm server
-- @internal
function lia.log.resetTables()
end

-- @type function lia.log.addType(logType, func)
-- Used to reset tables into database
-- @realm server
-- @string logType
-- @function (client, ...) log format callback
-- @usageStart
-- lia.log.addType("playerConnected", function(client, ...)
--		local data = {...}
--		local steamID = data[2]
--
--		return string.format("%s[%s] has connected to the server.", client:Name(), steamID or client:SteamID())
--	end)
-- @usageEnd
function lia.log.addType(logType, func)
    lia.log.types[logType] = func
end

-- @type function lia.log.getString(client, logType, ...)
-- Formats a string that is in log.type
-- @player client Default argument for format string
-- @string logType 
-- @vararg ... Other arguments on log format
-- @realm server
-- @treturn string Formatted string
-- @internal
function lia.log.getString(client, logType, ...)
    local text = lia.log.types[logType]
    if isfunction(text) then
        local success, result = pcall(text, client, ...)
        if success then return result end
    end
end

-- @type function lia.log.addRaw(logString, shouldNotify, flag)
-- Adds a raw that does not require formatting
-- @string logString Log string data
-- @bool sholdNotify Display log notification in the administration console
-- @int flag Log color flag
-- @realm server
function lia.log.addRaw(logString, shouldNotify, flag)
    if shouldNotify then lia.log.send(lia.util.getAdmins(), logString, flag) end
    Msg("[LOG] ", logString .. "\n")
    if not noSave then file.Append("lilia/logs/" .. os.date("%x"):gsub("/", "-") .. ".txt", "[" .. os.date("%X") .. "]\t" .. logString .. "\r\n") end
end

-- @type function lia.log.add(client, logType, ...)
-- Displays a line of the log according to the match described in the log type
-- @player client player name on displayed log
-- @string logType type of log
-- @vararg ... other arguments for log
-- @realm server
-- @usageStart
-- function GM:PlayerAuthed(client, steamID, uniqueID)
--	lia.log.add(client, "playerConnected", client, steamID)
-- end
-- @usageEnd
function lia.log.add(client, logType, ...)
    local logString = lia.log.getString(client, logType, ...)
    if not isstring(logString) then return end
    if mLogs then lia.log.mLogsLoad(logString) end
    hook.Run("OnServerLog", client, logType, ...)
    Msg("[LOG] ", logString .. "\n")
    if noSave then return end
    file.Append("lilia/logs/" .. os.date("%x"):gsub("/", "-") .. ".txt", "[" .. os.date("%X") .. "]\t" .. logString .. "\r\n")
end

-- @type function lia.log.send(client, logString, flag)
-- Display log raw on client console
-- @player client player name on displayed log
-- @string logString log string
-- @int flag Color flag on log string
-- @realm server
-- @internal
function lia.log.send(client, logString, flag)
    netstream.Start(client, "liaLogStream", logString, flag)
end

-- @type function lia.log.send(client, logString, flag)
-- Display log raw on client console
-- @string logString log string
-- @realm server
-- @internal
function lia.log.mLogsLoad(str)
    mLogs.log("LiliaLog", "lia", {
        log = str
    })
end
