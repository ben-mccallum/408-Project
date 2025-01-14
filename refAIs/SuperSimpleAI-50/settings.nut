/**
 * This file is part of SuperSimpleAI: An OpenTTD AI.
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

/**
 * Some magic numbers that changes how this AI works.
 * Because all settings of info.nut file are optional, some values are dependent
 * of AIGameSettings.GetValue("settings_profile"), if they aren't in info.nut file.
 * If they are setted in info.nut file, AIGameSettings.GetValue("settings_profile")
 * doesn't have any effect in this AI, except in info.nut settings. Note: this func-
 * tion is called via MyAIGameSettings.GetSettingsProfile().
 */

class AISettings
{
	root = null; // Reference to the main SuperSimpleAI instance
	constructor(that)
	{
		root = that;
	}
	
	/**
	 * This is the (only) function than loads settings from info.nut file. The only file
	 * where this function is used is this file. No other files uses this function or
	 * AIController.GetSetting() function. This function allow all settings of info.nut
	 * file to be optional.
	 * @param name The name of setting to get value.
	 * @param def The default value if name is not found in info.nut file.
	 * @return The value of name's setting.
	 */
	static function GetAISetting(name, def = null) { return (AIController.GetSetting(name) == -1) ? def : AIController.GetSetting(name); }

	/********************
	 * General Settings *
	 ********************/

	/**
	 * Limit de maximum number of routes.
	 * This is the warning that Mr. Brumi put in SimpleAI code: "Do not build more than 1000 routes, it may crash on loading."
	 */
	static function MaxRoutes()		{ return 2400; }

	/**
	 * This setting controls how often Manager.CheckRoutes runs.
	 * Values are:
	 * 1 - Use maximum 50% of time.
	 * 2 - Use maximum 33% of time.
	 * 3 - Use maximum 25% of time.
	 * 4 - Use maximum 20% of time.
	 */
	static function DaysBeforeRunManagerMainLoop()	{ return 5; }

	/**
	 * Get waiting time before build a new route.
	 * @return time in days, by default some value between 0 and 30, it depends of "settings_profile" config parameter.
	 */
	static function GetWaitingTime()	{ return AISettings.GetAISetting("waiting_time", 30 - 15 * MyAIGameSettings.GetSettingsProfile()); }

	/**
	 * Get slowdown effect (wait more time when we have more routes).
	 * @return 0 (none), 1 (soft) or 2 (hard). By default, it depends of "settings_profile" config parameter.
	 */
	static function GetSlowdownEffect()	{ return AISettings.GetAISetting("slowdown", 2 - MyAIGameSettings.GetSettingsProfile()); }

	/**
	 * Get the subsidy change (0..10).
	 * @return value between 0 to 10. By default, it depends of "settings_profile" config parameter.
	 */
	static function GetSubsidyChange()	{ return AISettings.GetAISetting("subsidy_chance", 2 - MyAIGameSettings.GetSettingsProfile()); }

	/**
	 * Maximum percentage of transported cargo before build a new route.
	 * @return value between 0 to 99. By default, it depends of "settings_profile" config parameter, from 1 to 30.
	 */
	static function GetMaxTransported()	{ return AISettings.GetAISetting("max_transported", 15 * MyAIGameSettings.GetSettingsProfile()); }

	/**
	 * Close routes when the are unprofitable.
	 * @return True if can be closed.
	 */
	static function CloseUnprofitableRoutes()	{ return AISettings.GetAISetting("close_unprofitable_routes", true); }

	/**
	 * I don't remember if in OTT or TTD the HQ was builded or not in towns...
         * @return True if we can build in towns. True by default.
	 */
	static function BuildHQInTown()		{ return AISettings.GetAISetting("hq_in_town", true); }

	/**
	 * This feature is a contribution by 3iff to a SimpleAI project.
         * @return True if we can use custom company names. True by default.
	 */
	static function UseCustomCompanyName()	{ return AISettings.GetAISetting("use_custom_companyname", true); }

	/**
	 * Return true if we can build a statue.
         * @return True if we can build statue. By default, this setting is set to true when settings profile is hard.
	 */
	static function CanBuildStatue()	{ return AISettings.GetAISetting("build_statue", (MyAIGameSettings.GetSettingsProfile() == 2)); }

