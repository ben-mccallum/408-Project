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

/**
 * Determines whether to use aircraft or not. This is done before selecting a route.
 * @return True if aircraft will be used.
 */
function cBuilder::GetAirIntensity() { return (AISettings.IsAgressiveStyleAircraft()) ? AISettings.GetAgressiveAirIntensity() : ((AISettings.IsMediumStyleAircraft()) ? AISettings.GetMediumAirIntensity() : AISettings.GetModerateAirIntensity()); }
function cBuilder::UseAircraft()
{
	if (!root.use_aircraft || (!AISettings.IsAgressiveStyleAircraft() && root.buildcounter < 10)) return false;
	if (Banker.MinimumMoneyToUseAircraft() > Banker.GetMaxBankBalance()) return false;
	if (!root.use_trains && !root.use_roadvehs) return true;
	local chance = cBuilder.GetAirIntensity();
	if (!root.use_trains || !root.use_roadvehs) chance *= 2;
	return (AIBase.Chance(chance, 100));
}

/**
 * Builds an airport around the source or the destination town.
 * Builder class variables used: src, dst
 * Builder class variablse set: stasrc, stadst
 * The airport built is registered in the airports list.
 * @param is_source True if the source airport is to be built.
 * @return True if the airport was built.
 */
function cBuilder::BuildAirport(is_source)
{
	local tilelist = null;
	// Decide which airport type to use
	local airporttype = cBuilder.WhichAirportCanUse();
	// Get the tile list
	if (is_source) tilelist = MyAITile.GetTilesAroundTown(src, AIAirport.GetAirportWidth(airporttype), AIAirport.GetAirportHeight(airporttype));
	else tilelist = MyAITile.GetTilesAroundTown(dst, AIAirport.GetAirportWidth(airporttype), AIAirport.GetAirportHeight(airporttype));
	//local tilelist2 = tilelist;
	tilelist.Valuate(AITile.IsBuildableRectangle, AIAirport.GetAirportWidth(AIAirport.AT_SMALL), AIAirport.GetAirportHeight(AIAirport.AT_SMALL));
	tilelist.KeepValue(1);
	foreach (tile, dummy in tilelist) tilelist.SetValue(tile, cBuilder.WhichAirportCanBeBuilt(tile));
	tilelist.RemoveValue(AIAirport.AT_INVALID);
	if (tilelist.Count() == 0) return false;
	// Try to build the largest airport possible
	airporttype = cBuilder.GetLargestAirport(tilelist);
	tilelist.KeepValue(airporttype);
	tilelist.Valuate(AITile.GetCargoAcceptance, crg, AIAirport.GetAirportWidth(airporttype), AIAirport.GetAirportHeight(airporttype), AIAirport.GetAirportCoverageRadius(airporttype));
	tilelist.Sort(AIList.SORT_BY_VALUE, false);
	foreach (tile, dummy in tilelist) {
		// try to build the airport
		if (cBuilder.BuildAirportWithLandscaping(tile, airporttype, AIStation.STATION_NEW)) {
			if (is_source) {
				stasrc = AIStation.GetStationID(tile);
				root.airports.AddItem(src, stasrc);
				homedepot = AIAirport.GetHangarOfAirport(tile);
			} else {
				stadst = AIStation.GetStationID(tile);
				root.airports.AddItem(dst, stadst);
			}
			return true;
		}
	}
	LogDebug("Airport could not be built: " + AIError.GetLastErrorString());
	return false;
}

/**
 * Get the largest airport type which can be built.
 * @return The largest airport type, AIAirport.AT_INVALID if none can be built.
 */
function cBuilder::WhichAirportCanUse()
{
	local airports = cBuilder.GetAirports();
	for (local x = 0; x < airports.len(); x++) if (AIAirport.IsValidAirportType(airports[x])) return airports[x];
	return AIAirport.AT_INVALID;
}

/**
 * Get the largest airport type which can be built at a given tile.
 * @param tile The tile to be examined.
 * @return The largest airport type, AIAirport.AT_INVALID if none can be built.
 */
