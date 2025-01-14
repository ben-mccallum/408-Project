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

class SuperSimpleAI extends AIController
{
		// Building stages, needed to recover a savegame
		BS_NOTHING = 0;
		BS_BUILDING = 1;
		BS_REMOVING = 2;
		BS_ELECTRIFYING = 3;
		BS_PATHFINDING = 4;
		BS_AIRPORT_REMOVING = 5;

		// Reasons to send a vehicle to a depot
		TD_SELL = 1;
		TD_REPLACE = 2;
		TD_ATTACH_WAGONS = 3;

		pathfinder = null; // Pathfinder instance. Possibly unused?
		pendingtracks = null; // list of tracks pending to build from a saved game.
		builder = null; // Builder class instance
		manager = null; // Manager class instance
		routes = null; // The table of routes
		routes_loaded = null; // The table of routes
		routes_active = null; // The number of routes whith vehicles
		serviced = null; // Industry/town - cargo pairs already serviced
		serviced_towns = null; // Industry/town - cargo pairs already serviced
		groups = null; // The list of vehicle groups
		airports = null; // The airport of each town
		airport_to_close = null; // Airport to close, if the game was saved when we are replacing a small airport by big one
		new_airport = null; // Airport to open, if the game was saved when we are replacing a small airport by big one
		new_airport_name = null; // Name of the new_airport
		new_airport_town = null; // Name of the new_airport
		use_trains = null; // Whether using trains is allowed
		use_roadvehs = null; // Whether using road vehicles is allowed
		use_aircraft = null; // Whether using aircraft is allowed
		el_rails = null; // Use electrified rails by default?
		lastroute = null; // The date the last route was built
		loadedgame = null; // Whether the game is loaded from a savegame
		companyname_set = null; // True if the company name has already been set (only used with 3iff's naming system)
		buildingstage = null; // The current building stage
		buildcounter = null; // The counter of buid attempts
		inauguration = null; // The inauguration year of the company
		bridgesupgraded = null; // The year in which bridges were last upgraded
		removelist = null; // List used to continue rail removal and electrification
		toremove = { vehtype = null,
			 stasrc = null,
			 stadst = null,
			 crg = null,
			 trains = null,
			 stasrc = null,
			 stadst = null,
			 stapass = null,
			 homedepot = null,
			 segment = 0,
			 builddepot1 = null,
			 builddepot2 = null,
			 list = null
		}; // Table used to remove unfinished routes
		roadbridges = null; // The list of road bridges
		railbridges = null; // The list of rail bridges
		engineblacklist = null; // The blacklist of train engines
		wagonlenlist = null; // The list of wagons and their lengths
		constructor() {
			routes = [];
			routes_loaded = [];
			routes_active = 0;
			serviced = AIList();
			serviced_towns = AIList();
			groups = AIList();
			airports = AIList();
			manager = cManager(this);
			loadedgame = false;
			el_rails = false;
			lastroute = 0;
			buildingstage = BS_NOTHING;
			buildcounter = 1;
			inauguration = 0;
			bridgesupgraded = null;
			removelist = [];
			roadbridges = AITileList();
			railbridges = AITileList();
			engineblacklist = AIList();
			wagonlenlist = AIList();
			pendingtracks = AITileList();
		}
}

/**
 * Include all .nut files
 */
require("version.nut");
require("mylib/require.nut");
require("banker.nut");
require("manager.nut");
// cBuilder class is into builder.nut file, load all builder functions after builder.nut file.
require("builder.nut");
require("railbuilder.nut");
require("railbuilder-stations.nut");
require("railbuilder-passinglanes.nut");
require("vehicles.nut");
require("roadbuilder.nut");
require("roadbuilder-stations.nut");
require("airbuilder.nut");
// Settings and Log functions are loaded after cManager, cBuilder and SuperSimpleAI classes are declared.
require("settings.nut");
require("log.nut");

/**
 * The main function of the AI.
 */
