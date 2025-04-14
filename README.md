# Fusion 360 Post Processors

Included is some of my Fusion 360 post processor tweaks to the base upstream posts.

#### Brother Speedio

The `brother speedio.cps` is the stock Brother Speedio post processor with some of my own tweaks:

* Enabled passthrough support
* Removed 1 second minimum dwell instrumentation
* Updated stop operations to retract to the home location
* Added NC property to easily control the smoothing criteria between stock to leave or tolerances
* Updated some of the base thresholds for finishing vs roughing
* Fixed probing in Z with the Blum probe
* Added support for tool break detection through tool library setting

#### Tool Sheet (HTML/SVG)

The `tool sheet svg.cps` is a revamp of the Audodesk Tool Sheet to be optimized to just the most
relevant info with an effective use of space.

The stock tool sheet post includes a lot of fields that aren't relevant to
loading tools into the machine. Its formatted such that it creates a lot of
blank space, so it becomes many pages, or requires scaling it down to get some
balance.

This post focuses on only the most relevant information. Organized in a way
to make the most use of the space. A normal page should fit 12 tools with
normal margins and scale settings. If you have duplex printing, you can fit
24 tools on a single sheet.

It also has options for "output tool as name" and "show radius values" which
can be useful on controls that like tool radius rather than diameter (like Heidenhain).