function cBuilder::WhichAirportCanBeBuilt(tile)
{
	local testmode = AITestMode();
	local airports = cBuilder.GetAirports();
	for (local x = 0; x < airports.len(); x++) {
		if (AIAirport.BuildAirport(tile, airports[x], AIStation.STATION_NEW)) return airports[x];
		else if (AIError.GetLastError() == AIError.ERR_FLAT_LAND_REQUIRED) {
			if (!AIAirport.IsValidAirportType(airports[x])) continue;
			if (!MyAIAirport.IsWithinNoiseLimit(tile, airports[x])) continue;
			local width = AIAirport.GetAirportWidth(airports[x]);
			local height = AIAirport.GetAirportHeight(airports[x]);
			local cost = MyAIMap.CostToFlattern(tile, width, height);
			if (cost >= 0 && cost < Banker.InflatedValue(50000)) return airports[x];
		}
	}
	return AIAirport.AT_INVALID;
}

/**
 * Get the largest airport which can be built in a given area.
 * @param tilelist The tiles to be examined.
 * @return The largest airport type, AIAirport.AT_INVALID if none can be built.
 */
function cBuilder::GetLargestAirport(tilelist)
{
	local airports = cBuilder.GetAirports();
	for (local x = 0; x < airports.len(); x++) {
		if (AIAirport.IsValidAirportType(airports[x])) {
			local tilelist2 = AIList();
			tilelist2.AddList(tilelist);
			tilelist2.KeepValue(airports[x]);
			if (tilelist2.Count() > 0) return airports[x];
		}
	}
	return AIAirport.AT_INVALID;
}

/**
 * Demolishes a given airport if no vehicles are using it.
 */
function cBuilder::DeleteAirport(sta)
{
	if (sta == null || !AIStation.IsValidStation(sta)) return;
	local vehiclelist = AIVehicleList_Station(sta);
	if (vehiclelist.Count() > 0) return;
	local tile = AIStation.GetLocation(sta);
	if (AIAirport.RemoveAirport(tile)) root.airports.RemoveValue(sta);
}

/**
 * Builds an airport at a given tile. The function uses landscaping if needed.
 * @param tile The tile where the airport will be built.
 * @param tpye The type of the airport.
 * @param station_id The StationID which will be used.
 * @return True if the construction succeeded.
 */
function cBuilder::BuildAirportWithLandscaping(tile, type, station_id)
{
	if (AIAirport.BuildAirport(tile, type, station_id)) return true;
	if (AIError.GetLastError() == AIError.ERR_FLAT_LAND_REQUIRED) {
		local width = AIAirport.GetAirportWidth(type);
		local height = AIAirport.GetAirportHeight(type);
		//local account = AIAccounting();
		local result = Terraform.Terraform(tile, width, height, -1);
		//if (account.GetCosts() > 0) LogDebug("Terraforming cost was " + account.GetCosts());
		return (result && AIAirport.BuildAirport(tile, type, station_id));
	}
	return false;
}

/**
 * Get the aircraft-based order distance of a town to a tile.
 * @param town The townID of the town.
 * @param tile The tile to which the distance is measured.
 * @return The order distance.
 */
function cBuilder::GetTownAircraftOrderDistanceToTile(town, tile)	return AIOrder.GetOrderDistance(AIVehicle.VT_AIR, AITown.GetLocation(town), tile);

/**
 * Get list of airport types.
 * @return a list of airports.
 */
function cBuilder::GetAirports()
{
	if (AISettings.IsOldStyleAircraft()) return AISettings.GetOldStyleAirports();
	if (AISettings.IsModerateStyleAircraft()) return AISettings.GetModerateStyleAirports();
	if (AISettings.IsMediumStyleAircraft()) return AISettings.GetMediumStyleAirports();
	if (AISettings.IsAgressiveStyleAircraft()) return AISettings.GetAgressiveStyleAirports();
}

/**
 * Check the airport capacity.
 * @return True if the airport has capacity.
 */