function SuperSimpleAI::Start()
{
	this.CheckVehicleTypes();
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	AICompany.SetAutoRenewStatus(false);
	this.ShowConfig();
	LogWarning("SuperSimpleAI v" + SELF_VERSION + " (" + SELF_DATE + ") started.");
	if (loadedgame) {
		LogLoad("I'm " + MyAICompany.GetMyPresidentName() + "! Hello!");
		//LogLoad("My primary livery colour is " + AICompany.GetPrimaryLiveryColour(AICompany.LS_DEFAULT));
		routes = MyRoutes.SaveDataToRouteTable(routes_loaded);
		LogLoad("We have " + routes.len() + " routes and " + routes_active + " active routes.");
		this.SetRailType();
		switch (buildingstage) {
			case BS_BUILDING:
				if (!this.RestartUnfinishedPath() || !this.RestartUnfinishedRoute()) {
					// Remove unfinished route if needed
					LogLoad("Removing the unfinished route after loading...");
					this.RemoveUnfinishedRoute();
				} else buildcounter++;
				break;
			case BS_PATHFINDING:
				// Restarting unfinished routes
				if (!this.RestartUnfinishedRoute()) this.RemoveUnfinishedRoute();
				buildcounter++;
				break;
			case BS_REMOVING:
				// Continue the removal of rails
				LogLoad("Finishing the removal of the rail line.")
				removelist = toremove.list;
				builder = cBuilder(this);
				builder.RemoveRailLine(AIMap.TILE_INVALID);
				break;
			case BS_ELECTRIFYING:
				// Continue the electrification of rails
				LogLoad("Finishing the electrification of the rail line.");
				removelist = toremove.list;
				this.SetRailType();
				builder = cBuilder(this);
				builder.ElectrifyRail(AIMap.TILE_INVALID);
				break;
			case BS_AIRPORT_REMOVING:
				// Wait until there are not planes in the airport before close it
				LogLoad("Removing small and unused airport.");
				while (!AIAirport.RemoveAirport(AIStation.GetLocation(toremove.src))) {
					manager.CheckEvents();
					manager.CheckTodepotlist();
					manager.CheckRoutes();
					AIController.Sleep(50);
				}
				AIStation.SetName(toremove.dst, toremove.crg);
				LogInfo("Replaced " + AITown.GetName(toremove.extracrg) + " airport: " + toremove.crg + " -> " + AIAirport.GetAirportType(AIStation.GetLocation(toremove.dst)));
				buildcounter++;
				break;
		}
		builder = null;
		buildingstage = BS_NOTHING;
		manager.CheckEvents();
		manager.CheckRoutes();
		Banker.PayLoan();
	} else {
		inauguration = AIDate.GetYear(AIDate.GetCurrentDate());
		bridgesupgraded = AIDate.GetYear(AIDate.GetCurrentDate());
		LogLoad("No previous game found in data, I'm " + MyAICompany.GetMyPresidentName() + "! Hello!");
		//LogLoad("My primary livery colour is " + AICompany.GetPrimaryLiveryColour(AICompany.LS_DEFAULT));
	}
	// The main loop of the AI
	while(true) {
		local lastloop = AIDate.GetCurrentDate();
		if (routes.len() < AISettings.MaxRoutes() && this.HasWaitingTimePassed()) { // Do not build more than 1000 routes, it may crash on loading.
			// Check if we have enough money
			if (Banker.GetMaxBankBalance() > Banker.MinimumMoneyToBuild()) {
				if (MyAICompany.GetMyBankBalance() < Banker.MinimumMoneyToBuild()) {
					Banker.SetMinimumBankBalance(Banker.MinimumMoneyToBuild());
				}
				this.SetRailType();
				this.CheckVehicleTypes();
				builder = cBuilder(this);
				builder.BuildSomething();
				builder = null;
				buildcounter++;
				if (AIDate.GetYear(AIDate.GetCurrentDate()) > bridgesupgraded && Banker.SetMinimumBankBalance(AISettings.MiniumMoneyToUpgradeBridges())) this.UpgradeBridges();
			}
		}
		manager.MainLoop();
		if (AIDate.GetCurrentDate() - lastloop < 1) AIController.Sleep(80);
		
	}
}

/**
 * The function called when stopping the AI.
 */
function SuperSimpleAI::Stop()
{
}

/**
 * Saves the current state of the AI.
 */