	/**
         * Minium money to build statue of company's owner.
         * @return The minimum amount of money to build statue.
	 */
	static function MiniumMoneyToBuildStatue()	{ return Banker.InflatedValue(850000); }

	/**
	 * Date format to print to console.
	 */
	static function GetDateFormat()		{ return AISettings.GetAISetting("date_format", 1); }

	/****************
	 * Air Settings *
	 ****************/

	/**
	 * Use aircrafts?
         * @return True if we can use it.
	 */
	static function UseAircraft()		{ return AISettings.GetAISetting("use_aircraft", true) && !AIGameSettings.GetValue("ai_disable_veh_aircraft"); }

	/**
	 * Style of air routes.
         * @return 0 to TTO/TTD style, 1 to moderate style, 2 to medium style or 3 to hard style.
	 */
	static function GetAircraftStyle()	{ return AISettings.GetAISetting("aircraft_style", MyAIGameSettings.GetSettingsProfile() + 1); }

	/**
	 * List of airports to use in Old Style, Moderate Style, Medium Stle, Agressive Style.
	 */
	static function GetOldStyleAirports()		{ return [AIAirport.AT_LARGE, AIAirport.AT_SMALL]; }
	static function GetModerateStyleAirports()	{ return [AIAirport.AT_METROPOLITAN, AIAirport.AT_LARGE, AIAirport.AT_COMMUTER, AIAirport.AT_SMALL]; }
	static function GetMediumStyleAirports()	{ return [AIAirport.AT_INTERNATIONAL, AIAirport.AT_METROPOLITAN, AIAirport.AT_LARGE, AIAirport.AT_COMMUTER, AIAirport.AT_SMALL]; }
	static function GetAgressiveStyleAirports()	{ return [AIAirport.AT_INTERCON, AIAirport.AT_INTERNATIONAL, AIAirport.AT_METROPOLITAN, AIAirport.AT_LARGE, AIAirport.AT_COMMUTER, AIAirport.AT_SMALL]; }

	/**
	 * Some extra style functions.
	 */
	static function IsOldStyleAircraft()		{ return (AISettings.GetAircraftStyle() == 0); }
	static function IsModerateStyleAircraft()	{ return (AISettings.GetAircraftStyle() == 1); }
	static function IsMediumStyleAircraft()		{ return (AISettings.GetAircraftStyle() == 2); }
	static function IsAgressiveStyleAircraft()	{ return (AISettings.GetAircraftStyle() == 3); }
	static function GetAirStyleName()		{ return (AISettings.IsAgressiveStyleAircraft()) ? "agressive" : ((AISettings.IsMediumStyleAircraft()) ? "medium" : "moderate"); }

	/**
	 * How much money we need before start to build new air routes.
         * @return The minimum amount of money to build new air route.
	 */
	static function MinimumMoneyToBuildOldStyleAirRoute()		{ return Banker.InflatedValue(150000); }
	static function MinimumMoneyToBuildModerateStyleAirRoute()	{ return Banker.InflatedValue(120000); }
	static function MinimumMoneyToBuildMediumStyleAirRoute()	{ return Banker.InflatedValue(90000); }
	static function MinimumMoneyToBuildAgressiveStyleAirRoute()	{ return Banker.InflatedValue(60000); }

	/**
	 * Return the minimum production before create a passenger air route.
	 */
	static function GetAirMinProduction()	{ return 150; }

	/**
	 * Return the minimum distance that an aircraft route can be build.
	 */
	static function GetAirMinDistance()		{ return (AISettings.GetAISetting("aircraft_line_type", 0) == 0) ? 128 : 200; }

	/**
	 * Return the percentage of builder attempts to build an air route when road and rail are enabled.
	 * This percentage is doubled if road or rail isn't allowed.
	 */
	static function GetModerateAirIntensity()	{ return 15; }
	static function GetMediumAirIntensity()		{ return 30; }
	static function GetAgressiveAirIntensity()	{ return 45; }

	/**
	 * Return de maximum aircraft per route. (1..5)
	 */
	static function MaxAircraftPerRoute()	{ return (AISettings.IsOldStyleAircraft()) ? 2 : AISettings.GetAircraftStyle(); }

