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
 * Build a road station at a town or an industry.
 * Builder class variables used: crg, src, dst, srcistown, dstistown, srcplace, dstplace,
 *   statile, deptile, stafront, depfront
 * Builder class variables set: stasrc, stadst, homedepot
 * @param is_source True if we're building the source station.
 * @param is_double True if this station is double.
 * @return True if the construction succeeded.
 */
function cBuilder::BuildSingleRoadStation(is_source)	{ return BuildOrCheckRoadStation(is_source, false, true); }
function cBuilder::CheckSingleRoadStation(is_source)	{ return BuildOrCheckRoadStation(is_source, true, true); }
function cBuilder::BuildRoadStation(is_source, is_double)	{ return BuildOrCheckRoadStation(is_source, false, is_double); }
function cBuilder::CheckRoadStation(is_source, is_double)	{ return BuildOrCheckRoadStation(is_source, true, is_double); }
function cBuilder::BuildOrCheckRoadStation(is_source, check_build, is_double)
{
	local hasdepot = is_source || AISettings.DestRoadStationHasDepot();
	local localbus = MyAICargo.IsPassengersCargo(crg) && (srcplace == dstplace); 
	local dir, tilelist, thisplace, otherplace, isneartown = null;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP);
	// Determine the possible list of tiles
	if (is_source) {
		dir = MyAIMap.GetDirection(srcplace, dstplace);
		if (srcistown) {
			tilelist = MyAITile.GetTilesAroundTown(src, 1, 1);
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryProducing(src, rad);
			isneartown = false;
		}
		otherplace = dstplace;
		thisplace = srcplace;
	} else {
		dir = MyAIMap.GetDirection(dstplace, srcplace);
		if (dstistown) {
			tilelist = MyAITile.GetTilesAroundTown(dst, 1, 1);
			if (!check_build && localbus) {
				tilelist.Valuate(AIMap.DistanceManhattan, AIStation.GetLocation(stasrc));
				tilelist.RemoveBelowValue(12);
			}
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryAccepting(dst, rad);
			tilelist.Valuate(AITile.GetCargoAcceptance, crg, 1, 1, rad);
			tilelist.RemoveBelowValue(8);
			isneartown = false;
		}
		otherplace = srcplace;
		thisplace = dstplace;
	}
	// Decide whether to use a bus or a lorry station
	local stationtype = null;
	if (MyAICargo.IsPassengersCargo(crg)) stationtype = AIRoad.ROADVEHTYPE_BUS;
	else stationtype = AIRoad.ROADVEHTYPE_TRUCK;
	// Filter the tile list
	tilelist.Valuate(AITile.IsBuildable);
	tilelist.KeepValue(1);
	if (isneartown) {
		tilelist.Valuate(AITile.GetCargoAcceptance, crg, 1, 1, rad);
		tilelist.KeepAboveValue(10);
	} else {
		if (AISettings.IsClosestStation()) tilelist.Valuate(AIMap.DistanceManhattan, thisplace);
		else tilelist.Valuate(AIMap.DistanceManhattan, otherplace);
	}
	tilelist.Sort(AIList.SORT_BY_VALUE, !isneartown);
	local success = false;
	// Find a place where the station can be built
	foreach (tile, dummy in tilelist) {
		if (cBuilder.CanBuildRoadStation(tile, dir, hasdepot, is_double)) {
			success = true;
			break;
		} else continue;
	}
	if (!success) return false;
	if (check_build) return MyAIRoad.CanBuildRoadStation(statile, stafront, stationtype, AIStation.STATION_NEW) && MyAIRoad.CanBuildRoadStation(sta2tile, sta2front, stationtype, AIStation.STATION_NEW);

	// Build the parts of the station
	if (success && !WaitAndBuildRoadStation(statile, stafront, stationtype, AIStation.STATION_NEW)) {
		LogWarning("Station could not be built: " + AIError.GetLastErrorString());
		success = false;
	}
	if (success && is_double && !WaitAndBuildRoadStation(sta2tile, sta2front, stationtype, AIStation.GetStationID(statile))) {
		LogWarning("Station could not be built: " + AIError.GetLastErrorString());
		cBuilder.WaitAndDemolish(statile);
		success = false;
	}
	if (success && hasdepot && !WaitAndBuildRoadDepot(deptile, depfront)) {
		LogWarning("Depot could not be built: " + AIError.GetLastErrorString());
		cBuilder.WaitAndDemolish(statile);
		if (is_double) cBuilder.WaitAndDemolish(sta2tile);
		success = false;
	}
	success = success && WaitAndBuildRoad(stafront, statile);
	if (hasdepot) {
		success = success && WaitAndBuildRoad(depfront, deptile);
		success = success && WaitAndBuildRoad(stafront, depfront);
	}
	if (is_double) {
		success = success && WaitAndBuildRoad(sta2front, sta2tile);
		success = success && WaitAndBuildRoad(sta2front, stafront);
	}
	if (!success) {
		AIRoad.RemoveRoad(stafront, statile);
		if (hasdepot) {
			AIRoad.RemoveRoad(depfront, deptile);
			cBuilder.WaitAndDemolish(deptile);
		}
		if (is_double) {
			AIRoad.RemoveRoad(sta2front, sta2tile);
			cBuilder.WaitAndDemolish(sta2tile);
		}
		cBuilder.WaitAndDemolish(statile);
		return false;
	}
	if (is_source) {
		stasrc = AIStation.GetStationID(statile);
		homedepot = deptile;
	} else stadst = AIStation.GetStationID(statile);
	return true;
}