function SuperSimpleAI::Save()
{
	local table = {	lastroute = lastroute,
			todepotlist = [],
			routes = routes_loaded,
			routes_active = routes_active,
			serviced = [],
			serviced_towns = [],
			groups = [],
			airports = [],
			eventqueue = null,
			buildingstage = buildingstage,
			buildcounter = buildcounter,
			inauguration = inauguration,
			bridgesupgraded = bridgesupgraded,
			roadbridges = [],
			railbridges = [],
			engineblacklist = [],
			wagonlenlist = [],
			pendingtracks = [],
			toremove = {
				vehtype = null,
				railtype = null,
				src = null,
				dst = null,
				crg = null,
				extracrg = null,
				trains = null,
				stasrc = null,
				stadst = null,
				stapass = null,
				homedepot = null,
				segment = 0,
				slopes = 0,
				builddepot1 = null,
				builddepot2 = null,
				holes = null,
				list = null
			}
	};
	table.todepotlist = MyAIList.ListToArray(manager.todepotlist);
	table.serviced = MyAIList.ListToArray(serviced);
	table.serviced_towns = MyAIList.ListToArray(serviced_towns);
	table.groups = MyAIList.ListToArray(groups);
	table.airports = MyAIList.ListToArray(airports);
	table.eventqueue = this.SaveEventQueue();
	table.roadbridges = MyAIList.ListToArray(roadbridges);
	table.railbridges = MyAIList.ListToArray(railbridges);
	table.engineblacklist = MyAIList.ListToArray(engineblacklist);
	table.wagonlenlist = MyAIList.ListToArray(wagonlenlist);
	switch (buildingstage) {
		case BS_PATHFINDING:
		case BS_BUILDING:
			if (builder != null) {
				table.toremove.vehtype = builder.vehtype;
				table.toremove.railtype = builder.railtype;
				table.toremove.src = builder.src;
				table.toremove.dst = builder.dst;
				table.toremove.crg = builder.crg;
				table.toremove.extracrg = builder.extracrg;
				table.toremove.trains = builder.trains;
				table.toremove.stasrc = builder.stasrc;
				table.toremove.stadst = builder.stadst;
				table.toremove.stapass = builder.stapass;
				table.toremove.homedepot = builder.homedepot;
				table.toremove.segment = builder.segment;
				table.toremove.slopes = builder.slopes;
				table.toremove.builddepot1 = builder.builddepot1;
				table.toremove.builddepot2 = builder.builddepot2;
				if (builder.vehtype == AIVehicle.VT_ROAD) {
					local srcsta_loc = null, dststa_loc = null;
					if (builder.stasrc != null) srcsta_loc = AIRoad.GetRoadStationFrontTile(AIStation.GetLocation(builder.stasrc));
					if (builder.stadst != null) dststa_loc = AIRoad.GetRoadStationFrontTile(AIStation.GetLocation(builder.stadst));
					table.toremove.list = [ dststa_loc, srcsta_loc];
					table.toremove.holes = builder.holes;
				}
				if (builder.vehtype == AIVehicle.VT_RAIL) {
					table.toremove.list = [
						builder.dst_entry, builder.src_entry,
						builder.ps1_entry, builder.ps1_exit,
						builder.ps2_entry, builder.ps2_exit,
						builder.ps3_entry, builder.ps3_exit,
						builder.ps4_entry, builder.ps4_exit,
						builder.ps5_entry, builder.ps5_exit,
						builder.ps6_entry, builder.ps6_exit,
						builder.ps7_entry, builder.ps7_exit,
						builder.ps8_entry, builder.ps8_exit,
						builder.ps9_entry, builder.ps9_exit,
						builder.ps10_entry, builder.ps10_exit,
						builder.ps11_entry, builder.ps11_exit,
						builder.ps12_entry, builder.ps12_exit,
						builder.ps13_entry, builder.ps13_exit,
						builder.ps14_entry, builder.ps14_exit,
						builder.ps15_entry, builder.ps15_exit,
						builder.bl1_entry, builder.bl1_exit,
						builder.bl2_entry, builder.bl2_exit,
						builder.bl3_entry, builder.bl3_exit,
						builder.bl4_entry, builder.bl4_exit,
						builder.bl5_entry, builder.bl5_exit,
						builder.bl6_entry, builder.bl6_exit,
						builder.bl7_entry, builder.bl7_exit,
						builder.bl8_entry, builder.bl8_exit,
						builder.bl9_entry, builder.bl9_exit,
						builder.bl10_entry, builder.bl10_exit,
						builder.bl11_entry, builder.bl11_exit,
						builder.bl12_entry, builder.bl12_exit,
						builder.bl13_entry, builder.bl13_exit,
						builder.bl14_entry, builder.bl14_exit,
						builder.bl15_entry, builder.bl15_exit
					];
				}
			} else {
				SuperSimpleAI.LogError("Invalid save state, probably the game is being saved right after loading");
				table.buildingstage = BS_NOTHING;
			}
			break;
		case BS_REMOVING:
		case BS_ELECTRIFYING:
			table.toremove.list = removelist;
			break;
		case BS_AIRPORT_REMOVING:
			// Reusing some items gfrom toremove table...
			table.toremove.src = airport_to_remove;
			table.toremove.dst = new_airport;
			table.toremove.crg = new_airport_name;
			table.toremove.extracrg = new_airport_town;
			break;
	}
	SuperSimpleAI.LogInfo("Game saved.");
	return table;
}

/**
 * Loads the state of the AI from a savegame.
 */
function SuperSimpleAI::Load(version, data)
{
	if ("lastroute" in data) lastroute = data.lastroute;
	else lastroute = 0;
	if ("routes" in data) routes_loaded = data.routes;
	if ("routes_active" in data) routes_active = data.routes_active;
	else routes_active = routes.len();
	if ("todepotlist" in data) manager.todepotlist.AddList(MyAIList.ArrayToList(data.todepotlist));
	if ("serviced" in data) serviced.AddList(MyAIList.ArrayToList(data.serviced));
	if ("serviced_towns" in data) serviced_towns.AddList(MyAIList.ArrayToList(data.serviced_towns));
	if ("groups" in data) groups.AddList(MyAIList.ArrayToList(data.groups));
	if ("airports" in data) airports.AddList(MyAIList.ArrayToList(data.airports));
	if ("inauguration" in data) inauguration = data.inauguration;
	if ("buildcounter" in data) buildcounter = data.buildcounter;
	else inauguration = AIGameSettings.GetValue("game_creation.starting_year");
	if ("eventqueue" in data) manager.eventqueue = data.eventqueue;
	if ("bridgesupgraded" in data) bridgesupgraded = data.bridgesupgraded;
	if ("roadbridges" in data) roadbridges.AddList(MyAIList.ArrayToList(data.roadbridges));
	if ("railbridges" in data) railbridges.AddList(MyAIList.ArrayToList(data.railbridges));
	if ("engineblacklist" in data) engineblacklist.AddList(MyAIList.ArrayToList(data.engineblacklist));
	if ("wagonlenlist" in data) wagonlenlist.AddList(MyAIList.ArrayToList(data.wagonlenlist));
	if ("pendingtracks" in data) pendingtracks.AddList(MyAIList.ArrayToList(data.pendingtracks));
	if ("buildingstage" in data) buildingstage = data.buildingstage;
	else buildingstage = BS_NOTHING;
	if (buildingstage != BS_NOTHING) {
		toremove = data.toremove;
	}
	loadedgame = true;
}

