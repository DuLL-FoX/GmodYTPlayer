surface.CreateFont("Font", {
    font = "Arial",
    extended = true,
    size = 20
})

local musicPlayer
local volume = 30 -- Local value so that players can change their own volume

local function PlayMusic(videoID, check, isTemp)
    check = check or 1
    isTemp = isTemp or false
    local tempPlayer = vgui.Create("DHTML") -- Creating a temporary player to check without creating a new one
    tempPlayer:SetSize(0, 0)
    tempPlayer:SetVisible(false)

    tempPlayer:AddFunction("gmod", "OnVideoData", function(title)
        LocalPlayer():ChatPrint("Now playing: " .. title)
    end)

    tempPlayer:AddFunction("gmod", "OnErrorResult", function(result)
        tempPlayer.errorResult = result
    end)

    if videoID then
        tempPlayer.videoID = videoID
        -- Basically it's js. Interaction functions are described here https://developers.google.com/youtube/iframe_api_reference?hl=ru
        tempPlayer:SetHTML([[
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
                                'onError': onPlayerError
                            },
                            playerVars: {
                                'controls': 0,
                                'autoplay': ]] .. check .. [[,
                                'showinfo': 0,
                                'rel': 0,
                                'disablekb': 1
                            }
                        });
                    }

                    function onPlayerError(event) {
                        if (event.data == 101) {
                            gmod.OnErrorResult(false);
                        }
                        else if (event.data == 150) {
                            gmod.OnErrorResult(false);
                        }
                        else {
                            gmod.OnErrorResult(true);
                        }
                    }
                    
    
                    function onPlayerReady(event) {
                        if (]] .. check .. [[ != 0) {
                            event.target.playVideo();
                            player.setVolume(]] .. volume .. [[);
                            var title = player.getVideoData().title;
                            gmod.OnVideoData(title);
                        } else {
                            gmod.OnErrorResult(true);
                            event.target.stopVideo();
                        }
                    }
                </script>
            </head>
            <body>
                <div id="player"></div>
            </body>
            </html>
        ]])
        tempPlayer:SetVisible(false)
        if isTemp then return tempPlayer end

        if IsValid(musicPlayer) then
            musicPlayer:RunJavascript("player.stopVideo();")
            musicPlayer:Remove()
        end

        -- Set the new music player
        musicPlayer = tempPlayer
    end
end

local function CreateMusicPlayerUI()
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 150)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()
    local frameHeight = frame:GetTall()
    local frameWidth = frame:GetWide()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(0, 0, 0, 200))
        draw.SimpleText("YouTube Music Player", "Font", 250, 5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    local urlEntry = vgui.Create("DTextEntry", frame)
    urlEntry:SetPos(25, 50)
    urlEntry:SetSize(450, 25)
    urlEntry:SetPlaceholderText("Enter YouTube URL")
    local stopButton = vgui.Create("DButton", frame)
    stopButton:SetPos(frameWidth * 0.7, frameHeight * 0.6)
    stopButton:SetSize(frameWidth * 0.2, 25)
    stopButton:SetText("Stop")

    stopButton.DoClick = function()
        net.Start("ytmp_stop_music")
        net.SendToServer()
    end

    local playButton = vgui.Create("DButton", frame)
    playButton:SetPos(frameWidth * 0.1, frameHeight * 0.6)
    playButton:SetSize(frameWidth * 0.2, 25)
    playButton:SetText("Play")

    playButton.DoClick = function()
        local url = urlEntry:GetText()
        local videoID = string.match(url, "watch%?v=([%w-_]+)")
        -- Cheking the link for limitations on the use of music
        local tempPlayer = PlayMusic(videoID, 0, true)

        -- Checking the link for correctness
        if string.StartWith(url, "https") then
            -- Checking the link for limitations on the use of music
            timer.Simple(1, function()
                if tempPlayer.errorResult then
                    tempPlayer:Remove()
                    net.Start("ytmp_play_music")
                    net.WriteString(videoID)
                    net.SendToServer()
                else
                    local error = vgui.Create("DLabel", frame)
                    error:SetSize(frame:GetWide() * 0.3, 25)
                    error:SetPos(frame:GetWide() * 0.37, frame:GetTall() * 0.6)
                    error:SetText("Copyright, cannot be used")
                    error:SetTextColor(Color(255, 0, 0))

                    timer.Simple(3, function()
                        error:Remove()
                    end)
                end
            end)
        else
            local error = vgui.Create("DLabel", frame)
            error:SetSize(frame:GetWide() * 0.3, 25)
            error:SetPos(frame:GetWide() * 0.45, frame:GetTall() * 0.6)
            error:SetText("Invalid URL")
            error:SetTextColor(Color(255, 0, 0))

            timer.Simple(3, function()
                error:Remove()
            end)
        end
    end
end

--I'm not sure how correct it is to leave the check logic in net.Receive, but it's formally more reliable here.
net.Receive("ytmp_update_music", function()
    local videoID = net.ReadString()

    -- If the musicPlayer is valid, stop and remove it
    if IsValid(musicPlayer) then
        musicPlayer:RunJavascript("player.stopVideo();")
        musicPlayer:Remove()
    end

    -- If the received videoID is not empty, then play the new music
    if videoID ~= "" then
        PlayMusic(videoID, 1, false)
    end
end)

net.Receive("ytmp_commands", function()
    local text = net.ReadString()

    if string.StartWith(text, "!volume") then
        local cmd = string.Explode(" ", text)
        volume = tonumber(cmd[2])
        LocalPlayer():ChatPrint("Your volume is " .. volume .. "%")

        if IsValid(musicPlayer) then
            musicPlayer:RunJavascript("player.setVolume(" .. volume .. ");")
        end
    end

    if string.StartWith(text, "!mp") then
        CreateMusicPlayerUI()
    end
end)