--[[ 
    This script fixes the timecode gap bug identified in this video [ https://youtu.be/TMY9J1RW6r4 ].

    Essentially, DJI has a timecode bug that they refuse to fix because it is complicated.  Interestingly,
    GoPro has the same bug.  In loop mode these cameras segment video files.  The segments use the free
    running clock to set the starting timecode for the newly created segment.  The newly created segment is
    a contiguous video that should not have any timecode gaps, however, the timecode does not turn out to 
    be contiguous with the ending timecode of the prior segment.  That is the bug.  
    
    This script walks through the DJI video clips in the Media tab, identifies which ones are supposed to be
    contiguous using the filename formats, and then repairs the timecode gaps.  The clips can subsequently
    be added to a timeline using timecode without issue.  This automation saves hours of work in post
    processing required to close gaps between segments of a continuously shot scene.

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

-- Functor to Print Clip Properties
local function functorPrintClipProperties(mediaPoolItem)
    PrintClipProperties(mediaPoolItem:GetClipProperty())
end

-- Functor to Build the global DJI Clip List
djiClipList = {}
local function functorBuildDJIClipList(mediaPoolItem)
    local clipProperties = mediaPoolItem:GetClipProperty()
    if (clipProperties == nil) then return; end

    if (clipProperties["Type"] == "Video + Audio") then

        -- Sample DJI OSMO Action 4 file format: DJI_20240506120600_0002_D_A00_003.MP4
        local kformat = "^(DJI_%d%d%d%d%d%d%d%d%d%d%d%d%d%d_%d%d%d%d_D_%a%d%d_)(%d%d%d).MP4"
        local i, j, key, number = string.find(clipProperties["Clip Name"], kformat)
        if (i == nil) then return; end

        --[[ This is a potential DJI video needing correction so
        let's keep track by indexing a linked list via the key portion
        of the filename. ]]
        local num = tonumber (number)
        local item = djiClipList[key]
        if(item == nil) then
            --print ("add new entry : " .. key .. " " ..num)
            djiClipList[key] = {next = nil, number = num, properties = clipProperties}
        else
            --print ("add to existing entry: " .. key .. " " ..num)
            -- walk link list and add new entry based on ascending sorted number
            local previous = nil
            while item do
                if(item.number < num) then
                    previous = item
                    item = item.next

                    if (item == nil) then
                        previous.next = {next = nil, number = num, properties = clipProperties}
                    end
                else
                    local entry = {next = item, number = num, properties = clipProperties}
                    if (previous == nil) then
                        djiClipList[key] = entry
                    else
                        previous.next = entry
                    end
                    item = nil
                end
            end
        end
    end
end

-- Helper to locate the entry in the clip list
local function FindClipListEntry(key, number)
    --print("FindClipListEntry("..key..", "..number..")")
    local entry = djiClipList[key]
    while entry do
        if (entry.number == number) then
            --print("   >>> FOUND ENTRY <<<")
            break;
        end
        entry = entry.next;
    end
    return entry;
end

-- Functor to Save DJI Clip List modifications
local function functorSaveDJIClipList(mediaPoolItem)
    --print ("@@@@@@@@@@@@@@@@@@ functorSaveDJIClipList")
    local clipProperties = mediaPoolItem:GetClipProperty()
    if (clipProperties == nil) then return; end

    if (clipProperties["Type"] == "Video + Audio") then
        -- Look up this item in the corrected clip list
        -- Sample DJI OSMO Action 4 file format: DJI_20240506120600_0002_D_A00_003.MP4
        local kformat = "^(DJI_%d%d%d%d%d%d%d%d%d%d%d%d%d%d_%d%d%d%d_D_%a%d%d_)(%d%d%d).MP4"
        local i, j, key, number = string.find(clipProperties["Clip Name"], kformat)
        if (i == nil) then return; end

        -- Locate the item in our clip list.
        --print(" >> FindClipListEntry(" ..key..", "..number..")")
        local entry = FindClipListEntry(key, tonumber(number))
        if (entry == nil) then
            print ("ERROR - new file not found in clip list " .. clipProperties["Clip Name"])
            os.exit()
        end

        -- Did anything change?
        if (entry.properties["Start TC"] ~= clipProperties["Start TC"]) then
            print("MODIFYING [" ..clipProperties["Clip Name"].."] Start TC from [" ..clipProperties["Start TC"].. " >> " .. entry.properties["Start TC"] .. "]")
            if (mediaPoolItem:SetClipProperty("Start TC", entry.properties["Start TC"]) == false) then
                print ("ERROR - CAN'T SET 'Start TC'")
            end
        end

        --[[
        if (entry.properties["End TC"] ~= clipProperties["End TC"]) then
            print("MODIFYING [" ..clipProperties["Clip Name"].."] End TC from [" ..clipProperties["End TC"].. " >> " .. entry.properties["End TC"] .. "]")
            if (mediaPoolItem:SetClipProperty("End TC", entry.properties["End TC"]) == false) then
                print ("ERROR - CAN'T SET 'End TC'")
            end
        end
        ]]
    end
end

-- Helper to print the Clip properties
local function PrintClipProperties(clipProperties)
    if (clipProperties == nil) then return; end

    if (clipProperties["Type"] == "Video + Audio") then
        print (clipProperties["Clip Name"])
        print (clipProperties["Start TC"])
        print (clipProperties["End TC"])
        print (clipProperties["Duration"])
        print (clipProperties["FPS"])
    end
end

-- Helper to print out the clip list
local function PrintClipList(clipList)
    print ("Videos")
    --print (clipList)
    for k, entry in pairs(clipList) do
        print("*** Key: " .. k)
        while entry do
            print ("> Number: " ..entry.number)
            PrintClipProperties(entry.properties)
            entry = entry.next
        end
    end
end

-- Convert to our timecode object
local function stringToTimecode(stringTimeCode)
    local kTCFormat = "(%d%d):(%d%d):(%d%d):(%d%d)"
    local i, j, hh, mm, ss, frms = string.find(stringTimeCode, kTCFormat)
    --print("stringToTimecode(" .. stringTimeCode ..") => " ..hh..":"..mm..":"..ss..":"..frms)

    -- bug fix: frames should be a number
    local tc = {secs = hh * 3600 + mm * 60 + ss, frames = tonumber(frms)}
    
    return tc;
end

local function stringToTimecodeAddFrames(stringTimeCode, framesToAdd, framerate)
    local kTCFormat = "(%d%d):(%d%d):(%d%d):(%d%d)"
    local i, j, hh, mm, ss, frms = string.find(stringTimeCode, kTCFormat)
    --print("stringToTimecodeAddFrames(" .. stringTimeCode ..") => " ..hh..":"..mm..":"..ss..":"..frms.. ", framesToAdd=" ..framesToAdd)
    local tc = {secs = hh * 3600 + mm * 60 + ss, frames = frms + tonumber(framesToAdd)}
    --print("stringToTimecodeAddFrames -before- tc.secs = " ..tc.secs.. ", tc.frames = " ..tc.frames)
    --print(" - framerate = " .. framerate .. ", math.floor(tc.frames/math.ceil(framerate)) = " ..math.floor(tc.frames / math.ceil(framerate)))
    tc.secs = tc.secs + math.floor(tc.frames/math.ceil(framerate))
    tc.frames = tc.frames % math.ceil(framerate)
    --print("stringToTimecodeAddFrames -after- tc.secs = " ..tc.secs.. ", tc.frames = " ..tc.frames)
    return tc
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

-- Logic to fix gaps in the list
local function FixGapsDJIClipList(clipList)
    for k, entry in pairs(clipList) do
        --[[ We found a file, let's iterate the segments within it to
        see if there are any gaps that need to be closed ]]
        local previous = nil
        local framerate = nil
        while entry do
            -- First one never needs fixing
            if (previous == nil) then
                --print("++++++++++++++++++++ Processing - " ..entry.properties["Clip Name"])
                framerate = entry.properties["FPS"]
            else
                -- Check for fatal conditions
                if (framerate ~= entry.properties["FPS"]) then 
                    print("ERROR: segments have different framerates in file " ..entry.properties["Clip Name"])
                    os.exit()
                elseif (tonumber(entry.properties["Drop frame"]) == 1) then
                    print("ERROR: we don't currently support drop frames " ..entry.properties["Clip Name"])
                    os.exit()
                end

                -- Check if there's a gap with the previous segment
                --print(entry)
                local tc = stringToTimecode(entry.properties["Start TC"])
                --print(previous)
                --local tcp = stringToTimecodeAddFrames(previous.properties["End TC"], 0, framerate)
                local tcp = stringToTimecode(previous.properties["End TC"])

                --print ("DEBUG - tc (" .. entry.number..")= {secs = " ..tc.secs.. ", frames = " .. tc.frames.."} ==> " ..entry.properties["Start TC"])
                --print ("DEBUG - tcp (" .. previous.number..") = {secs = " ..tcp.secs.. ", frames = " .. tcp.frames.."}")

                if ((tc.secs ~= tcp.secs) or (tc.frames ~= tcp.frames)) then
                    -- We need to close the gap
                    --print ("FIXING gap found in [" ..entry.properties["Clip Name"].."] between segment (" ..previous.number..") and (" ..entry.number ..")")
                    --print ("  FROM -> start timecode [" ..entry.properties["Start TC"].."] and end timecode[" .. entry.properties["End TC"].."]")

                    -- Quick Timecode math... 
                    entry.properties["Start TC"] = timecodeToString(tcp)
                    --print ("Duration = " ..entry.properties["Duration"])
                    entry.properties["End TC"] = timecodeToString(addTimecode(tcp, stringToTimecode(entry.properties["Duration"]), framerate))

                    --print ("  TO -> start timecode [" ..entry.properties["Start TC"].."] and end timecode[" .. entry.properties["End TC"].."]")
                end
            end
            previous = entry
            entry = entry.next
        end
    end
end

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
    for files in the DJI file format and grab their  time code information. ]]
    VisitBin(rootBin, functorBuildDJIClipList)

    --print ("++++++++ BEFORE +++++++++++")
    --PrintClipList(djiClipList)

    -- Fix Gaps
    FixGapsDJIClipList(djiClipList)

    --print ("++++++++ AFTER +++++++++++")
    --PrintClipList(djiClipList)

    -- Save Metadata
    print ("++++++++ MODIFYING +++++++++++")
    resolve:OpenPage("deliver") -- optimize to fix a bug so that no clip is previewed and changed
    VisitBin(rootBin, functorSaveDJIClipList)
    resolve:OpenPage("media")
    print ("++++++++ DONE +++++++++++")
end

main()