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