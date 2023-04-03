surface.CreateFont("Font", {
    font = "Arial",
    extended = true,
    size = 20
})

local musicPlayer = nil
-- Local value so that players can change their own volume
local volume = 50

local function PlayMusic(videoID)
    musicPlayer = vgui.Create("DHTML")
    musicPlayer:SetSize(0, 0)
    musicPlayer:SetVisible(false)

    musicPlayer:AddFunction("gmod", "OnVideoData", function(title)
        LocalPlayer():ChatPrint("Now playing: " .. title)
    end)

    if videoID then
        musicPlayer.videoID = videoID
        -- Basically it's js. Interaction functions are described here https://developers.google.com/youtube/iframe_api_reference?hl=ru
        musicPlayer:SetHTML([[
            <!DOCTYPE html>
            <html>
            <head>
                <script src="https://www.youtube.com/iframe_api"></script>
                <script>
                    var player;
    
                    function onYouTubeIframeAPIReady() {
                        player = new YT.Player('player', {
                            height: '0',
                            width: '0',
                            videoId: ']] .. videoID .. [[',
                            events: {
                                'onReady': onPlayerReady,
                                'onStateChange': onPlayerStateChange
                            },
                            playerVars: {
                                'controls': 0,
                                'autoplay': 1,
                                'showinfo': 0,
                                'rel': 0,
                                'disablekb': 1
                            }
                        });
                    }
    
                    function onPlayerReady(event) {
                        event.target.playVideo();
                        player.setVolume(]] .. volume .. [[);
                    }
    
                    function onPlayerStateChange(event) {
                        if (event.data == YT.PlayerState.PLAYING) {
                            var title = player.getVideoData().title;
                            gmod.OnVideoData(title);
                        }
                    }
                </script>
            </head>
            <body>
                <div id="player"></div>
            </body>
            </html>
        ]])
        musicPlayer:SetVisible(false)
    end
end

local function CreateMusicPlayerUI()
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 150)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(0, 0, 0, 200))
        draw.SimpleText("YouTube Music Player", "Font", 250, 5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    local urlEntry = vgui.Create("DTextEntry", frame)
    urlEntry:SetPos(25, 50)
    urlEntry:SetSize(450, 25)
    urlEntry:SetPlaceholderText("Enter YouTube URL")
    local playButton = vgui.Create("DButton", frame)
    playButton:SetPos(frame:GetWide() * 0.1, frame:GetTall() * 0.6)
    playButton:SetSize(frame:GetWide() * 0.2, 25)
    playButton:SetText("Play")

    playButton.DoClick = function()
        local url = urlEntry:GetText()
        local videoID = string.match(url, "watch%?v=([%w-_]+)")

        if videoID then
            net.Start("ytmp_play_music")
            net.WriteString(videoID)
            net.SendToServer()
        end
    end

    local stopButton = vgui.Create("DButton", frame)
    stopButton:SetPos(frame:GetWide() * 0.7, frame:GetTall() * 0.6)
    stopButton:SetSize(frame:GetWide() * 0.2, 25)
    stopButton:SetText("Stop")

    stopButton.DoClick = function()
        if IsValid(musicPlayer) then
            musicPlayer:Remove()
            musicPlayer:RunJavascript("player.stopVideo();")
        end
    end
end

--I'm not sure how correct it is to leave the check logic in net.Receive, but it's formally more reliable here.
net.Receive("ytmp_update_music", function()
    local videoID = net.ReadString()

    -- Delete added to cut off previous music when starting a new one or stopping
    if IsValid(musicPlayer) then
        musicPlayer:Remove()
        return
    elseif IsValid(musicPlayer) and musicPlayer.videoID == "" then
        musicPlayer:Remove()
        return
    else
        PlayMusic(videoID)
    end
end)

hook.Add("OnPlayerChat", "ytmp_command_handler", function(ply, text)
    local cmd = string.Explode(" ", text)

    if cmd[1] == "!mp" and ply:IsAdmin() then
        CreateMusicPlayerUI()

        -- Added to not be displayed in the chat
        return true
    elseif cmd[1] == "!volume" then
        volume = tonumber(cmd[2])
        LocalPlayer():ChatPrint("Your volume is " .. volume .. "%")

        if IsValid(musicPlayer) and volume and volume >= 0 and volume <= 100 then
            musicPlayer:RunJavascript("player.setVolume(" .. volume .. ");")
        end

        -- Same as above
        return true
    end
end)