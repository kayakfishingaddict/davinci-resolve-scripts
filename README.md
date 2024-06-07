# Davinci Resolve Scripts

## Description

This project includes multiple helpful scripts as described below.

## Script: DJI OSMO Action 4 Serious TimeCode Bug Fix Script

This [script](https://github.com/kayakfishingaddict/davinci-resolve-scripts/blob/master/DJI%20OA4%20Serious%20Timecode%20Bug%20Fix.lua) fixes the timecode gap bug identified in this [video](https://youtu.be/TMY9J1RW6r4).

Here's a [video](https://youtu.be/AW236xE3xqs) that shows how to install and run the script with an example of how it fixes the timecode bug.

Essentially, DJI has a timecode bug that they refuse to fix because it is complicated.  Interestingly, GoPro has the same bug.  In loop mode these cameras segment video files.  The segments use the free running clock to set the starting timecode for the newly created segment.  The newly created segment is a contiguous video that should not have any timecode gaps, however, the timecode does not turn out to be contiguous with the ending timecode of the prior segment.  That is the bug.

This script walks through the DJI video clips in the Media tab, identifies which ones are supposed to be contiguous using the filename formats, and then repairs the timecode gaps.  The clips can subsequently be added to a timeline using timecode without issue.  This automation saves hours of work in post processing required to close gaps between segments of a continuously shot scene.

### Dependencies - (DJI OA4 Serious Timecode Bug Fix.lua)

* Davinci Resolve 18 or higher
* Recordings from OSMO Action 4 cameras, synchronized with timecode reportedly only with looping mode turned on.
* Video file names should be in the following format: DJI_20240506120600_0002_D_A00_003.MP4 which is the default.

## Script: Set Start TimeCode to Time-Of-Day If Not Already Set Script

This [script](https://github.com/kayakfishingaddict/davinci-resolve-scripts/blob/master/Set%20Start%20TC%20to%20TOD%20If%20Not%20Already%20Set.lua) sets the Start TC clip property to the time of the creation date of the file if the Start TC is 00:00:00:00.  This in effect takes files that do not have timecode in them and injects the timecode based on the Time of Day using the creation date of the file.

Note, the creation date of the file for most cameras is usually after the starting time of recording, however it is the best time to use.  This allows you to add these files into a timeline based on timecode time-of-day and get the files approximately in the right place.

A few use cases may help.  I use a DJI Mini 3 Pro for drone footage while simultaneously shooting with DJI Osmo Action 4 cameras that are synchronized to timecode (time-of-day).  This allows the drone footage to be placed on the timeline approximately where it belongs without me having to compute it out. I can then nudge the clip on the timeline to get it to align more accurately with the other footage.

The same is true for iPhone captured footage too.

After running this script, you can add the footage to the timeline using timecode.

The script searches across all video files regardless of bin.

### Dependencies - (Set Start TC to TOD If Not Already Set.lua)

* Davinci Resolve 18 or higher
* Recordings with timecode set to 00:00:00:00

## Getting Started

## Installing

Place the script files in the following directory on your computer and then launch Davinci Resolve.

* Mac: /Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility
* Windows: %PROGRAMDATA%\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Utility
* Linux: /opt/resolve/Fusion/Scripts/Utility (or /home/resolve/Fusion/Scripts/Utility depending on installation)

## Executing Scripts

You can run the script from the Workspace -> Scripts menu option; and you can see any log messages the script produces in the Workspace -> Console.

## Help

## Authors

Contributors names and contact info

ex. [@KayakFishingAddict](https://youtube.com/kayakfishingaddict)

## Version History

* 0.1
  * Initial Release - DJI OSMO Action 4 Serious TimeCode Bug Fix Script.  It does not include DF support.

* 0.2
  * Initial Release - Set Start TimeCode to Time-Of-Day If Not Already Set Script.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Discussions & Background

* [Video describing the bug](https://youtu.be/TMY9J1RW6r4)
* [Installation video for this script](https://youtu.be/AW236xE3xqs)
* [DJI Forum Post](https://forum.dji.com/forum.php?mod=viewthread&tid=298365)
* [What is timecode?](https://rode.com/en/about/news-info/what-is-timecode-and-why-do-you-need-it)