function cBuilder::CheckAirportCapacity(town)
{
	local airport = root.airports.GetValue(town);
	local airporttype = AIAirport.GetAirportType(AIStation.GetLocation(airport));
	return ((2 * AISettings.GetAirportTypeCapacity(airporttype) - AIVehicleList_Station(airport).Count()) < 2) ? false : true;
}

/**
 * Build new air route between two existing airports.
 */
function cBuilder::BuildAirRouteWithExistingAirports()
{
	// Creating other air route with existing airports
	local srclist2 = AITownList();
	srclist2.Valuate(AIBase.RandItem);
	foreach (isrc, dummy2 in srclist2) {
		if (!root.airports.HasItem(isrc)) continue;
		if (!CheckAirportCapacity(isrc)) continue;
		srcplace = AITown.GetLocation(isrc);
		dstlist = AITownList();
		dstlist.Valuate(AITown.GetDistanceManhattanToTile, srcplace);
		local max_distance = AISettings.GetAirMaxDistance();
		// Get the maximum range of airplanes
		local max_range = MyAIEngine.GetMaximumAircraftRange();
		if (max_range > 0) {
			// maximum range is 0 if range is not supported by the plane set
			dstlist.Valuate(cBuilder.GetTownAircraftOrderDistanceToTile, srcplace);
			if (max_distance > (max_range * 0.82).tointeger()) max_distance = (max_range * 0.82).tointeger();
		}
		dstlist.KeepBelowValue(max_distance);
		dstlist.KeepAboveValue(AISettings.GetAirMinDistance());
		dstlist.Valuate(AIBase.RandItem);
		foreach (idst, dummy3 in dstlist) {
			if (!root.airports.HasItem(idst)) continue;
			if (!CheckAirportCapacity(idst)) continue;
			if (AreTownsServiced(isrc, idst)) continue;
			dstplace = AITown.GetLocation(idst);
			src = isrc;
			dst = idst;
			LogWarning("Trying to build new service with existing airports:");
			stasrc = root.airports.GetValue(src);
			LogInfo(AICargo.GetCargoLabel(crg) + " from " + AITown.GetName(src) + " to " + AITown.GetName(dst));
			homedepot = AIAirport.GetHangarOfAirport(AIStation.GetLocation(stasrc));
			LogInfo("Using existing airport at " + AITown.GetName(src) + ": " + AIStation.GetName(stasrc));
			stadst = root.airports.GetValue(dst);
			LogInfo("Using existing airport at " + AITown.GetName(dst) + ": " + AIStation.GetName(stadst));
			// Depending on the type of the airports, choose a plane
			local is_small = MyAIAirport.IsSmallAirport(AIAirport.GetAirportType(AIStation.GetLocation(stasrc))) || MyAIAirport.IsSmallAirport(AIAirport.GetAirportType(AIStation.GetLocation(stadst)));
			local planetype = MyPlanes.ChoosePlane(crg, is_small, AIOrder.GetOrderDistance(AIVehicle.VT_AIR, srcplace, dstplace), false);
			if (planetype == null) {
				LogWarning("No suitable plane available!");
				root.buildingstage = root.BS_NOTHING;
				return true;
			}
			LogInfo("Selected aircraft: " + AIEngine.GetName(planetype));
			LogDebug("Distance: " + AIOrder.GetOrderDistance(AIVehicle.VT_AIR, srcplace, dstplace) + " Range: " + AIEngine.GetMaximumOrderDistance(planetype));
			group = AIGroup.CreateGroup(AIVehicle.VT_AIR);
			cBuilder.SetGroupName(group, crg, stasrc);
			if (!cBuilder.BuildAndStartVehicles(planetype, 1, null)) return false;
			LogInfo("Added plane 1 to route: " + AIStation.GetName(stasrc) + " - " + AIStation.GetName(stadst));
			local new_route = cBuilder.RegisterRoute();
			root.routes_active++;
			LogWarning("New route " + root.routes.len() + " done!");
			return true;
		}
	}
	return false;
}

