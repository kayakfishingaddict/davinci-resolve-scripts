# DJI OSMO Action 4 Serious Timecode Bug Fix

This [script](https://github.com/kayakfishingaddict/davinci-resolve-scripts/blob/master/DJI%20OA4%20Serious%20Timecode%20Bug%20Fix.lua) fixes the timecode gap bug identified in this video [https://youtu.be/TMY9J1RW6r4](https://youtu.be/TMY9J1RW6r4).

## Description

Essentially, DJI has a timecode bug that they refuse to fix because it is complicated.  Interestingly, GoPro has the same bug.  In loop mode these cameras segment video files.  The segments use the free running clock to set the starting timecode for the newly created segment.  The newly created segment is a contiguous video that should not have any timecode gaps, however, the timecode does not turn out to be contiguous with the ending timecode of the prior segment.  That is the bug.

This script walks through the DJI video clips in the Media tab, identifies which ones are supposed to be contiguous using the filename formats, and then repairs the timecode gaps.  The clips can subsequently be added to a timeline using timecode without issue.  This automation saves hours of work in post processing required to close gaps between segments of a continuously shot scene.

## Getting Started

### Dependencies

* Davinci Resolve 18 or higher
* Recordings from OSMO Action 4 cameras, synchronized with timecode reportedly only with looping mode turned on.
* Video file names should be in the following format: DJI_20240506120600_0002_D_A00_003.MP4 which is the default.

### Installing

Place the script in the following directory on your computer and then launch Davinci Resolve.

* Mac: /Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility
* Windows: %PROGRAMDATA%\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Utility
* Linux: /opt/resolve/Fusion/Scripts/Utility (or /home/resolve/Fusion/Scripts/Utility depending on installation)

### Executing program

You can run the script from the Workspace -> Scripts menu option; and you can see any log messages the script produces in the Workspace -> Console.

## Help

## Authors

Contributors names and contact info

ex. [@KayakFishingAddict](https://youtube.com/kayakfishingaddict)

## Version History

* 0.1
  * Initial Release - does not include DF support

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Discussions & Background

* [Video](https://youtu.be/TMY9J1RW6r4)
* [DJI Forum Post](https://forum.dji.com/forum.php?mod=viewthread&tid=298365)
* [What is timecode?](https://rode.com/en/about/news-info/what-is-timecode-and-why-do-you-need-it)