	/**
	 * Replace old airports with greater ones?
	 * @return True if replace airports.
 	*/
	static function ReplaceOldAirports()		{ return !AISettings.IsOldStyleAircraft(); }

	/**
	 * Return the maximum distance that an aircraft route can be build.
	 * These numbers may be coherent with info.nut's numbers.
	 */
	static function GetAirMaxDistance()
	{
		if (!AISettings.UseAircraft()) return 0;
		local aircraft_type = AISettings.GetAISetting("aircraft_line_type", 6);
		if (aircraft_type > 5) return 1920;
		if (aircraft_type > 4) return 1440;
		if (aircraft_type > 3) return 1024;
		if (aircraft_type > 2) return 768;
		if (aircraft_type > 1) return 520;
		if (aircraft_type > 0) return 360;
		return 180;
	}

	/**
	 * Get the capacity of an airport type.
	 * @param airport_type The airport type.
	 * @return The maximum amount of planes which can use the airport.
	 */
	static function GetAirportTypeCapacity(airport_type)
	{
		if (!AIAirport.IsAirportInformationAvailable(airport_type)) return 0;
		if (airport_type == AIAirport.AT_SMALL) return 4;
		if (airport_type == AIAirport.AT_COMMUTER) return 6;
		if (airport_type == AIAirport.AT_LARGE) return 7;
		if (airport_type == AIAirport.AT_METROPOLITAN) return 8;
		if (airport_type == AIAirport.AT_INTERNATIONAL) return 12;
		if (airport_type == AIAirport.AT_INTERCON) return 16;
		return 0;
	}

	/**
	 * Rename airports?
	 */
	static function RenameAirports()		{ return AISettings.GetAISetting("rename_airports", !AISettings.IsOldStyleAircraft()); }

	/*********************************
	 * Road and Rail Common Settings *
	 *********************************/

	/**
	 * Get the minimum distance that a road or rail route can be build.
	 * These numbers may be coherent with info.nut's numbers.
	 * @return Minimum distance.
	 */
	static function GetRoadOrRailMinDistance()	{ return 35; }

	/**
	 * Minium money to build fast bridges.
	 * @return The minimum amount of money to build a fast bridge.
	 */
	static function MiniumMoneyToUseFastBridges()	{ return Banker.InflatedValue(100100 + 100000 * MyMath.Squared(AIGameSettings.GetValue("construction_cost"))); }

	/**
	 * Minium money to upgrade bridges to a faster one..
	 * @return The minimum amount of money to upgrade a bridge.
	 */
	static function MiniumMoneyToUpgradeBridges()	{ return Banker.InflatedValue(500000); }

	/**
	 * Build stations as nearest as possible to industries?
	 */
	static function IsClosestStation()		{ return AISettings.GetAISetting("closest_station", !AISettings.IsOldStyleRailLine()); }

	/**
	 * Get cost of a bridge head when they aren't on flat/well sloped tile.
	 * @return Inflated cost.
	 */
	static function GetBridgeHeadCost()		{ return (AIGameSettings.GetValue("construction_cost") > 1) ? Banker.InflatedValue(11000) : Banker.InflatedValue(3000); }

	/**
	 * Rename stations?
	 */
	static function RenameStations()		{ return AISettings.GetAISetting("rename_stations", !AISettings.IsOldStyleRailLine()); }

	/*****************
	 * Rail Settings *
	 *****************/

	/**
	 * Use trains?
	 */
	static function UseRail()		{ return AISettings.GetAISetting("use_trains", true) && !AIGameSettings.GetValue("ai_disable_veh_train"); }

	/**
	 * Use passenger trains?
	 */
	static function UsePassTrains()		{ return (AISettings.GetAISetting("train_pass_line_type", 7) != 0); }

	/**
	 * Check if we have limited the rail lines like OTT and TTD.
	 * @return True if we are in Old Style AI.
	 */
	static function IsOldStyleRailLine()	{ return (AISettings.GetAISetting("train_line_type", 7) == 0); }

	/**
	 * Are dual cargo trains allowed? (for example grain and livestock)
	 */
	static function AllowDoubleCargoTrains()	{ return AISettings.GetAISetting("train_double_cargo", !AISettings.IsOldStyleRailLine()); }

