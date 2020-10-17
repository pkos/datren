datren v0.5 - Utility to compare No-Intro or Redump dat files to the rom or disc collection
              and rename the matching files (by crc) to the dat standard.

with datren [ options ] [dat file ...] [directory ...] [system]

Options:
  -rename  rename files with matching dat entries otherwise just log

Example:
              datren -rename "D:/Atari - 2600.dat" "D:/Atari - 2600/Games" "Atari - 2600"

Author:
   Discord - Romeo#3620


Notes
--------------------------------------
v0.5 - Does not include zip support yet, and does not include disc serial checking (only crc).
