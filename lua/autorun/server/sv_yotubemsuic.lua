util.AddNetworkString("ytmp_play_music")
util.AddNetworkString("ytmp_update_music")
util.AddNetworkString("ytmp_stop_music")

net.Receive("ytmp_play_music", function(len, ply)
    if not ply:IsAdmin() then return end
    local videoID = net.ReadString()
    net.Start("ytmp_update_music")
    net.WriteString(videoID)
    net.Broadcast()
end)

net.Receive("ytmp_stop_music", function(len, ply)
    if not ply:IsAdmin() then return end
    net.Start("ytmp_update_music")
    net.WriteString("")
    net.Broadcast()
end)