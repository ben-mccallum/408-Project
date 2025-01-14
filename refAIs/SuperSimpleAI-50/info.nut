/**
 * This file is part of SuperSimpleAI: An OpenTTD AI.
 *
 * Based on code from SimpleAI, written by Brumi.
 *
 * Author: Jaume Sabater
 *
 * It's free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * any later version.
 *
 * You should have received a copy of the GNU General Public License
 * with it.  If not, see <http://www.gnu.org/licenses/>.
 */

require("version.nut");

class SuperSimpleAI extends AIInfo
{
   function GetAuthor()		{ return "Brumi (SimpleAI) - Jaume Sabater (SuperSimpleAI)"; }
   function GetName()		{ return "SuperSimpleAI"; }
   function GetDescription()	{ return "This AI is a fork from SimpleAI v12 (An AI which tries to imitate the old AI), but much more powerful, competitive and configurable. Version " + GetVersion() + " released on " + GetDate() + "."; }
   function GetVersion()	{ return SELF_VERSION; }
   function GetDate()		{ return SELF_DATE; }
   function MinVersionToLoad()	{ return SELF_LOAD_VERSION; }
   function CreateInstance()	{ return "SuperSimpleAI"; }
   function GetShortName()	{ return "SSAI"; }
   function GetAPIVersion()	{ return "1.2"; }
   function GetURL()		{ return "https://www.tt-forums.net/viewtopic.php?f=65&t=88300"; }

