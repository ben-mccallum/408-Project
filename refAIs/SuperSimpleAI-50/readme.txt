SuperSimpleAI v40 - 2023/02/20
------------------------

Contents
--------
1. Introduction
2. Usage
3. Parameters
4. Recommended configuration
5. Dependencies
6. License
7. Support

1. Introduction
---------------
SuperSimpleAI is an AI written for OpenTTD, which tries to enhace the possibilities of old AI.
The AI builds simple point-to-point routes (which can has passing stations) using road
vehicles, trains and aircraft. Station layout is similar to that of the old AI.
SuperSimpleAI supports all default cargoes, but it will try to use most NewGRF
cargoes as well.

2. Usage
--------
This AI can be used just like any other AI, see http://wiki.openttd.org/AI_settings
for details.

3. Parameters
-------------
Number of days to start this AI after the previous one (give or take) - You can configure
how much time the AI will wait before founding its company.

Use aircraft - Allows/disallows building aircraft for SuperSimpleAI.

Style of aircraft routes - Less to more agressive use of aircrafts.

Use road vehicles - Allows/disallows building road vehicles for SuperSimpleAI.

Use local buses - Allows/disallows building local (town) buses. Because poor code, this
setting is disabled by default.

Use regional buses - Allows/disallows building regional (town to town) buses.

Use trucks - Allows/disallows building freight road routes.

Type of road lines - The length of road routes. In OTT, TTD and SimpleAI road routes are
shorter than 130 tiles.

Use trains - Allows/disallows building trains for SuperSimpleAI.

Faster railbuilding, using fake passing lanes (like checkpoints) between passing lanes.
This changes how passenger rail routes are made.

Type of freight train lines - The length of freight train routes. In OTT, TTD and SimpleAI
train routes are shorter than 130 tiles.

Type of passenger train lines - The length of passenger train routes. In OTT, TTD and SimpleAI
train routes are shorter than 130 tiles.

Limit the length of freight trains - The length of freight trains. In OTT, TTD and SimpleAI
the limit is setted to 3 tiles. This AI can manage 24 tiles long trains, but Game Settings
overrides this values.

Minium length of freight trains - Setting the minium length of trains can help the AI to
build profitable routes. In OTT, TTD and SimpleAI the minium length of trains are 2 tiles.
If you play with default Industry Set or any set that industry production grows if they're
serviced, setting the minium to 7 or more wil be a good option.

Limit the length of passenger trains - The length of passenger trains. In OTT, TTD and
SimpleAI the limit is setted to 3 tiles. This AI can manage 6 tiles long passenger trains.

Minium length of passenger trains - Setting the minium length of trains can help the AI to
build profitable routes. In OTT, TTD and SimpleAI the minium length of trains are 2 tiles.

Electrify old rail lines - Electrifying steam rail lines allow to use more powered engines,
but can create unrealistic networks. With this setting you can choose hoe these old lines
can be electrified, or simply disabling electrification of old lines from steam era.

Close unprofitable road and rail routes - You can disallow the closure of unprofitable routes
or allow it. In some cases (early stages of game, slow start, poorly finances, ...) can cause
premature closure of under-developed routes, it's a good idea wait to start whitout allowing
the closure of.these young routes.

Build new routes if transported percentage is smaller than this value - With this setting
you can configure how much SuperSimpleAI will compete with other companies. The higher the
value, the more competitive SimpleAI will be. When building a new connection, firstly it
checks how much of the cargo is transported from the given industry by other companies. If
it is higher than this value, the AI will move on to another industry.

The chance of taking subsidies - This setting allows you to configure how much the AI will
go for subsidies. The AI will ignore subsudies if it is set to 0, and will always try to get
subsidies if it is set to 10. It is recommended to set it to a lower value if more instances
of SimpleAI or SuperSimpleAI are present in the game.

Days to wait between building two routes - If a new route is built successfully, the AI will
wait for the configured time before it tries to build a new one. If this setting is set to 0,
the AI will try to build a new route immediately after the previous one.

Slowdown effect (how much the AI will become slower over time) - If this is enabled, the
waiting time defined in the previous setting will increase over time. With this the AI
will slow down if it has plenty of routes. You can configure how fast the waiting time
will increase.

Rename Airports - Setting to false keeps the old style of names, like OTT, TTD and SimpleAI.

Rename road and rail stations - Setting to false keeps the old style of names, like OTT, TTD
and SimpleAI. Setting to true creates a new name with Company Name,route ID, SRC|PASS|DST
and year.

Build statue of company's owner - Allow SuperSimpleAI to build statues when cash is not a
problem. OTT, TTD and SimpleAI doesn't build statues.

Note: If you disallow using a specific vehicle type for all AIs in the Advanced settings,
these settings are overridden. However, if you want to change these settings during the
game, changing the AI's own settings is preferred, as it still allows to finish the route
under construction and to maintain existing vehicles.

4. Recommended configuration
----------------------------
SuperSimpleAI is not compatibile with articulated road vehicles (it is no problem if there
are articulated vehicles present, the AI just won't use them).

It is also recommended to enable building on slopes, as the AI doesn't terraform while
building tracks.

Enabling vehicle breackdowns may cause problems, because very large routes with only one
depot per route.

Disabling 90 degree turns for trains may cause problems, in some cases, while rebuilding
interrupted rail can cause 90 degree turns. Rail stations suport forbidden 90 degree turns.

SuperSimpleAI can build very large rail stations, up to 24 tiles. Setting train and station
length to 24 or more is strongly recomended.

This AI is suitable for running multiple instances of it, although it is better to lower
the subsidy chance factor if you're using multiple instances, so that not all instances
will try to build at the same place when a new subsidy appears.

5. Dependencies
---------------
SuperSimpleAI depends on the following libraries:
- Pathfinder.Road v4
- Pathfinder.Rail v1
- Graph.AyStar v4 (a dependency of the rail pathfinder)
- Graph.AyStar v6 (a dependency of the road pathfinder)
- Queue.BinaryHeap v1 (a dependency of Graph.AyStar)
If you downloaded this AI from the in-game content downloading system, these libraries
also got installed automatically. However if you downloaded this AI manually from the
forums or somewhere else, then you need to install these libraries as well.
The libraries can be downloaded here: http://noai.openttd.org/downloads/Libraries/
Install these libraries into the ai/library subdirectory of OpenTTD.
Or you can download SimpleAI from the in-game content downloading system, which uses
same libraries.

6. License
----------
SuperSimpleAI is licensed under version 2 of the GNU General Public License. See license.txt
for details.
SuperSimpleAI reuses code from NoCAB (Terraform.nut), PAXLink (cBuilder::CostToFlattern),
DictatorAI (MyAIEngine::GetEngineEfficiency), WormAI (some pathfinder modifications),
SuperLib (MyMath class) and SimpleAI (tons and tons of code)
The AI contains code contributed by 3iff: setcompanyname.nut

7. Support
----------
Discussion about SuperSimpleAI and testing versions can be found here: 
TT Forums: https://www.tt-forums.net/viewtopic.php?f=65&t=88300
You're welcome to post bug reports and other comments :)