/**
 * Builds the company headquarters.
 * @param centre The town or station around which the HQ will be built.
 * @param istown Whether the HQ will be built in a town.
 * @return True if the construction succeeded.
 */
function SuperSimpleAI::BuildHQ(centre, istown)
{
	local tilelist = null;
	// Get a tile list
	if (istown) {
		tilelist = MyAITile.GetTilesAroundTown(centre, 1, 1);
	} else {
		tilelist = AITileList_IndustryProducing(centre, 6);
	}
	tilelist.Valuate(AIBase.RandItem);
	foreach (tile, dummy in tilelist) {
		if (AISettings.UseCustomCompanyName()) {
			// Using test mode here because the name of the company has to be set before the HQ is built.
			local test_mode = AITestMode();
			if (AICompany.BuildCompanyHQ(tile)) {
				test_mode = null;
				//  Call the company naming routine
				SetCo.SetCompanyName(AITile.GetClosestTown(tile));
				SuperSimpleAI.LogInfo("The company is named " + MyAICompany.GetMyName());
			}
		}
		if (AICompany.BuildCompanyHQ(tile)) {
			// This sleep is needed to ensure that the company gets its name after the HQ town
			AIController.Sleep(25);
			local name = null;
			if (istown) {
				name = AITown.GetName(centre);
			} else {
				name = AIIndustry.GetName(centre);
			}
			SuperSimpleAI.LogInfo("Built company headquarters near " + name);
			return true;
		}
	}
	return false;
}

/**
 * Sets the current rail type of the AI based on the maximum number of cargoes transportable.
 */
function SuperSimpleAI::SetRailType()
{
	local railtypes = AIRailTypeList();
	local cargoes = AICargoList();
	local max_cargoes = 0;
	railtypes.Valuate(AIRail.GetBuildCost, AIRail.BT_TRACK);
	if (el_rails && routes_active > AISettings.MinRoutesToBuildElectrifiedRail()) {
		railtypes.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	} else {
		railtypes.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	}
	// Check each rail type for the number of available cargoes
	foreach (railtype, dummy in railtypes) {
		// Avoid the universal rail in NUTS and other similar ones
		local buildcost = AIRail.GetBuildCost(railtype, AIRail.BT_TRACK);
		if (buildcost > Banker.InflatedValue(2000)) continue;
		local current_railtype = AIRail.GetCurrentRailType();
		AIRail.SetCurrentRailType(railtype);
		local num_cargoes = 0;
		// Count the number of available cargoes
		foreach (cargo, dummy2 in cargoes) {
			if (MyTrains.ChooseWagon(cargo, null) != null) num_cargoes++;
		}
		//LogInfo("Rail type " + railtype + " named " + AIRail.GetName(railtype) + " cost = " + buildcost + " cargoes = " + num_cargoes);
		if (num_cargoes >= max_cargoes) {
			max_cargoes = num_cargoes;
			current_railtype = railtype;
		}
		AIRail.SetCurrentRailType(current_railtype);
	}
}

/**
 * Checks the game settings for the particular vehicle types.
 */
function SuperSimpleAI::CheckVehicleTypes()
{
	if (AISettings.UseRoad() && !AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD))
		use_roadvehs = 1;
	else use_roadvehs = 0;
	if (AISettings.UseRail() && !AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_RAIL))
		use_trains = 1;
	else use_trains = 0;
	if (AISettings.UseAircraft() && !AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_AIR))
		use_aircraft = 1;
	else use_aircraft = 0;

	/* Checking vehicle limits */

	local vehiclelist = AIVehicleList();
	vehiclelist.Valuate(AIVehicle.GetVehicleType);
	vehiclelist.KeepValue(AIVehicle.VT_ROAD);
	if (vehiclelist.Count() + 5 > AIGameSettings.GetValue("vehicle.max_roadveh")) {
		use_roadvehs = 0;
		SuperSimpleAI.LogWarning("Limit of road vehicles reached! I can't build more road routes!");
	}

	vehiclelist = AIVehicleList();
	vehiclelist.Valuate(AIVehicle.GetVehicleType);
	vehiclelist.KeepValue(AIVehicle.VT_RAIL);
	if (vehiclelist.Count() + 1 > AIGameSettings.GetValue("vehicle.max_trains")) {
		use_trains = 0;
		SuperSimpleAI.LogWarning("Limit of trains reached! I can't build more trains routes!");
	}

	vehiclelist = AIVehicleList();
	vehiclelist.Valuate(AIVehicle.GetVehicleType);
	vehiclelist.KeepValue(AIVehicle.VT_AIR);
	if (vehiclelist.Count() + 1 > AIGameSettings.GetValue("vehicle.max_aircraft")) {
		use_aircraft = 0;
		SuperSimpleAI.LogWarning("Limit of aircraft reached! I can't build more air routes!");
	}
}