	/**
	 * Are dual destination rail routes allowed? (With dual cargo trains set to true)
	 */
	static function AllowDoubleDestinationRailRoutes()	{ return (AISettings.AllowDoubleCargoTrains()) ? AISettings.GetAISetting("train_double_dst", true) : false; }

	/**
	 * Minium distance to build double cargo lines
	 */
	static function GetDoubleDestinationMinDistance()	{ return 150; }

	/**
	 * Maxmimum distance between destination station and passing station.
	 */
	static function GetMaxDstPasDistance()	{ return AISettings.FastRailPathFinder() ? 125 : 105; }

	/**
	 * Fast rail building. Enabled by default.
	 */
	static function FastRailBuild()		{ return AISettings.GetAISetting("fast_build", true); }

	/**
	 * Fast rail PathFinder. Enabled by default.
	 */
	static function FastRailPathFinder()		{ return AISettings.GetAISetting("fast_rail_pf", true); }

	/**
	 * Use NewGrF Stations if they are available?
	 */
	static function UseNewGRFStations()	{ return AISettings.GetAISetting("newgrf_stations", !AISettings.IsOldStyleRailLine()); }

	/**
	 * Control how stations can be build.
	 */
	static function ArePassengerStationsDouble()	{ return AISettings.GetAISetting("double_platform_pass_sta", false); }
	static function IsDestinationStationDouble()	{ return false; } // doesn't work...

	/**
	 * Minimum active routes to build electrifyed rail lines.
	 */
	static function MinRoutesToBuildElectrifiedRail()	{ return 20;}

	/**
	 * Electrify old rail lines?
	 *    0 = Never
	 *    1 = Passenger lines only
	 *    2 = Cargo lines if are busy, and passenger lines too
	 *    3 = All lines
	 */
	static function ElectrifyOldRailLines()		{ return AISettings.GetAISetting("electrify_old", 2); }

	/**
	 * Minium money to electrify rail lines.
	 */
	static function MinMoneyToElectrify()		{ return Banker.InflatedValue(400000); }

	/**
	 * Attempts to build engine if they are blacklisted.
	 */
	static function EngineBlackListLoop()		{ return 15; }

	/**
	 * How long and powered can be trains.
	 */
	static function GetMaxNumEngines()		{ return AISettings.GetAISetting("train_engines", 7); }			// 0..7
	static function GetCargoTrainMaxLength()	{ return AISettings.GetAISetting("train_length", 21) + 3; }		// 0..21
	static function GetCargoTrainMinLength()	{ return AISettings.GetAISetting("min_train_length", 2) + 2; }		// 0..10
	static function GetPassTrainMaxLength()		{ return AISettings.GetAISetting("max_pass_train_length", 2) + 2; }	// 0..2
	static function GetPassTrainMinLength()		{ return AISettings.GetAISetting("min_pass_train_length", 0) + 2; }	// 0..1

	/**
	 * Type os signal to use.
	 */
	static function IsSignalTypePBS()	{ return (AISettings.GetAISetting("signaltype", 2) > 1); }
	static function NeedExtraSignal()	{ return (AISettings.GetAISetting("signaltype", 2) == 3); } // The extra signal in single lines from SimpleAI.
	static function GetSignalType()		{ return (AISettings.GetAISetting("signaltype", 2) > 0) ? ((!AISettings.IsSignalTypePBS()) ? AIRail.SIGNALTYPE_TWOWAY : AIRail.SIGNALTYPE_PBS_ONEWAY) : AIRail.SIGNALTYPE_NORMAL; }

	/**
	 * Determine size and if passing lanes are flat or not.
	 */
	static function IsFlatLane()			{ return AISettings.GetAISetting("flat_lane", !AISettings.IsOldStyleRailLine()); }

	/**
	 * Difference of heigh between two passing lanes or stations.
	 */
	static function MaxDiffPassingLaneHeigh()	{ return (AISettings.IsOldStyleRailLine()) ? 32 : (AISettings.FastRailPathFinder() ? 4 : 5); }

	/**
	 * Build passing lane larger than platforms are?
	 */
	static function OversizePassingLane()		{ return AISettings.GetAISetting("lane_overlength", 0); }

