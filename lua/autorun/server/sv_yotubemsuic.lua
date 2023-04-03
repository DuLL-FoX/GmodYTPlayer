local videoID = ""

-- Protection from the admin who forgot to press the stop button so that the music does not play for those who connected
-- Not a very implementation, but you need an api key or even network strings for a more adequate one. Or your edits
timer.Create("ResetVideoID", 15, 0, function()
    videoID = ""
end)

util.AddNetworkString("ytmp_play_music")
util.AddNetworkString("ytmp_update_music")
util.AddNetworkString("ytmp_stop_music")
util.AddNetworkString("ytmp_commands")

net.Receive("ytmp_play_music", function(len, ply)
    if not ply:IsAdmin() then return end
    videoID = net.ReadString()
    net.Start("ytmp_update_music")
    net.WriteString(videoID)
    net.Broadcast()
end)

net.Receive("ytmp_stop_music", function(len, ply)
    if not ply:IsAdmin() then return end
    videoID = ""
    net.Start("ytmp_update_music")
    net.WriteString(videoID)
    net.Broadcast()
end)

-- If the player has just connected, he starts playing the music that was last played
hook.Add("PlayerInitialSpawn", "ytmp_create_music_player", function(ply)
    net.Start("ytmp_update_music")
    net.WriteString(videoID)
    net.Send(ply)
end)

-- If you know how then you can get rid of one AddNetworkString. Because I do not know how to do it
hook.Add("PlayerSay", "HideChatCommands", function(ply, text, teamChat)
    if string.StartWith(text, "!mp") and ply:IsAdmin() then
        net.Start("ytmp_commands")
        net.WriteString(text)
        net.Send(ply)

        return ""
    end

    if string.StartWith(text, "!volume") and ply:IsAdmin() then
        net.Start("ytmp_commands")
        net.WriteString(text)
        net.Send(ply)

        return ""
    end
end)