/**
 * Changes destination town/airport to one existing airport.
 * @param srctown Source town.
 * @return True if success.
 */
function cBuilder::GetExistingAirport(srctown)
{
	local srcplace = AITown.GetLocation(srctown);
	local dstlist = AITownList();
	dstlist.Valuate(AITown.GetDistanceManhattanToTile, srcplace);
	local max_distance = AISettings.GetAirMaxDistance();
	// Get the maximum range of airplanes
	local max_range = MyAIEngine.GetMaximumAircraftRange();
	if (max_range > 0) {
		// maximum range is 0 if range is not supported by the plane set
		dstlist.Valuate(cBuilder.GetTownAircraftOrderDistanceToTile, srcplace);
		if (max_distance > (max_range * 0.82).tointeger()) max_distance = (max_range * 0.82).tointeger();
	}
	dstlist.KeepBelowValue(max_distance);
	dstlist.KeepAboveValue(AISettings.GetAirMinDistance());
	dstlist.Valuate(AIBase.RandItem);
	foreach (idst, dummy3 in dstlist) {
		if (!root.airports.HasItem(idst)) continue;
		if (!CheckAirportCapacity(idst)) continue;
		dst = idst;
		return true;
	}
	return false;
}

/**
 * Check if an existing airport of a town is small or have capacity, and if not tries to replace this airport.
 * @param town The town near the airport.
 * @param icrg The cargo if new route to build.
 * @param veh Type of vehicle.
 * @param is_source If source or destination airport.
 * @return True if old or new airport have capacity.
 */
function cBuilder::CheckExistingAirportCapacity(town, icrg, veh, is_source)
{
	if (veh == AIVehicle.VT_AIR && root.airports.HasItem(town) && (!cBuilder.CheckAirportCapacity(town) || MyAIAirport.IsSmallAirport(AIAirport.GetAirportType(AIStation.GetLocation(root.airports.GetValue(town)))))) {
		local origairport = root.airports.GetValue(town);
		local origtype = AIAirport.GetAirportType(AIStation.GetLocation(origairport));
		local name = AIStation.GetName(origairport);
		local has_capacity = cBuilder.CheckAirportCapacity(town);
		if (!cBuilder.AirportMustBeReplaced(origtype)) return has_capacity;
		local newairport = null;
		if (is_source) src = town;
		else dst = town;
		crg = icrg;
		if (cBuilder.BuildAirport(is_source)) {
			if (!AIStation.IsAirportClosed(origairport)) AIStation.OpenCloseAirport(origairport);
			LogWarning("Airport " + name + " near " + AITown.GetName(town) + " is too small, trying to replace it...");
			if (is_source) newairport = stasrc;
			else newairport = stadst;
			if (!cBuilder.AirportMustBeReplacedBy(origtype, AIAirport.GetAirportType(AIStation.GetLocation(newairport)))) {
				LogInfo("Wrong new airport type " + AIAirport.GetAirportType(AIStation.GetLocation(newairport)));
				AIAirport.RemoveAirport(AIStation.GetLocation(newairport));
				return has_capacity;
			}
			local vehiclelist = AIVehicleList_Station(origairport);
			foreach (aircraft, dummy in vehiclelist) {
				if (AIMap.DistanceManhattan(AIStation.GetLocation(origairport), AIOrder.GetOrderDestination(aircraft, 0)) == 0) {
					AIOrder.InsertOrder(aircraft, 1, AIStation.GetLocation(newairport), AIOrder.OF_NONE);
					AIOrder.RemoveOrder(aircraft, 0);
				}
				if (AIMap.DistanceManhattan(AIStation.GetLocation(origairport), AIOrder.GetOrderDestination(aircraft, 1)) == 0) {
					AIOrder.AppendOrder(aircraft, AIStation.GetLocation(newairport), AIOrder.OF_NONE);
					AIOrder.RemoveOrder(aircraft, 1);
				}
				cManager.LogInfo("Changing orders to " + AIVehicle.GetName(aircraft));
			}
			cBuilder.ReplaceRouteAirport(origairport, newairport);
			root.airports.RemoveItem(town);
			root.airports.AddItem(town, newairport);
			AIStation.SetName(origairport, MyAICompany.GetMyName() + " Closed_" + root.buildcounter);
			root.airport_to_close = origairport;
			root.new_airport = newairport;
			root.new_airport_name = name;
			root.new_airport_town = town;
			root.buildingstage = root.BS_AIRPORT_REMOVING;
			while (!AIAirport.RemoveAirport(AIStation.GetLocation(origairport))) {
				root.manager.CheckEvents();
				root.manager.CheckTodepotlist();
				root.manager.CheckRoutes();
				AIController.Sleep(50);
			}
			AIStation.SetName(newairport, name);
			LogInfo("Upgrading " + AITown.GetName(town) + " airport: " + name + " -> " + AIAirport.GetAirportType(AIStation.GetLocation(newairport)));
			root.buildcounter++;
			return cBuilder.CheckAirportCapacity(town);
		}
		return has_capacity;
	}
	return true;
}