	/**
	 * Get the maximum distance that a cargo rail route can be build.
	 * These numbers may be coherent with info.nut's numbers.
	 * @param counter The buildcounter, or > 99 if we want large routes from start.
	 * @return maximum distance.
	 */
	static function GetCargoRailMaxDistance(counter = 99)
	{
		if (!AISettings.UseRail()) return 0;
		local train_type = AISettings.GetAISetting("train_line_type", 7);
		local ret = 100;
		if (counter > 2) ret = 140;
		if (train_type > 1 && counter > 4) ret = 170;
		if (train_type > 1 && counter > 6) ret = 210;
		if (train_type > 2 && counter > 8) ret = 260;
		if (train_type > 2 && counter > 10) ret = 330;
		if (train_type > 3 && counter > 12) ret = 390;
		if (train_type > 3 && counter > 14) ret = 450;
		if (train_type > 4 && counter > 16) ret = 520;
		if (train_type > 4 && counter > 18) ret = 620;
		if (train_type > 5 && counter > 20) ret = 768;
		if (train_type > 5 && counter > 22) ret = 1024;
		if (train_type > 6 && counter > 24) ret = 1280;
		if (train_type > 6 && counter > 26) ret = 1440;
		if (train_type > 6 && counter > 28) ret = 1600;
		if (train_type > 6 && counter > 30) ret = 1720;
		if (train_type > 6 && counter > 32) ret = 1840;
		if (train_type > 6 && counter > 34) ret = 1920;
		return ret;
	}

	/**
	 * Get the maximum distance that a passengers rail route can be build.
	 * These numbers may be coherent with info.nut's numbers.
	 * @param counter The buildcounter, or > 99 if we want large routes from start.
	 * @return maximum distance.
	 */
	static function GetPassRailMaxDistance(counter = 99)
	{
		if (!AISettings.UseRail()) return 0;
		local train_type = AISettings.GetAISetting("train_pass_line_type", 7);
		local ret = 0;
		if (train_type > 0) ret = 100;
		if (train_type > 0 && counter > 2) ret = 130;
		if (train_type > 2 && counter > 4) ret = 160;
		if (train_type > 2 && counter > 6) ret = 190;
		if (train_type > 2 && counter > 8) ret = 220;
		if (train_type > 2 && counter > 10) ret = 260;
		if (train_type > 3 && counter > 12) ret = 300;
		if (train_type > 3 && counter > 14) ret = 340;
		if (train_type > 4 && counter > 16) ret = 390;
		if (train_type > 4 && counter > 18) ret = 450;
		if (train_type > 4 && counter > 20) ret = 520;
		if (train_type > 5 && counter > 22) ret = 580;
		if (train_type > 5 && counter > 24) ret = 650;
		if (train_type > 5 && counter > 26) ret = 720;
		if (train_type > 6 && counter > 28) ret = 860;
		if (train_type > 6 && counter > 30) ret = 1024;
		if (train_type > 6 && counter > 32) ret = 1280;
		return ret;
	}