/**
 * Check if a road station can be built at a given place.
 * Builder class variables set: statile, deptile, stafront, depfront
 * @param tile The tile to be checked.
 * @param direction The direction of the proposed station.
 * @param hasdepot True if this station has depot.
 * @param isdouble True if this station is double.
 * @return True if a road station can be built.
 */
function cBuilder::CanBuildRoadStation(tile, direction, hasdepot, isdouble)
{
	if (!AITile.IsBuildable(tile)) return false;
	local offsta = null;
	local offdep = null;
	local middle = null;
	local middleout = null;
	// Calculate the offsets depending on the direction
	switch (direction) {
		case DIR_NE:
			offdep = AIMap.GetTileIndex(0, -1);
			offsta = AIMap.GetTileIndex(-1, 0);
			middle = AITile.CORNER_W;
			middleout = AITile.CORNER_N;
			break;
		case DIR_NW:
			offdep = AIMap.GetTileIndex(1, 0);
			offsta = AIMap.GetTileIndex(0, -1);
			middle = AITile.CORNER_S;
			middleout = AITile.CORNER_W;
			break;
		case DIR_SE:
			offdep = AIMap.GetTileIndex(-1, 0);
			offsta = AIMap.GetTileIndex(0, 1);
			middle = AITile.CORNER_N;
			middleout = AITile.CORNER_E;
			break;
		case DIR_SW:
			offdep = AIMap.GetTileIndex(0, 1);
			offsta = AIMap.GetTileIndex(1, 0);
			middle = AITile.CORNER_E;
			middleout = AITile.CORNER_S;
			break;
	}
	statile = tile;
	deptile = tile + offdep;
	if (!isdouble) sta2tile = tile;
	else sta2tile = tile - offdep;
	stafront = statile + offsta;
	sta2front = sta2tile + offsta;
	depfront = deptile + offsta;
	// Check if the place is buildable
	if (!AITile.IsBuildable(stafront) && !AIRoad.IsRoadTile(stafront)) return false;
	if (isdouble && !AITile.IsBuildable(sta2front) && !AIRoad.IsRoadTile(sta2front)) return false;
	if (hasdepot && !AITile.IsBuildable(deptile)) return false;
	if (hasdepot && !AITile.IsBuildable(depfront) && !AIRoad.IsRoadTile(depfront)) return false;
	local height = AITile.GetMaxHeight(statile);
	local tiles = AITileList();
	tiles.AddTile(statile);
	tiles.AddTile(stafront);
	if (hasdepot) {
		tiles.AddTile(deptile);
		tiles.AddTile(depfront);
	}
	if (isdouble) {
		tiles.AddTile(sta2tile);
		tiles.AddTile(sta2front);
	}
	// Check the slopes
	if (!AIGameSettings.GetValue("construction.build_on_slopes")) foreach (idx, dummy in tiles) if (!MyAITile.IsFlatTile(idx)) return false;
	else {
		if (AITile.GetCornerHeight(stafront, middle) != height && AITile.GetCornerHeight(stafront, middleout) != height) return false;
		//if (isdouble && AITile.GetCornerHeight(sta2front, middle) != height && AITile.GetCornerHeight(sta2front, middleout) != height) return false;
	}
	foreach (idx, dummy in tiles) {
		if (AITile.GetMaxHeight(idx) != height) return false;
		if (AITile.IsSteepSlope(AITile.GetSlope(idx))) return false;
	}
	// Check if the station can be built
	local test = AITestMode();
	if (!MyAIRoad.CanBuildRoad(stafront, statile)) return false;
	if (isdouble && !MyAIRoad.CanBuildRoad(sta2front, sta2tile)) return false;
	if (hasdepot && !MyAIRoad.CanBuildRoad(depfront, deptile)) return false;
	if (hasdepot && !MyAIRoad.CanBuildRoad(stafront, depfront)) return false;
	if (isdouble && !MyAIRoad.CanBuildRoad(sta2front, stafront)) return false;
	if (isdouble) {
		if (hasdepot) if (!MyAIRoad.CanBuildRoad(stafront, stafront + offsta) && !MyAIRoad.CanBuildRoad(sta2front, sta2front + offsta) && !MyAIRoad.CanBuildRoad(sta2front, sta2front - offdep) && !MyAIRoad.CanBuildRoad(depfront, depfront + offsta) && !MyAIRoad.CanBuildRoad(depfront, depfront + offdep)) return false;
		else if (!MyAIRoad.CanBuildRoad(stafront, stafront + offsta) && !MyAIRoad.CanBuildRoad(sta2front, sta2front + offsta) && !MyAIRoad.CanBuildRoad(sta2front, sta2front - offdep) && !MyAIRoad.CanBuildRoad(stafront, stafront + offdep)) return false;
	} else {
		if (hasdepot) if (!MyAIRoad.CanBuildRoad(stafront, stafront + offsta) && !MyAIRoad.CanBuildRoad(stafront, stafront - offdep) && !MyAIRoad.CanBuildRoad(depfront, depfront + offsta) && !MyAIRoad.CanBuildRoad(depfront, depfront + offdep)) return false;
		else if (!MyAIRoad.CanBuildRoad(stafront, stafront + offsta) && !MyAIRoad.CanBuildRoad(stafront, stafront - offdep) && !MyAIRoad.CanBuildRoad(stafront, stafront + offdep)) return false;
	}
	if (!AIRoad.BuildRoadStation(statile, stafront, AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) return false;
	if (isdouble && !AIRoad.BuildRoadStation(sta2tile, sta2front, AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW)) return false;
	if (hasdepot && !AIRoad.BuildRoadDepot(deptile, depfront)) return false;
	test = null;
	LogDebug("Testing if we can build a road station: Yes, it is possible");
	return true;
}

/**
 * Remove a road station.
 * @param sta The StationID of the station.
 */
function cBuilder::DeleteRoadStation(sta)
{
	if (sta == null || !AIStation.IsValidStation(sta)) return;
	// Don't remove the station if there are vehicles still using it
	local vehiclelist = AIVehicleList_Station(sta);
	if (vehiclelist.Count() > 0) {
		LogError(AIStation.GetName(sta) + " cannot be removed, it's still in use!");
		return;
	}
	local place = AIStation.GetLocation(sta);
	local front = AIRoad.GetRoadStationFrontTile(place);
	if (cBuilder.WaitForMoney(Banker.InflatedValue(2000))) return cBuilder.DeleteRoadStationPlace(place, front);
	else return false;
}

/**
 * Remove a road station, if the place and orientation of the road station is already known.
 * Note that this function works even if there is no road station at the given location. The purpose
 * of this is that we can clean up even if we fail to build the road station for some obscure reason.
 * @param place The tile on which the road station is located.
 * @param front The front tile of the road station.
 */
function cBuilder::DeleteRoadStationPlace(place, front)
{
	local offx = AIMap.GetTileX(front) - AIMap.GetTileX(place);
	local offy = AIMap.GetTileY(front) - AIMap.GetTileY(place);
	local dir1 = AIMap.GetTileIndex(offx, offy);
	local placeholder = offx;
	offx = -offy;
	offy = placeholder;
	local dir2 = AIMap.GetTileIndex(offx, offy);
	local place2 = place - dir2;
	local depot = place + dir2;
	local frontdep = depot + dir1;
	local front2 = place2 + dir1;
	if (AITile.IsStationTile(place2) && AIStation.IsValidStation(AIStation.GetStationID(place2)) && AIStation.GetStationID(place) == AIStation.GetStationID(place2)) {
		cBuilder.WaitAndDemolish(place2);
		AIRoad.RemoveRoad(front2, place2);
		if (!AIRoad.AreRoadTilesConnected(front2, front2 + dir1) && !AIRoad.AreRoadTilesConnected(front2, front2 - dir2)) AIRoad.RemoveRoad(front2, front);
	}
	if (AIRoad.IsRoadDepotTile(depot) && AIRoad.GetRoadDepotFrontTile(depot) == frontdep) {
		cBuilder.WaitAndDemolish(depot);
		AIRoad.RemoveRoad(frontdep, depot);
		if (!AIRoad.AreRoadTilesConnected(frontdep, frontdep + dir1) && !AIRoad.AreRoadTilesConnected(frontdep, frontdep + dir2)) AIRoad.RemoveRoad(frontdep, front);
	}
	cBuilder.WaitAndDemolish(place);
	AIRoad.RemoveRoad(front, place);
	if (!AIRoad.AreRoadTilesConnected(front, front + dir1) && !AIRoad.AreRoadTilesConnected(front, front - dir2) && !AIRoad.AreRoadTilesConnected(front, front + dir2)) cBuilder.WaitAndDemolish(front);
	return true;
}

/**
 * Wait for money and buils a road station.
 * @param tile Place to build the station.
 * @param front The tile exactly in front of the station.
 * @param road_veh_type Whether to build a truck or bus station.
 * @param station_id The station to join, AIStation::STATION_NEW or AIStation::STATION_JOIN_ADJACENT.
 * @return Whether the station has been/can be build or not.
 */
function cBuilder::WaitAndBuildRoadStation(tile, front, road_veh_type, station_id)
{
	if (!cBuilder.WaitForMoney(MyAIRoad.GetRoadStationCost(tile, front, road_veh_type, station_id))) return false;
	return AIRoad.BuildRoadStation(tile, front, road_veh_type, station_id);
}