/**
 * Saves the important elements of the event queue.
 * @return The event queue converted to an array which can be saved.
 */
function SuperSimpleAI::SaveEventQueue()
{
	local array = manager.eventqueue;
	while (AIEventController.IsEventWaiting()) {
		local event = AIEventController.GetNextEvent();
		local vehicle = null;
		local isimportant = false;
		switch (event.GetEventType()) {
			case AIEvent.ET_VEHICLE_CRASHED:
				event = AIEventVehicleCrashed.Convert(event);
				vehicle = event.GetVehicleID();
				isimportant = true;
				break;

			case AIEvent.ET_VEHICLE_WAITING_IN_DEPOT:
				event = AIEventVehicleWaitingInDepot.Convert(event);
				vehicle = event.GetVehicleID();
				isimportant = true;
				break;

			case AIEvent.ET_VEHICLE_UNPROFITABLE:
				event = AIEventVehicleUnprofitable.Convert(event);
				vehicle = event.GetVehicleID();
				isimportant = true;
				break;
		}
		if (isimportant) {
			local arrayitem = [event.GetEventType(), vehicle];
			array.append(arrayitem);
		}
	}
	return array;
}

/**
 * Decides whether it is time to build a new route.
 * @return True if the waiting time has passed.
 */
function SuperSimpleAI::HasWaitingTimePassed()
{
	local date = AIDate.GetCurrentDate();
	local waitingtime = AISettings.GetWaitingTime() + (AIDate.GetYear(date) - inauguration) * AISettings.GetSlowdownEffect() * 4;
	return (MyMath.Max(date - lastroute, 1) > waitingtime);
}

/**
 * Removes the unfinished route started before saving the game.
 */
function SuperSimpleAI::RemoveUnfinishedRoute()
{
	switch (toremove.vehtype) {
		case AIVehicle.VT_ROAD:
			builder = cBuilder(this);
			builder.DeleteRoadStation(toremove.stasrc);
			builder.DeleteRoadStation(toremove.stadst);
			builder = null;
			break;
		case AIVehicle.VT_RAIL:
			builder = cBuilder(this);
			builder.DeleteRailStation(toremove.stasrc);
			builder.DeleteRailStation(toremove.stadst);
			if (toremove.stapass != null) builder.DeleteRailStation(toremove.stapass);
			builder.RemoveRailLine(toremove.list[2][1]);
			builder.RemoveRailLine(toremove.list[4][1]);
			builder.RemoveRailLine(toremove.list[6][1]);
			builder.RemoveRailLine(toremove.list[8][1]);
			builder.RemoveRailLine(toremove.list[10][1]);
			builder.RemoveRailLine(toremove.list[12][1]);
			builder.RemoveRailLine(toremove.list[14][1]);
			builder.RemoveRailLine(toremove.list[16][1]);
			builder.RemoveRailLine(toremove.list[18][1]);
			builder.RemoveRailLine(toremove.list[20][1]);
			builder.RemoveRailLine(toremove.list[22][1]);
			builder.RemoveRailLine(toremove.list[24][1]);
			builder.RemoveRailLine(toremove.list[26][1]);
			builder.RemoveRailLine(toremove.list[28][1]);
			builder.RemoveRailLine(toremove.list[30][1]);
			builder = null;
			break;
		case AIVehicle.VT_AIR:
			builder = cBuilder(this);
			builder.DeleteAirport(toremove.stasrc);
			builder.DeleteAirport(toremove.stadst);
			builder = null;
			break;
	}
}

/**
 * Restart building tracks.
 */
function SuperSimpleAI::RestartUnfinishedPath()
{
	//if (pendingtracks != null) {
	//	LogLoad("Detected pending tracks to build...");
	//	builder = cBuilder(this);
	//	if (builder.BuildTracks(pendingtracks)) {
	//		toremove.segment++;
	//		buildingstage = BS_PATHFINDING;
	//		return true;
	//	}
	//}
	return false;
}

/**
 * Restart the unfinished route started before saving the game.
 */