	/**
	 * Get needed passinglanes for a rail route, depending of distance.
	 * These numbers may be coherent with info.nut's numbers.
	 * @param dist The distance between two stations
	 * @param iscrg Boolean cargo = true; passengers = false
	 * @return Number of passing lanes (0..15).
	 */
	static function GetNumberOfPassingLanes(dist, iscrg)
	{
		local passinglanes = 0;
		if (AISettings.FastRailPathFinder()) {
			if (iscrg) {	// Cargo routes
				if (dist > 170) passinglanes = 1;
				if (dist > 340) passinglanes = 2;
				if (dist > 510) passinglanes = 3;
				if (dist > 680) passinglanes = 4;
				if (dist > 850) passinglanes = 5;
				if (dist > 1020) passinglanes = 6;
				if (dist > 1190) passinglanes = 7;
			} else {	// Passenger routes
				passinglanes = 1;
				if (dist > 150) passinglanes = 2;
				if (dist > 250) passinglanes = 3;
				if (dist > 350) passinglanes = 4;
				if (dist > 450) passinglanes = 5;
				if (dist > 550) passinglanes = 6;
				if (dist > 650) passinglanes = 7;
			}
		} else {
			if (iscrg) {	// Cargo routes
				if (dist > 120) passinglanes = 1;
				if (dist > 240) passinglanes = 2;
				if (dist > 360) passinglanes = 3;
				if (dist > 480) passinglanes = 4;
				if (dist > 600) passinglanes = 5;
				if (dist > 720) passinglanes = 6;
				if (dist > 840) passinglanes = 7;
				if (dist > 960) passinglanes = 8;
				if (dist > 1080) passinglanes = 9;
				if (dist > 1200) passinglanes = 10;
				if (dist > 1320) passinglanes = 11;
				if (dist > 1440) passinglanes = 12;
				if (dist > 1560) passinglanes = 13;
				if (dist > 1680) passinglanes = 14;
				if (dist > 1800) passinglanes = 15;
			} else {	// Passenger routes
				passinglanes = 1;
				if (dist > 120) passinglanes = 2;
				if (dist > 200) passinglanes = 3;
				if (dist > 280) passinglanes = 4;
				if (dist > 340) passinglanes = 5;
				if (dist > 420) passinglanes = 6;
				if (dist > 500) passinglanes = 7;
				if (dist > 580) passinglanes = 8;
				if (dist > 660) passinglanes = 9;
				if (dist > 740) passinglanes = 10;
				if (dist > 820) passinglanes = 11;
				if (dist > 900) passinglanes = 12;
				if (dist > 980) passinglanes = 13;
				if (dist > 1060) passinglanes = 14;
				if (dist > 1140) passinglanes = 15;
			}
		}
		return passinglanes;
	}

	/*****************
	 * Road Settings *
	 *****************/

	/**
	 * Use trucks and buses?
	 */
	static function UseRoad()		{ return AISettings.GetAISetting("use_roadvehs", true) && !AIGameSettings.GetValue("ai_disable_veh_roadveh"); }

	/**
	 * Fast road building. Enabled by default.
	 */
	static function FastRoadBuild()		{ return AISettings.GetAISetting("fast_build", true); }

	/**
	 * Use local buses? This work poorly, disabled by default.
	 */
	static function UseLocalBuses()		{ return AISettings.GetAISetting("use_localbuses", false) && AISettings.UseRoad(); }

	/**
	 * Minium distance between two local bus stations..
	 */
	static function MinLocalBusDistance()	{ return 10; }

	/**
	 * Use regional buses? Enabled by default.
	 */
	static function UseRegionalBuses()	{ return AISettings.GetAISetting("use_regionalbuses", true) && AISettings.UseRoad(); }

	/**
	 * Use trucks? Enabled by default.
	 */
	static function UseTrucks()		{ return AISettings.GetAISetting("use_trucks", true) && AISettings.UseRoad(); }

	/**
	 * Build depot in destination stations?
	 */
	static function DestRoadStationHasDepot()	{ return false; }

	/**
	 * Return the maximum and minimum number of road vehicles that a route can has.
	 */
	static function GetMaxRoadVehicles()		{ return AISettings.GetAISetting("max_roadvehs", 120); }
	static function GetMinRoadVehicles()		{ return 6; }
	static function GetStartRoadVehicles()		{ return MyMath.Min(2 + AIGameSettings.GetValue("competitor_speed"), AISettings.GetMinRoadVehicles()); }

	/**
	 * Return the number of vehicles that a 'dist' tiles long route can has.
	 */
	static function GetRoadDensity(dist)		{ return (dist / 5 + 2).tointeger(); }

	/**
	 * Get the maximum distance that a road route can be build.
	 * These numbers may be coherent with info.nut's numbers.
	 * @param counter The buildcounter, or > 99 if we want large routes from start.
	 * @return Maximum distance.
	 */
	static function GetRoadMaxDistance(counter = 99)
	{
		if (!AISettings.UseRoad()) return 0;
		local road_type = AISettings.GetAISetting("road_line_type", 4);
		local ret = 70;
		if (counter > 2) ret = 90;
		if (counter > 4) ret = 110;
		if (counter > 6) ret = 130;
		if (road_type > 0 && counter > 8) ret = 150;
		if (road_type > 1 && counter > 10) ret = 190;
		if (road_type > 2 && counter > 12) ret = 230;
		if (road_type > 3 && counter > 14) ret = 280;
		return ret;
	}
}

