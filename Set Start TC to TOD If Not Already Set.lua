--[[ 
    This script sets the Start TC clip property to the time of the creation date of the file if the Start
    TC is 00:00:00:00.  This in effect takes files that do not have timecode in them and injects the
    timecode based on the Time of Day using the creation date of the file.

    Note, the creation date of the file for most cameras is usually after the starting time of recording,
    however it is the best time to use.  This allows you to add these files into a timeline based on
    timecode time-of-day and get the files approximately in the right place.

    A few use cases may help.  I use a DJI Mini 3 Pro for drone footage while simultaneously shooting with
    DJI Osmo Action 4 cameras that are synchronized to timecode (time-of-day).  This allows the drone
    footage to be placed on the timeline approximately where it belongs without me having to compute it out.
    I can then nudge the clip on the timeline to get it to align more accurately with the other footage.
        
    The same is true for iPhone captured footage too.

    After running this script, you can add the footage to the timeline using timecode.

    The script searches across all video files regardless of bin.

    INSTALL
    Place the script in the following directory on your computer and then launch Davinci Resolve.
        Mac: /Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility
        Windows: %PROGRAMDATA%\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Utility
        Linux: /opt/resolve/Fusion/Scripts/Utility (or /home/resolve/Fusion/Scripts/Utility depending on installation)

    RUN
    You can run the script from the Workspace -> Scripts menu option; and you can see any log messages the script
    produces in the Worspace -> Console.

    LICENSE
    MIT License

    Copyright (c) 2024 Ron Jones

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    ]]

-- Visit clips
local function VisitClips(clips, functor)
    --print("**** Clip List ****")
    if not clips or (next(clips) == nil) then
        return;
    end

    for k, mediaPoolItem in ipairs(clips) do
        --print(k,mediaPoolItem)
        functor(mediaPoolItem)
    end
end

-- Visit a BIN
local function VisitBin(bin, functor)
    if (bin == nil) then
        return;
    end

    --print("==== Processing: ", bin.GetName(), "====")

    -- Examine the BIN
    mediaPool:SetCurrentFolder(bin)

    -- Get clips within this BIN
    VisitClips(bin:GetClipList(), functor)

    -- Get Subfolders & visit each...
    for k, v in ipairs(bin:GetSubFolderList()) do
        VisitBin(v, functor)
    end
end

-- Convert to our timecode object
local function stringToTimecode(stringTimeCode)
    local kTCFormat = "(%d%d):(%d%d):(%d%d):(%d%d)"
    local i, j, hh, mm, ss, frms = string.find(stringTimeCode, kTCFormat)
    --print("stringToTimecode(" .. stringTimeCode ..") => " ..hh..":"..mm..":"..ss..":"..frms)
    local tc = {secs = hh * 3600 + mm * 60 + ss, frames = tonumber(frms)}
    return tc;
end

local function addTimecode(timecode, duration, framerate)
    local tc = {secs = timecode.secs + duration.secs, frames = timecode.frames + duration.frames}
    tc.secs = tc.secs + math.floor(tc.frames/math.ceil(framerate))
    tc.frames = tc.frames % math.ceil(framerate)
    return tc
end

local function timecodeToString(timecode)
    local kTCFormat = "%02d:%02d:%02d:%02d"
    secs = timecode.secs
    hh = secs/3600
    secs = secs % 3600
    mm = secs/60
    secs = secs % 60
    return string.format(kTCFormat, hh, mm, secs, timecode.frames)
end

local function PrintClipProperties(clipProperties)
    if (clipProperties == nil) then return; end

    if ((clipProperties["Type"] == "Video + Audio") or 
        ((clipProperties["Type"] == "Video")) or
        ((clipProperties["Type"] == "Audio"))) then
        print (clipProperties["Clip Name"])
        print (clipProperties["Start TC"])
        print (clipProperties["End TC"])
        print (clipProperties["Duration"])
        print (clipProperties["FPS"])
    end
end

-- Functor to Set the Start TC to Time-of-Day
local function functorSetStartTCToTimeOfDay(mediaPoolItem)
    local clipProperties = mediaPoolItem:GetClipProperty()
    if (clipProperties == nil) then return; end

    if ((clipProperties["Type"] == "Video + Audio") or 
        ((clipProperties["Type"] == "Video")) or
        ((clipProperties["Type"] == "Audio"))) then

        -- Grab the Start TC
        local sStartTC = clipProperties["Start TC"]
        local startTC = stringToTimecode(sStartTC)
        if ((startTC.secs == 0) and (startTC.frames == 0)) then
            --PrintClipProperties(clipProperties)
            -- Set the Start TC since it's 00:00:00:00
            local dateCreated = clipProperties["Date Created"]

            -- Parse out the time stamp
            local kTSFormat = "(%d%d):(%d%d):(%d%d)"
            local i, j, hh, mm, ss = string.find(dateCreated, kTSFormat)
        
            -- Format as a starting TC at frame 0
            local kTCFormat = "%02d:%02d:%02d:%02d"
            local tc = string.format(kTCFormat, hh, mm, ss, 0)

            -- Modify the Start TC
            print("MODIFYING [" ..clipProperties["Clip Name"].. " Date Created: " .. dateCreated .. "] Start TC from [" ..sStartTC.. " >> " .. tc .. "]")
            if (mediaPoolItem:SetClipProperty("Start TC", tc) == false) then
                print ("ERROR - CAN'T SET 'Start TC'")
            end
        end
    end
end

-- Main
local function main()
    -- Navigate to the Media Page
    resolve = Resolve()
    project = resolve:GetProjectManager():GetCurrentProject()

    if not project then
        print("No project is loaded")
        os.exit()
    end

    -- Open Media page
    resolve:OpenPage("media")

    -- get root bin
    mediaPool = project:GetMediaPool()
    rootBin = mediaPool:GetRootFolder()

    --[[ Visit each BIN and subfolder off of the root bin looking
    for files to process. ]]
    print ("++++++++ MODIFYING +++++++++++")
    resolve:OpenPage("deliver") -- optimize to fix a bug so that no clip is previewed and changed
    VisitBin(rootBin, functorSetStartTCToTimeOfDay)
    resolve:OpenPage("media")
    print ("++++++++ DONE +++++++++++")
end

main()