   function GetSettings() {
	AddSetting({
		name = "use_aircraft",
		description = "Use aircraft",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN | CONFIG_INGAME
	});
	if (SELF_INFO_VERSION > 0) {
		AddSetting({
			name = "aircraft_style",
			description = "Style of aircraft routes",
			min_value = 0,
			max_value = 3,
			easy_value = 1,
			medium_value = 2,
			hard_value = 3,
			custom_value = 3,
			flags = CONFIG_INGAME
		});
		AddLabels("aircraft_style", {
			_0 = "Old style, like OTT and TTD, don't replace small airports",
			_1 = "Moderate style, like SimpleAI",
			_2 = "Medium style, with international airports",
			_3 = "Agressive style, with intercontinental airports"
		});
	}
	if (SELF_INFO_VERSION > 1) {
		AddSetting({
			name = "aircraft_line_type",
			description = "Type of aircraft lines",
			min_value = 0,
			max_value = 6,
			easy_value = 6,
			medium_value = 6,
			hard_value = 6,
			custom_value = 6,
			flags = CONFIG_INGAME
		});
		AddLabels("aircraft_line_type", {
			_0 = "Very Short (180 tiles)",
			_1 = "Short (360 tiles))",
			_2 = "Medium (520 tiles)",
			_3 = "Large (768 tiles)",
			_4 = "Very large (1024 tiles)",
			_5 = "Continental (1440 tiles)",
			_6 = "Intercontinental (1920 tiles)"
		});
	}
	AddSetting({
		name = "use_roadvehs",
		description = "Use road vehicles",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN | CONFIG_INGAME
	});
	if (SELF_INFO_VERSION > 0) {
		AddSetting({
			name = "use_localbuses",
			description = "Use local buses",
			easy_value = 0,
			medium_value = 0,
			hard_value = 0,
			custom_value = 0,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "use_regionalbuses",
			description = "Use regional buses",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "use_trucks",
			description = "Use trucks",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "road_line_type",
			description = "Type of road lines",
			min_value = 0,
			max_value = 4,
			easy_value = 3,
			medium_value = 4,
			hard_value = 4,
			custom_value = 4,
			flags = CONFIG_INGAME
		});
		AddLabels("road_line_type", {
			_0 = "Very short (110 tiles, like original AI of TTO and TTD)",
			_1 = "Short (150 tiles)",
			_2 = "Medium (190 tiles)",
			_3 = "Large (230 tiles)",
			_4 = "Very large (280 tiles)"
		});
	}
	if (SELF_INFO_VERSION > 1) {
		AddSetting({
			name = "max_roadvehs",
			description = "The maximum number of road vehicles on a route",
			min_value = 6,
			max_value = 120,
			easy_value = 80,
			medium_value = 100,
			hard_value = 120,
			custom_value = 120,
			flags = CONFIG_INGAME
		});
	}
	AddSetting({
		name = "use_trains",
		description = "Use trains",
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN | CONFIG_INGAME
	});
	if (SELF_INFO_VERSION > 1) {
		AddSetting({
			name = "newgrf_stations"
			description = "Use NewGRF rail stations if available"
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "closest_station"
			description = "Put station closest as possible to industry"
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
	}
	AddSetting({
		name = "fast_rail_pf"
		description = "Use fast PathFinder"
		easy_value = 1,
		medium_value = 1,
		hard_value = 1,
		custom_value = 1,
		flags = CONFIG_BOOLEAN | CONFIG_INGAME
	});
	AddSetting({
		name = "train_line_type",
		description = "Type of freight train lines",
		min_value = 0,
		max_value = 7,
		easy_value = 7,
		medium_value = 7,
		hard_value = 7,
		custom_value = 7,
		flags = CONFIG_INGAME
	});
	AddLabels("train_line_type", {
		_0 = "Only single and 2-crossing lanes (130 tiles, like original AI of TTO and TTD)",
		_1 = "Better line types (130 tiles, like original AI of TTO and TTD)",
		_2 = "Very Short (260 tiles)",
		_3 = "Short (390 tiles))",
		_4 = "Medium (520 tiles)",
		_5 = "Large (768 tiles)",
		_6 = "Very large (1024 tiles)",
		_7 = "Continental (1920 tiles)"
	});
	AddSetting({
		name = "train_pass_line_type",
		description = "Type of passenger train lines",
		min_value = 0,
		max_value = 7,
		easy_value = 2,
		medium_value = 4,
		hard_value = 6,
		custom_value = 5,
		flags = CONFIG_INGAME
	});
	AddLabels("train_pass_line_type", {
		_0 = "Disabled",
		_1 = "Only single and 2-crossing lanes (130 tiles, like original AI of TTO and TTD)",
		_2 = "Better line types (130 tiles, like original AI of TTO and TTD)",
		_3 = "Very Short (260 tiles)",
		_4 = "Short (390 tiles))",
		_5 = "Medium (520 tiles)",
		_6 = "Large (768 tiles)",
		_7 = "Very large (1280 tiles)"
	});
	if (SELF_INFO_VERSION > 1) {
		AddSetting({
			name = "double_platform_pass_sta",
			description = "Allow double platform on long passenger routes",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "signaltype",
			description = "Signal type to be used",
			min_value = 0,
			max_value = 3,
			easy_value = 2,
			medium_value = 2,
			hard_value = 2,
			custom_value = 2,
			flags = CONFIG_INGAME
		});
		AddLabels("signaltype", {
			_0 = "One-way block signals (Transport Tycoon Original)",
			_1 = "Two-way block signals (Transport Tycoon DeLuxe)",
			_2 = "Path signals (Allow more than 2 trains without trafficjams)",
			_3 = "Path signals, even at single rail stations"
		});
	}
	if (SELF_INFO_VERSION > 0) {
		AddSetting({
			name = "train_length",
			description = "Limit the length of freight trains",
			min_value = 0,
			max_value = 21,
			easy_value = 21,
			medium_value = 21,
			hard_value = 21,
			custom_value = 21,
			flags = CONFIG_INGAME
		});
		AddLabels("train_length", {
			_0 = "3 tiles (like original AI of TTO and TTD)",
			_1 = "4 tiles - Short",
			_2 = "5 tiles - Medium",
			_3 = "6 tiles - Long",
			_4 = "7 tiles - Extra Long",
			_5 = "8 tiles - Over normal limit of game configuration",
			_6 = "9 tiles - Over normal limit of game configuration",
			_7 = "10 tiles - Over normal limit of game configuration",
			_8 = "11 tiles - Over normal limit of game configuration",
			_9 = "12 tiles - Over normal limit of game configuration",
			_10 = "13 tiles - Over normal limit of game configuration",
			_11 = "14 tiles - Over normal limit of game configuration",
			_12 = "15 tiles - Over normal limit of game configuration",
			_13 = "16 tiles - Over normal limit of game configuration",
			_14 = "17 tiles - Over normal limit of game configuration",
			_15 = "18 tiles - Over normal limit of game configuration",
			_16 = "19 tiles - Over normal limit of game configuration",
			_17 = "20 tiles - Over normal limit of game configuration",
			_18 = "21 tiles - Over normal limit of game configuration",
			_19 = "22 tiles - Over normal limit of game configuration",
			_20 = "23 tiles - Over normal limit of game configuration",
			_21 = "24 tiles - Over normal limit of game configuration"
		});
		AddSetting({
			name = "min_train_length",
			description = "Minium length of freight trains",
			min_value = 0,
			max_value = 10,
			easy_value = 0,
			medium_value = 1,
			hard_value = 2,
			custom_value = 0,
			flags = CONFIG_INGAME
		});
		AddLabels("min_train_length", {
			_0 = "2 tiles (like original AI of TTO and TTD)",
			_1 = "3 tiles - Very Short",
			_2 = "4 tiles - Short",
			_3 = "5 tiles - Medium",
			_4 = "6 tiles - Long",
			_5 = "7 tiles - Extra Long",
			_6 = "8 tiles - Extra Long - Over normal limit of game configuration",
			_7 = "9 tiles - Extra Long - Over normal limit of game configuration",
			_8 = "10 tiles - Extra Long - Over normal limit of game configuration",
			_9 = "11 tiles - Extra Long - Over normal limit of game configuration",
			_10 = "12 tiles - Extra Long - Over normal limit of game configuration"
		});
		AddSetting({
			name = "max_pass_train_length",
			description = "Limit the length of passenger trains",
			min_value = 0,
			max_value = 3,
			easy_value = 2,
			medium_value = 2,
			hard_value = 3,
			custom_value = 3,
			flags = CONFIG_INGAME
		});
		AddLabels("max_pass_train_length", {
			_0 = "3 tiles - Short (like original AI of TTO and TTD)",
			_1 = "4 tiles - Medium",
			_2 = "5 tiles - Long",
			_3 = "6 tiles - Extra Long"
		});
		AddSetting({
			name = "min_pass_train_length",
			description = "Minium length of passenger trains",
			min_value = 0,
			max_value = 2,
			easy_value = 0,
			medium_value = 0,
			hard_value = 1,
			custom_value = 0,
			flags = CONFIG_INGAME
		});
		AddLabels("min_pass_train_length", {
			_0 = "2 tiles - Short (like original AI of TTO and TTD)",
			_1 = "3 tiles - Medium",
			_2 = "4 tiles - Long"
		});
	}
	if (SELF_INFO_VERSION > 1) {
		AddSetting({
			name = "train_engines",
			description = "Use multiple engines",
			min_value = 0,
			max_value = 7,
			easy_value = 7,
			medium_value = 7,
			hard_value = 7,
			custom_value = 7,
			flags = CONFIG_INGAME
		});
		AddLabels("train_engines", {
			_0 = "Single engine",
			_1 = "Two engines",
			_2 = "Three engines",
			_3 = "Four engines",
			_4 = "Five engines",
			_5 = "Six engines",
			_6 = "Seven engines",
			_7 = "Eight engines"
		});
		AddSetting({
			name = "lane_overlength",
			description = "Oversize the length of passing lanes on passengers lines",
			min_value = 0,
			max_value = 5,
			easy_value = 0,
			medium_value = 1,
			hard_value = 2,
			custom_value = 0,
			flags = CONFIG_INGAME
		});
		AddLabels("lane_overlength", {
			_0 = "None (Like original AI of TTO and TTD)",
			_1 = "1 extra tiles - Very short",
			_2 = "2 extra tiles - Short",
			_3 = "3 extra tiles - Medium",
			_4 = "4 extra tiles - Long",
			_5 = "5 extra tiles - Extra long"
		});
		AddSetting({
			name = "train_double_cargo",
			description = "Allow double cargo trains",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "flat_lane",
			description = "Force to build flat passing lanes",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
	}
	if (SELF_INFO_VERSION > 0) {
		AddSetting({
			name = "electrify_old",
			description = "Electrify old rail lines",
			min_value = 0,
			max_value = 3,
			easy_value = 1,
			medium_value = 2,
			hard_value = 3,
			custom_value = 2,
			flags = CONFIG_INGAME
		});
		AddLabels("electrify_old", {
			_0 = "Never",
			_1 = "Only passenger routes",
			_2 = "Passenger lines and busy cargo lines",
			_3 = "All routes"
		});
		AddSetting({
			name = "close_unprofitable_routes",
			description = "Close unprofitable road and rail routes",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "max_transported",
			description = "Build new routes if transported percentage is smaller than this value",
			min_value = 1,
			max_value = 100,
			easy_value = 1,
			medium_value = 10,
			hard_value = 20,
			custom_value = 1,
			flags = CONFIG_INGAME
		});
		AddSetting({
			name = "subsidy_chance",
			description = "The chance of taking subsidies",
			min_value = 0,
			max_value = 10,
			easy_value = 0,
			medium_value = 0,
			hard_value = 1,
			custom_value = 0,
			flags = CONFIG_INGAME
		});
	}
	AddSetting({
		name = "waiting_time",
		description = "Days to wait between building two routes",
		min_value = 0,
		max_value = 365,
		easy_value = 30,
		medium_value = 15,
		hard_value = 0,
		custom_value = 0,
		step_size = 5,
		flags = CONFIG_INGAME
	});
	AddSetting({
		name = "slowdown",
		description = "Slowdown effect (how much the AI will become slower over time)",
		min_value = 0,
		max_value = 3,
		easy_value = 2,
		medium_value = 1,
		hard_value = 0,
		custom_value = 0,
		flags = CONFIG_INGAME
	});
	AddLabels("slowdown", {
		_0 = "none",
		_1 = "little",
		_2 = "medium",
		_3 = "high"
	});
	if (SELF_INFO_VERSION > 0) {
		AddSetting({
			name = "rename_airports",
			description = "Rename airports",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "rename_stations",
			description = "Rename road and rail stations",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "build_statue",
			description = "Build statue of company's owner",
			easy_value = 0,
			medium_value = 0,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
	}
	if (SELF_INFO_VERSION > 1) {
		AddSetting({
			name = "hq_in_town",
			description = "Build company headquarters near towns",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN
		});
		AddSetting({
			name = "use_custom_companyname",
			description = "Use a custom company name",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN
		});
		AddSetting({
			name = "date_format",
			description = "Date format",
			min_value = 0,
			max_value = 2,
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_INGAME
		});
		AddLabels("date_format", {
			_0 = "YYYY-MM-DD",
			_1 = "DD/MM/YYYY",
			_2 = "MM/DD/YYYY"
		});
	}
	if (SELF_INFO_VERSION > 2) {
		AddSetting({
			name = "SuperSimpleAI_log",
			description = "Log SuperSimpleAI messages",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "SuperSimpleAI_log_debug",
			description = "Log debug SuperSimpleAI messages",
			easy_value = 0,
			medium_value = 0,
			hard_value = 0,
			custom_value = 0,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "cBuilder_log",
			description = "Log cBuilder messages",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "cBuilder_log_debug",
			description = "Log debug cBuilder messages",
			easy_value = 0,
			medium_value = 0,
			hard_value = 0,
			custom_value = 0,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "cManager_log",
			description = "Log cManager messages",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
		AddSetting({
			name = "cManager_log_debug",
			description = "Log debug cManager messages",
			easy_value = 0,
			medium_value = 0,
			hard_value = 0,
			custom_value = 0,
			flags = CONFIG_BOOLEAN | CONFIG_INGAME
		});
	}
   }
}

RegisterAI(SuperSimpleAI());