/**
 * Check if an airport must be replaced.
 * @param type Old airport type.
 * @param newairport New airport type.
 * @return True if bigger airport is available.
 */
function cBuilder::AirportMustBeReplaced(airtype)	{ return cBuilder.AirportMustBeReplacedBy(airtype, cBuilder.WhichAirportCanUse()); }
function cBuilder::AirportMustBeReplacedBy(airtype, newairport)
{
	if (!AISettings.ReplaceOldAirports()) return false;
	if (newairport == AIAirport.AT_INVALID) return false;
	if (airtype == newairport) return false;
	if (airtype == AIAirport.AT_SMALL) return true;
	if (newairport == AIAirport.AT_INTERCON) return true;
	if (newairport != AIAirport.AT_SMALL && airtype == AIAirport.AT_COMMUTER) return true;
	if (newairport != AIAirport.AT_SMALL && newairport != AIAirport.AT_COMMUTER && newairport != AIAirport.AT_METROPOLITAN && airtype == AIAirport.AT_LARGE) return true;
	if (newairport != AIAirport.AT_SMALL && newairport != AIAirport.AT_COMMUTER && newairport != AIAirport.AT_LARGE && airtype == AIAirport.AT_METROPOLITAN) return true;
	return false;
}

/**
 * Changes old airport to new airport in all routes, if source or destination are the old airport.
 * @param old Old airport ID.
 * @param new New airport ID.
 */
function cBuilder::ReplaceRouteAirport(old, new)
{
	local routecount = 1;
	foreach (idx, route in root.routes) {
		if (route.vehtype == AIVehicle.VT_AIR) {
			if (route.stasrc == old) {
				LogDebug("Found route " + routecount + " with source airport to be replaced");
				route.homedepot = AIAirport.GetHangarOfAirport(AIStation.GetLocation(new));
				route.stasrc = new;
			}
			if (route.stadst == old) {
				LogDebug("Found route " + routecount + " with destination airport to be replaced");
				route.stadst = new;
			}
		}
		routecount++;
	}
}

/**
 * The new name of the airport.
 * @param station_id The basestation to set the name of.
 * @param The new name.
 * @return True if success.
 */
function cBuilder::SetAirportName(station_id)	{
        if (!AISettings.RenameAirports()) return false;
	return MyStation.SetName(station_id, "AIR", root.airports.Count());
}

/**
 * Return the number of airplanes that a route can has, depending of the distance.
 * @param dist The distance between source and destination.
 * @return Number of planes (1..5).
 */
function cBuilder::GetMaxAirplanes(dist)
{
	local max_airplanes = 1;
	local max_per_route = AISettings.MaxAircraftPerRoute();
	if (dist > 300 && max_per_route > 4) max_airplanes++;
	if (dist > 600 && max_per_route > 2) max_airplanes++;
	if (dist > 900 && max_per_route > 3) max_airplanes++;
	if (dist > 1200 && max_per_route > 1) max_airplanes++;
	return max_airplanes;
}