function SuperSimpleAI::RestartUnfinishedRoute()
{
        LogLoad("Detected unfinished " + MyAICargo.GetName(toremove.crg) + " route with " + toremove.trains + " trains from " + AIStation.GetName(toremove.stasrc) + " to " + AIStation.GetName(toremove.stadst) + ".");
	builder = cBuilder(this);
	local old_railtype = AIRail.GetCurrentRailType();
	if ("railtype" in toremove) builder.railtype = toremove.railtype; else builder.railtype = AIRail.GetCurrentRailType();
	AIRail.SetCurrentRailType(builder.railtype);
	builder.vehtype = toremove.vehtype; builder.segment = toremove.segment;
	builder.builddepot1 = toremove.builddepot1; builder.builddepot2 = toremove.builddepot2;
	builder.src = toremove.src; builder.dst = toremove.dst; builder.crg = toremove.crg; builder.trains = toremove.trains;
	if ("extracrg" in toremove) builder.extracrg = toremove.extracrg;
	if ("stapass" in toremove) builder.stapass = toremove.stapass;
	if ("slopes" in toremove) builder.slopes = toremove.slopes; else builder.slopes = 3;
	builder.stasrc = toremove.stasrc; builder.stadst = toremove.stadst; builder.homedepot = toremove.homedepot;
	builder.dst_entry = toremove.list[0]; builder.src_entry = toremove.list[1];
	builder.ps1_entry = toremove.list[2]; builder.ps1_exit = toremove.list[3];
	builder.ps2_entry = toremove.list[4]; builder.ps2_exit = toremove.list[5];
	builder.ps3_entry = toremove.list[6]; builder.ps3_exit = toremove.list[7];
	builder.ps4_entry = toremove.list[8]; builder.ps4_exit = toremove.list[9];
	builder.ps5_entry = toremove.list[10]; builder.ps5_exit = toremove.list[11];
	builder.ps6_entry = toremove.list[12]; builder.ps6_exit = toremove.list[13];
	builder.ps7_entry = toremove.list[14]; builder.ps7_exit = toremove.list[15];
	builder.ps8_entry = toremove.list[16]; builder.ps8_exit = toremove.list[17];
	builder.ps9_entry = toremove.list[18]; builder.ps9_exit = toremove.list[19];
	builder.ps10_entry = toremove.list[20]; builder.ps10_exit = toremove.list[21];
	builder.ps11_entry = toremove.list[22]; builder.ps11_exit = toremove.list[23];
	builder.ps12_entry = toremove.list[24]; builder.ps12_exit = toremove.list[25];
	builder.ps13_entry = toremove.list[26]; builder.ps13_exit = toremove.list[27];
	builder.ps14_entry = toremove.list[28]; builder.ps14_exit = toremove.list[29];
	builder.ps15_entry = toremove.list[30]; builder.ps15_exit = toremove.list[31];
	builder.bl1_entry = toremove.list[32]; builder.bl1_exit = toremove.list[33];
	builder.bl2_entry = toremove.list[34]; builder.bl2_exit = toremove.list[35];
	builder.bl3_entry = toremove.list[36]; builder.bl3_exit = toremove.list[37];
	builder.bl4_entry = toremove.list[38]; builder.bl4_exit = toremove.list[39];
	builder.bl5_entry = toremove.list[40]; builder.bl5_exit = toremove.list[41];
	builder.bl6_entry = toremove.list[42]; builder.bl6_exit = toremove.list[43];
	builder.bl7_entry = toremove.list[44]; builder.bl7_exit = toremove.list[45];
	builder.bl8_entry = toremove.list[46]; builder.bl8_exit = toremove.list[47];
	builder.bl9_entry = toremove.list[48]; builder.bl9_exit = toremove.list[49];
	builder.bl10_entry = toremove.list[50]; builder.bl10_exit = toremove.list[51];
	builder.bl11_entry = toremove.list[52]; builder.bl11_exit = toremove.list[53];
	builder.bl12_entry = toremove.list[54]; builder.bl12_exit = toremove.list[55];
	builder.bl13_entry = toremove.list[56]; builder.bl13_exit = toremove.list[57];
	builder.bl14_entry = toremove.list[58]; builder.bl14_exit = toremove.list[59];
	builder.bl15_entry = toremove.list[60]; builder.bl15_exit = toremove.list[61];
	builder.srcplace = AIIndustry.GetLocation(builder.src);
	builder.dstplace = AIIndustry.GetLocation(builder.dst);
	local platform = cBuilder.GetRailRoutePlatformLength(builder.stasrc, builder.stadst);
	local dist = AIMap.DistanceManhattan(AIBaseStation.GetLocation(builder.stasrc), AIBaseStation.GetLocation(builder.stadst));
	builder.LogDebug("The distance between two stations is " + dist + ", the platform length is " + platform);
        // Determine how many passing lanes has the unfinished route
        local passinglanes = 0;
        local counter = 2;
        while (counter < 32) {
                if (toremove.list[counter][1] != null) {
			passinglanes++;
		}
                counter++;
        }
        LogLoad("Detected " + ( passinglanes / 2 ) + " passing lanes and " + builder.segment + " rail segments built.");
	// Choose wagon and locomotive (preventive)
        local success = true;
	local wagon = MyTrains.ChooseWagon(builder.crg, engineblacklist);
	if (wagon == null) {
		builder.LogWarning("No suitable wagon available!");
		success = false;
	}
	local engine = MyTrains.ChooseTrainEngine(builder.crg, dist, wagon, platform * 2 - 1, engineblacklist);
	if (success && engine == null) {
		builder.LogWarning("No suitable engine available!");
		success = false;
	}
	local extra_wagon = null;
	if (success && builder.extracrg != null) {
		extra_wagon = MyTrains.ChooseWagon(builder.extracrg, engineblacklist);
		if (extra_wagon == null) {
			builder.LogWarning("No suitable wagon available!");
			success = false;
		}
	}
	if (success) {
		LogLoad("Restarting unfinished route before build new ones.");
		if (builder.segment == 0) {
			builder.recursiondepth = 0;
			if (builder.BuildRail(toremove.list[passinglanes + 1], builder.dst_entry, toremove.list[passinglanes + 31],[null,null])) builder.LogInfo("Rail 1 of " + ( passinglanes / 2 + 1 ) + " built successfully!");
			else success = false;
			builder.segment++;
			success = success && builder.AreIndustriesAlive();
		}
	}
        counter = 1;
	while (success && counter < (passinglanes / 2 + 1)) {
		if (counter > builder.segment - 1) {
			builder.recursiondepth = 0;
     	  		if (builder.BuildRail(toremove.list[counter*2 - 1], toremove.list[counter*2], toremove.list[counter*2 + 29], toremove.list[counter*2 + 30])) builder.LogInfo("Rail " + ( counter + 1 ) + " of " + ( passinglanes / 2 + 1 ) + " built successfully!");
			else success = false;
			builder.segment++;
			success = success && builder.AreIndustriesAlive();
		}
		counter++;
	}

	success = success && builder.AreIndustriesAlive();
	if (success) {
		local new_train = false;
		if (builder.stapass != null) builder.extra_dst = true;
		// Choose (again) wagon and locomotive
		wagon = MyTrains.ChooseWagon(builder.crg, engineblacklist);
		if (wagon == null) {
			builder.LogWarning("No suitable wagon available!");
			AIRail.SetCurrentRailType(old_railtype);
			return false;
		} else builder.LogInfo("Chosen wagon: " + AIEngine.GetName(wagon));
		local prod1_percent = 50;
		local wagonminspeed = wagon;
		local wagoncrg = builder.crg;
		local extra_wagon = (builder.extracrg == null) ? null : MyTrains.ChooseWagon(builder.extracrg, engineblacklist);
		if (builder.extracrg != null) {
			if (extra_wagon != null) {
				builder.LogInfo("Chosen wagon: " + AIEngine.GetName(extra_wagon));
				if (AIEngine.GetMaxSpeed(wagon) > AIEngine.GetMaxSpeed(extra_wagon)) {
					wagonminspeed = extra_wagon;
					wagoncrg = builder.extracrg;
				}
				prod1_percent = MyAIIndustry.GetProductionPercentage(builder.src, builder.crg, builder.extracrg);
			} else {
				builder.LogWarning("No suitable wagon available!");
				AIRail.SetCurrentRailType(old_railtype);
				return false;
			}
		}
		engine = MyTrains.ChooseTrainEngine(wagoncrg, dist, wagonminspeed, platform * 2 - 1, engineblacklist);
		if (engine == null) {
			builder.LogWarning("No suitable engine available!");
			AIRail.SetCurrentRailType(old_railtype);
			return false;
		} else builder.LogInfo("Chosen engine: " + AIEngine.GetName(engine));
		builder.group = AIGroup.CreateGroup(AIVehicle.VT_RAIL);
		// This is necesary for loaded games, if are waiting for money after build a route.
		buildingstage = BS_PATHFINDING;
		if (builder.BuildAndStartTrains(builder.trains, 2 * platform - 2, engine, wagon, extra_wagon, null, true, prod1_percent)) new_train = 1;
		// Retry if route was abandoned due to blacklisting
		local vehicles = AIVehicleList_Group(builder.group);
		local maxloop = AISettings.EngineBlackListLoop();
		local maxroutespeed = 500;
		while (maxloop > 0 && vehicles.Count() == 0) {
			builder.LogInfo("The new route may be empty because of blacklisting, retrying...")
			// Choose wagon and locomotive
			wagon = MyTrains.ChooseWagon(builder.crg, engineblacklist);
			if (wagon == null) {
				builder.LogWarning("No suitable wagon available!");
				maxloop = 1;
			} else {
				maxroutespeed = MyMath.Min(maxroutespeed, AIEngine.GetMaxSpeed(wagon));
				builder.LogInfo("Chosen wagon: " + AIEngine.GetName(wagon));
				wagonminspeed = wagon;
				wagoncrg = builder.crg;
				extra_wagon = (builder.extracrg == null) ? null : MyTrains.ChooseWagon(builder.extracrg, engineblacklist);
				if (builder.extracrg != null) {
					if (extra_wagon!= null) {
						maxroutespeed = MyMath.Min(maxroutespeed, AIEngine.GetMaxSpeed(extra_wagon));
						builder.LogInfo("Chosen wagon: " + AIEngine.GetName(extra_wagon));
						if (AIEngine.GetMaxSpeed(wagon) > AIEngine.GetMaxSpeed(extra_wagon)) {
							wagonminspeed = extra_wagon;
							wagoncrg = builder.extracrg;
						}
					} else {
						builder.LogWarning("No suitable wagon available!");
						maxloop = 1;
					}
				} else extra_wagon = null;
				engine = MyTrains.ChooseTrainEngine(wagoncrg, dist, wagonminspeed, platform * 2 - 1, engineblacklist);
				if (engine == null) {
					builder.LogWarning("No suitable engine available!");
					maxloop = 1;
				} else {
					maxroutespeed = MyMath.Min(maxroutespeed, AIEngine.GetMaxSpeed(engine));
					builder.LogInfo("Chosen engine: " + AIEngine.GetName(engine));
					if (builder.BuildAndStartTrains(builder.trains, 2 * platform - 2, engine, wagon, extra_wagon, null, true, prod1_percent)) new_train = 1;
				}
			}
			vehicles = AIVehicleList_Group(builder.group);
			maxloop--;
		}
		// Register if fail because it will be removed.
		builder.RegisterRoute(maxroutespeed);
		cBuilder.SetStationName(builder.stasrc, "SRC", routes.len());
		cBuilder.SetStationName(builder.stadst, "DST", routes.len());
		if (builder.stapass != null) cBuilder.SetStationName(builder.stapass, "PAS", routes.len());
		builder.SetGroupName(builder.group, builder.crg, builder.stasrc);
		if (new_train) builder.LogInfo("Added train 1 to route: " + AIGroup.GetName(builder.group));
		routes_active++;
		buildingstage = BS_NOTHING;
		builder.LogWarning("New route " + routes.len() + " done!");
	}
	AIRail.SetCurrentRailType(old_railtype);
	return success;
}

/**
 * Upgrades existing bridges.
 */
function SuperSimpleAI::UpgradeBridges()
{
	LogDebug("Upgrade bridges: Last upgrade was on " + bridgesupgraded + ", now is " + AIDate.GetYear(AIDate.GetCurrentDate()));
	local upgrade = false;
	local railtype = AIRail.GetCurrentRailType();
	builder = cBuilder(this);
	upgrade = builder.UpgradeRailBridges();
	AIRail.SetCurrentRailType(railtype);
	upgrade = builder.UpgradeRoadBridges() || upgrade;
	builder = null;
	bridgesupgraded = AIDate.GetYear(AIDate.GetCurrentDate());
	if (upgrade) buildcounter++;
}

/**
 * Show configuration and settings.
 */
function SuperSimpleAI::ShowConfig()
{
	LogWarning("Loading SuperSimpleAI v" + SELF_VERSION + " configuration info.nut v" + SELF_INFO_VERSION + " with OpenTTD v" + MyAIController.GetVersionString() + "...");
	LogConfig("Using " + MyAIGameSettings.GetSettingsProfileName() + " profile from Game Configuration -> Competitors.");
	LogConfig("The minium cash needed to build new routes is " + Banker.MinimumMoneyToBuild() + ".");
	if (use_aircraft == 1) LogConfig("Using " + AISettings.GetAirStyleName() + " style aircraft model for routes up to " + AISettings.GetAirMaxDistance() + " tiles long.");
	if (use_roadvehs == 1) LogConfig("Using road vehicles for routes up to " + AISettings.GetRoadMaxDistance() + " tiles long and " + AISettings.GetMaxRoadVehicles() + " maximum road vehicles per route.");
	if (use_trains == 1) {
		if (AIGameSettings.GetValue("difficulty.vehicle_breakdowns") == 1) LogWarning("This AI don't like breakdowns, please change your game settings!");
		if (AISettings.GetCargoTrainMaxLength() < AISettings.GetCargoTrainMinLength()) LogError("Wrong AI configuration: min_train_length is greater than max_train_length!");
		if (AISettings.GetCargoTrainMaxLength() > AIGameSettings.GetValue("vehicle.max_train_length")) LogWarning("Game settings don't allow trains longer than " + AIGameSettings.GetValue("vehicle.max_train_length") + " tiles!");
		if (AISettings.GetCargoTrainMaxLength() > AIGameSettings.GetValue("station.station_spread")) LogWarning("Game settings don't allow stations longer than " + AIGameSettings.GetValue("station.station_spread") + " tiles!");
		LogConfig("Using trains from " + AISettings.GetCargoTrainMinLength() + " to " + MyMath.Min(MyAIGameSettings.EfectiveMaxTrainLength(), AISettings.GetCargoTrainMaxLength()) + " tiles for cargo routes up to " + AISettings.GetCargoRailMaxDistance() + " tiles long.");
		if (AISettings.UsePassTrains()) LogConfig("Using trains from " + AISettings.GetPassTrainMinLength() + " to " + AISettings.GetPassTrainMaxLength() + " tiles for passenger routes up to " + AISettings.GetPassRailMaxDistance() + " tiles long.");
	}
	if (AISettings.BuildHQInTown()) LogConfig("Build my headquarter near a town.");
	else LogConfig("Build my headquarter near an industry.");
	if (AISettings.CanBuildStatue()) LogConfig("Build statue of me if I have money.");
	LogConfig("Build new routes if transported percentage is smaller than " + AISettings.GetMaxTransported() + "%.");
}

/**
 * Can print to log?
 * @return True if it is allowed.
 */
function SuperSimpleAI::PrintLog()
{
	return AISettings.GetAISetting("SuperSimpleAI_log", true);
}

/**
 * We are debugging something?
 * @return True to execute ebugging routines.
 */
function SuperSimpleAI::Debug()
{
	return (SuperSimpleAI.PrintLog()) ? AISettings.GetAISetting("SuperSimpleAI_log_debug", false) : false;
}

