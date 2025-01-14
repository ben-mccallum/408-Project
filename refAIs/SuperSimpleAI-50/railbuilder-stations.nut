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
 * Build or check a single (one-lane) rail station at a town or an industry.
 * Builder class variables used: crg, src, dst, srcplace, dstplace, srcistown, dstistown,
 *   statile, stafront, depfront, frontfront, statop, stationdir, extracrg, extra_dst
 * Builder class variables set: stasrc, stadst, homedepot
 * @param is_source True if we are building the source station.
 * @param platform_length The length of the new station's platform.
 * @param check_build True to check if its buildable, false to build it.
 * @param check_extra_ind True to check if the extra industry can be linked to this station.
 * @return True if the construction succeeded.
 */
function cBuilder::BuildSingleRailSourceStation(platform_length, check_extra_ind = false)	{ return BuildOrCheckSingleRailStation(true, platform_length, false, check_extra_ind); }
function cBuilder::CheckSingleRailSourceStation(platform_length, check_extra_ind = false)	{ return BuildOrCheckSingleRailStation(true, platform_length, true, check_extra_ind); }
function cBuilder::BuildSingleRailDestinationStation(platform_length, check_extra_ind = false)	{ return BuildOrCheckSingleRailStation(false, platform_length, false, check_extra_ind); }
function cBuilder::CheckSingleRailDestinationStation(platform_length, check_extra_ind = false)	{ return BuildOrCheckSingleRailStation(false, platform_length, true, check_extra_ind); }
function cBuilder::BuildOrCheckSingleRailStation(is_source, platform_length, check_build, check_extra_ind)
{
	local dir, altdir, tilelist, thisplace, otherplace, isneartown = false, success = false;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN) + platform_length - 1;
	local industry = isneartown ? null : (is_source ? src : dst);
	local industry_2 = isneartown ? null : (check_extra_ind ? extra_dst : null);
	local tile_tested = is_source ? srctile_tested : dsttile_tested;
	// Determine the direction of the station, and get tile lists
	if (is_source) {
		dir = MyAIMap.GetDirection(srcplace, dstplace);
		altdir = MyAIMap.GetSecondaryDirection(srcplace, dstplace);
		if (srcistown) {
			tilelist = MyAITile.GetTilesAroundTown(src, 1, 1);
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryProducing(src, rad);
		}
		thisplace = srcplace;
		otherplace = dstplace;
	} else {
		if (passplace == null) {
			dir = MyAIMap.GetDirection(dstplace, srcplace);
			altdir = MyAIMap.GetSecondaryDirection(dstplace, srcplace);
			otherplace = srcplace;
		} else {
			dir = MyAIMap.GetDirection(dstplace, passplace);
			altdir = MyAIMap.GetSecondaryDirection(dstplace, passplace);
			otherplace = passplace;
		}
		if (dstistown) {
			tilelist = MyAITile.GetTilesAroundTown(dst, 1, 1);
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryAccepting(dst, rad);
		}
		thisplace = dstplace;
	}
	if (tile_tested != null) {
		// Try to build the station at previously tested tile.
		if (CanBuildSingleRailStation(tile_tested, dir, platform_length, is_source, industry, industry_2)) success = true;
		if (!success && CanBuildSingleRailStation(tile_tested, altdir, platform_length, is_source, industry, industry_2)) {
			success = true;
			dir = altdir;
		}
	}
	if (!success) {
		tilelist.Valuate(AITile.IsBuildable);
		tilelist.KeepValue(1);
		// Sort the tile list
		if (isneartown) {
			tilelist.Valuate(AITile.GetCargoAcceptance, crg, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_TRAIN));
			tilelist.KeepAboveValue(10);
		} else {
			if (AISettings.IsClosestStation()) tilelist.Valuate(AIMap.DistanceManhattan, thisplace);
			else tilelist.Valuate(AIMap.DistanceManhattan, otherplace);
		}
		tilelist.Sort(AIList.SORT_BY_VALUE, !isneartown);
		// Find a place where the station can bee built
		foreach (tile, dummy in tilelist) {
			if (CanBuildSingleRailStation(tile, dir, platform_length, is_source, industry, industry_2)) {
				success = true;
				if (is_source) srctile_tested = tile;
				else dsttile_tested = tile;
				break;
			} else continue;
		}
	}
	if (!success) {
		// Find a place where the perpendicular station can bee built
		foreach (tile, dummy in tilelist) {
			if (CanBuildSingleRailStation(tile, altdir, platform_length, is_source, industry, industry_2)) {
				success = true;
				dir = altdir;
				if (is_source) srctile_tested = tile;
				else dsttile_tested = tile;
				break;
			} else continue;
		}
	}
	if (!success) return false;
	if (check_build) return MyAIRail.CanBuildRailStation(statop, stationdir, 1, platform_length, AIStation.STATION_NEW);
	//if (check_extra_ind) extra_dst = null;

	// Build the station itself
	local newsta = is_source ? (AIMap.DistanceManhattan(dstplace, statop) > AIMap.DistanceManhattan(dstplace, stabottom) ? statop : stabottom) : (AIMap.DistanceManhattan(srcplace, statop) > AIMap.DistanceManhattan(srcplace, stabottom) ? statop : stabottom);
	success = success && AIRail.BuildRailStation(newsta, stationdir, 1, 1, AIStation.STATION_NEW);
	if (!success) {
		LogError("Station could not be built: " + AIError.GetLastErrorString());
		return false;
	}
	if (extracrg == null || (extra_dst != null && !check_extra_ind)) {
		success = success && WaitAndBuildNewGRFRailStation(statop, stationdir, 1, platform_length, AIStation.GetStationID(newsta), crg, AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(dst), AIMap.DistanceManhattan(srcplace, dstplace), is_source);
	} else {
		local platform_1 = (platform_length / 2).tointeger();
		local platform_2 = platform_length - platform_1;
		local crg_1 = (dir == DIR_NW || dir == DIR_NE) ? crg: extracrg;
		local crg_2 = (dir == DIR_NW || dir == DIR_NE) ? extracrg : crg;
		success = success && WaitAndBuildNewGRFRailStation(statop, stationdir, 1, platform_1, AIStation.GetStationID(newsta), crg_1, AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(dst), AIMap.DistanceManhattan(srcplace, dstplace), is_source);
		success = success && WaitAndBuildNewGRFRailStation(staextracrg, stationdir, 1, platform_2, AIStation.GetStationID(newsta), crg_2, AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(dst), AIMap.DistanceManhattan(srcplace, dstplace), is_source);
	}
	// Build the rails and the depot
	if (AISettings.IsOldStyleRailLine() || (srcistown && dstistown)) {
		success = success && WaitAndBuildRail(statile, depfront, stafront);
		success = success && WaitAndBuildRail(depfront, stafront, frontfront);
		success = success && WaitAndBuildRailDepot(deptile, depfront);
		success = success && WaitAndBuildRail(statile, depfront, deptile);
		success = success && WaitAndBuildRail(deptile, depfront, stafront);
		if (AISettings.NeedExtraSignal()) {
			// Build an extra path signal according to the setting
			success = success && AIRail.BuildSignal(stafront, depfront, AIRail.SIGNALTYPE_PBS);
		}
	}
	if (success) {
		local headtiles = BuildRawRailHead(stafront, stavector, starvector, true);
		if (headtiles == null) return false;
		else {
			stafront = stafront + headtiles * stavector;
			frontfront = frontfront + headtiles * stavector;
		}
	}
	if (!success) {
		// If we couldn't build the station for any reason
		LogWarning("Station construction was interrupted.")
		RemoveRailLine(statile);
		RemoveRailLine(newsta);
		return false;
	}
	// Register the station
	if (is_source) {
		stasrc = AIStation.GetStationID(statile);
		homedepot = deptile;
	} else {
		stadst = AIStation.GetStationID(statile);
	}
	return true;
}

/**
 * Check whether a single rail station can be built at the given position.
 * Builder class variables set: statop, stabotton, statile, stafront, depfront, frontfront, srcistown, dstistown
 * @param tile The tile to be checked.
 * @param direction The direction of the proposed station.
 * @param platform_length The length of the proposed station's platform.
 * @param is_source True if is a source station.
 * @param industry The industry to be linked, null if it's linked to a town.
 * @param industry_2 The extra industry to be linked, null if it's linked to a town or not second industry was found.
 * @return True if a single rail station can be built at the given position.
 */
function cBuilder::CanBuildSingleRailStation(tile, direction, platform_length, is_source, industry, industry_2 = null)
{
	if (!AITile.IsBuildable(tile)) return false;
	local vector = null, rvector = null;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	// Determine some direction vectors
	switch (direction) {
		case DIR_NW:
			vector = AIMap.GetTileIndex(0, -1);
			rvector = AIMap.GetTileIndex(-1, 0);
			stationdir = AIRail.RAILTRACK_NW_SE;
			break;
		case DIR_NE:
			vector = AIMap.GetTileIndex(-1, 0);
			rvector = AIMap.GetTileIndex(0, 1);
			stationdir = AIRail.RAILTRACK_NE_SW;
			break;
		case DIR_SW:
			vector = AIMap.GetTileIndex(1, 0);
			rvector = AIMap.GetTileIndex(0, -1);
			stationdir = AIRail.RAILTRACK_NE_SW;
			break;
		case DIR_SE:
			vector = AIMap.GetTileIndex(0, 1);
			rvector = AIMap.GetTileIndex(1, 0);
			stationdir = AIRail.RAILTRACK_NW_SE;
			break;
	}
	stavector = vector;
	starvector = rvector;
	// Determine the top and the bottom tile of the station, used for building the station itself
	if (direction == DIR_NW || direction == DIR_NE) {
		stabottom = tile;
		statop = tile + (platform_length - 1) * vector;
		statile = statop;
		staoffset1 = stabottom;
		staoffset2 = stabottom - vector;
		staextracrg = statop - (platform_length / 2).tointeger() * vector;
	} else {
		statop = tile;
		stabottom = tile + (platform_length - 1) * vector;
		statile = stabottom;
		staoffset1 = statop;
		staoffset2 = statop - vector;
		staextracrg = statop + (platform_length / 2).tointeger() * vector;
	}
	local test = AITestMode();
	// Check if the station can be built
	if (!AIRail.BuildRailStation(statop, stationdir, 1, platform_length, AIStation.STATION_NEW)) return false;
	if (industry_2 != null) {
		local station_tile_list = AITileList();
		station_tile_list.AddRectangle(statop, stabottom);
		local found = false;
		foreach (stile, dummy in station_tile_list) if (AITile.GetCargoAcceptance(stile, extracrg, 1, 1, rad) && MyAIIndustry.IsTileValidForRailStation(stile, industry_2, is_source)) {
			found = true;
			break;
		}
		if (!found) return false;
	}
	if (industry != null) {
		local station_tile_list = AITileList();
		station_tile_list.AddRectangle(statop, stabottom);
		local found = false;
		foreach (stile, dummy in station_tile_list) if (AITile.GetCargoAcceptance(stile, crg, 1, 1, rad) && MyAIIndustry.IsTileValidForRailStation(stile, industry, is_source)) {
			found = true;
			break;
		}
		if (!found) return false;
	}
	// Set the other positions
	local builddepot = (AISettings.IsOldStyleRailLine() || (srcistown && dstistown));
	if (builddepot) {
		depfront = statile + vector;
		if (!AITile.IsBuildable(depfront)) return false;
		deptile = depfront + rvector;
		stafront = depfront + vector;
		if (!AIRail.BuildRailDepot(deptile, depfront) || !AIRail.BuildRail(statile, depfront, deptile) || !AIRail.BuildRail(deptile, depfront, stafront)) deptile = depfront - rvector;;
	} else {
		stafront = statile;
	}
	frontfront = stafront + vector;
	if (builddepot) {
		if (!AIRail.BuildRailDepot(deptile, depfront)) return false;
		if (!AIRail.BuildRail(statile, depfront, deptile)) return false;
		if (!AIRail.BuildRail(deptile, depfront, stafront)) return false;
		if (!AIRail.BuildRail(statile, depfront, stafront)) return false;
		if (!AITile.IsBuildable(stafront)) return false;
		if (!AIRail.BuildRail(depfront, stafront, frontfront)) return false;
	}
	if (!CheckRailHead(stafront, vector, rvector) && !CheckRailHead(stafront, vector, -rvector)) return false;
	// Check if there is a station just at the back of the proposed station
	if (AIRail.IsRailStationTile(statile - platform_length * vector)) {
		if (AICompany.IsMine(AITile.GetOwner(statile - platform_length * vector)) && AIRail.GetRailStationDirection(statile - platform_length * vector) == stationdir)
			return false;
	}
	test = null;
	LogDebug("Testing if we can build a single station: Yes, it is possible");
	return true;
}

/**
 * Build a double (two-lane) rail station at a town or an industry.
 * Builder class variables used: crg, extracrg, src, dst, srcplace, dstplace, srcistown, dstistown,
 *   statile, deptile, stafront, depfront, frontfront, front1, front2, lane2, morefront
 * Builder class variables set: stasrc, stadst, homedepot
 * @param is_source True if we are building the source station.
 * @param platform_length The length of the proposed station's platform.
 * @param passinglanes Number of passing lanes.
 * @param check_build True to check if its buildable, false to build it.
 * @param check_extra_ind True to check if the extra industry can be linked to this station.
 * @return True if the construction succeeded.
 */
function cBuilder::BuildDoubleRailSourceStation(platform_length, passinglanes, check_extra_ind = false)		{ return BuildOrCheckDoubleRailStation(true, platform_length, passinglanes, false, check_extra_ind); }
function cBuilder::CheckDoubleRailSourceStation(platform_length, passinglanes, check_extra_ind = false)		{ return BuildOrCheckDoubleRailStation(true, platform_length, passinglanes, true, check_extra_ind); }
function cBuilder::BuildDoubleRailDestinationStation(platform_length, passinglanes, check_extra_ind = false)	{ return BuildOrCheckDoubleRailStation(false, platform_length, passinglanes, false, check_extra_ind); }
function cBuilder::CheckDoubleRailDestinationStation(platform_length, passinglanes, check_extra_ind = false)	{ return BuildOrCheckDoubleRailStation(false, platform_length, passinglanes, true, check_extra_ind); }
function cBuilder::BuildOrCheckDoubleRailStation(is_source, platform_length, passinglanes, check_build, check_extra_ind)
{
	local dir, altdir, tilelist, thisplace, otherplace, isneartown = false, success = false;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN) + platform_length - 1;
	local need_signal = false;
	local signaltype = (AISettings.IsSignalTypePBS()) ? AIRail.SIGNALTYPE_PBS : AIRail.SIGNALTYPE_NORMAL_TWOWAY;
	local industry = isneartown ? null : (is_source ? src : dst);
	local industry_2 = isneartown ? null : (check_extra_ind ? (is_source ? extra_src : extra_dst) : null);
	local tile_tested = is_source ? srctile_tested : dsttile_tested;
	if (signaltype == AIRail.SIGNALTYPE_PBS && (passinglanes == 0 || (AISettings.FastRailPathFinder() && passinglanes == 1))) need_signal = true;
	// Get the tile list
	if (is_source) {
		if (passplace == null) {
			dir = MyAIMap.GetDirection(srcplace, dstplace);
			altdir = MyAIMap.GetSecondaryDirection(srcplace, dstplace);
			otherplace = dstplace;
		} else {
			dir = MyAIMap.GetDirection(srcplace, passplace);
			altdir = MyAIMap.GetSecondaryDirection(srcplace, passplace);
			otherplace = passplace;
		}
		if (srcistown) {
			tilelist = MyAITile.GetTilesAroundTown(src, 2, 2);
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryProducing(src, rad);
		}
		thisplace = srcplace;
	} else {
		dir = MyAIMap.GetDirection(dstplace, srcplace);
		altdir = MyAIMap.GetSecondaryDirection(dstplace, srcplace);
		if (dstistown) {
			tilelist = MyAITile.GetTilesAroundTown(dst, 2, 2);
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryAccepting(dst, rad);
		}
		thisplace = dstplace;
		otherplace = srcplace;
	}
	if (tile_tested != null) {
		// Try to build the station at previously tested tile.
		if (CanBuildDoubleRailStation(tile_tested, dir, platform_length, is_source, need_signal, industry, industry_2)) success = true;
		if (!success && CanBuildDoubleRailStation(tile_tested, altdir, platform_length, is_source, need_signal, industry, industry_2)) {
			success = true;
			dir = altdir;
		}
	}
	if (!success) {
		tilelist.Valuate(AITile.IsBuildable);
		tilelist.KeepValue(1);
		// Sort the tile list
		if (isneartown) {
			tilelist.Valuate(AITile.GetCargoAcceptance, crg, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_TRAIN));
			tilelist.KeepAboveValue(10);
		} else {
			if (AISettings.IsClosestStation()) tilelist.Valuate(AIMap.DistanceManhattan, thisplace);
			else tilelist.Valuate(AIMap.DistanceManhattan, otherplace);
		}
		tilelist.Sort(AIList.SORT_BY_VALUE, !isneartown);
		// Find a place where the station can be built
		foreach (tile, dummy in tilelist) {
			if (CanBuildDoubleRailStation(tile, dir, platform_length, is_source, need_signal, industry, industry_2)) {
				success = true;
				if (is_source) srctile_tested = tile;
				else dsttile_tested = tile;
				break;
			} else continue;
		}
	}
	if (!success) {
		// Find a place where the perpendicular station can be built
		foreach (tile, dummy in tilelist) {
			if (CanBuildDoubleRailStation(tile, altdir, platform_length, is_source, need_signal, industry, industry_2)) {
				success = true;
				dir = altdir;
				if (is_source) srctile_tested = tile;
				else dsttile_tested = tile;
				break;
			} else continue;
		}
	}
	if (!success) return false;
	if (check_build) return MyAIRail.CanBuildRailStation(statop, stationdir, 2, platform_length, AIStation.STATION_NEW);

	// Build the station itself
	local newsta = is_source ? (AIMap.DistanceManhattan(dstplace, statop) > AIMap.DistanceManhattan(dstplace, stabottom) ? statop : stabottom) : (AIMap.DistanceManhattan(srcplace, statop) > AIMap.DistanceManhattan(srcplace, stabottom) ? statop : stabottom);
	success = success && AIRail.BuildRailStation(newsta, stationdir, 1, 1, AIStation.STATION_NEW);
	if (!success) {
		LogError("Station could not be built: " + AIError.GetLastErrorString());
		return false;
	}
	if (extracrg == null) {
		success = success && WaitAndBuildNewGRFRailStation(statop, stationdir, 2, platform_length, AIStation.GetStationID(newsta), crg, AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(dst), AIMap.DistanceManhattan(srcplace, dstplace), is_source);
	} else {
		local platform_1 = (platform_length / 2).tointeger();
		local platform_2 = platform_length - platform_1;
		local crg_1 = (dir == DIR_NW || dir == DIR_NE) ? crg: extracrg;
		local crg_2 = (dir == DIR_NW || dir == DIR_NE) ? extracrg : crg;
		local dst_1 = (dir == DIR_NW || dir == DIR_NE) ? dst : (extra_dst == null ? dst : extra_dst);
		local dst_2 = (dir == DIR_NW || dir == DIR_NE) ? (extra_dst == null ? dst : extra_dst) : dst;
		success = success && WaitAndBuildNewGRFRailStation(statop, stationdir, 2, platform_1, AIStation.GetStationID(newsta), crg_1, AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(dst_1), AIMap.DistanceManhattan(srcplace, dstplace), is_source);
		success = success && WaitAndBuildNewGRFRailStation(staextracrg, stationdir, 2, platform_2, AIStation.GetStationID(newsta), crg_2, AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(dst_2), AIMap.DistanceManhattan(srcplace, dstplace), is_source);
	}

	// Build the station parts
	if (!AISettings.IsSignalTypePBS()) {
		success = success && WaitAndBuildRail(statile, front1, depfront);
		success = success && WaitAndBuildRail(lane2, front2, stafront);
		success = success && AIRail.BuildSignal(front1, statile, signaltype);
		success = success && AIRail.BuildSignal(front2, lane2, signaltype);
	}
	success = success && WaitAndBuildRail(front1, depfront, deptile);
	success = success && WaitAndBuildRail(front2, stafront, frontfront);
	if (staoption == 0 && AISettings.FastRailBuild()) {
		success = success && WaitAndBuildRail(front1, depfront, frontfront);
	} else {
		success = success && WaitAndBuildRail(front1, depfront, stafront);
		success = success && WaitAndBuildRail(depfront, stafront, frontfront);
	}
	if (depoption == 0 && AISettings.FastRailBuild()) {
		success = success && WaitAndBuildRail(front2, stafront, deptile);
	} else {
		success = success && WaitAndBuildRail(front2, stafront, depfront);
		success = success && WaitAndBuildRail(stafront, depfront, deptile);
	}
	if (staoption == 1 || need_signal) {
		success = success && WaitAndBuildRail(stafront, frontfront, morefront);
	} else {
		morefront = frontfront;
		frontfront = stafront;
	}
	if (need_signal) success = success && AIRail.BuildSignal(frontfront, morefront, signaltype);
	if (success) {
		local headtiles = BuildRailHead(frontfront, stavector, starvector);
		if (headtiles == null) success = false;
		else {
			morefront = morefront + headtiles * stavector;
			frontfront = frontfront + headtiles * stavector;
		}
	}
	
	success = success && WaitAndBuildRailDepot(deptile, depfront);
	// Handle it if the construction was interrupted for any reason
	if (!success) {
		LogError("Station construction was interrupted.");
		RemoveRailLine(statile);
		RemoveRailLine(front2);
		RemoveRailLine(newsta);
		return false;
	}
	// Register the station
	if (is_source) {
		stasrc = AIStation.GetStationID(statile);
		homedepot = deptile;
	} else {
		stadst = AIStation.GetStationID(statile);
	}
	return true;
}

/**
 * Determine whether a double rail station can be built at a given place.
 * Builder class variables set: statile, deptile, stafront, depfront, front1, front2,
 *   lane2, frontfront, morefront, statop, stabottom, staextracrg
 * @param tile The tile to be checked.
 * @param direction The direction of the proposed station.
 * @param platform_length The length of the proposed station's platform.
 * @param is_source True if is a source station.
 * @param need_sifnal True if need a entrance signal.
 * @param industry The industry to be linked, null if it's linked to a town.
 * @param industry_2 The extra industry to be linked, null if it's linked to a town or not second industry was found.
 * @return Ture if a double rail station can be built at the given position.
 */
function cBuilder::CanBuildDoubleRailStation(tile, direction, platform_length, is_source, need_signal, industry, industry_2 = null)
{
	if (!AITile.IsBuildable(tile)) return false;
	local test = AITestMode();
	local vector, rvector = null;
	local reverse = false;
	local station_is_first_place = true;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	// Determine whether we're building a flipped station
	local src_x, src_y, dst_x, dst_y, ps_x, ps_y;
	src_x = AIMap.GetTileX(tile);
	src_y = AIMap.GetTileY(tile);
	if (is_source) {
		dst_x = AIMap.GetTileX(dst_offset[1]);
		dst_y = AIMap.GetTileY(dst_offset[1]);
	} else {
		dst_x = AIMap.GetTileX(dstplace);
		dst_y = AIMap.GetTileY(dstplace);
	}
	// Set the direction vectors
	switch (direction) {
		case DIR_NW:
			vector = AIMap.GetTileIndex(0, -1);
			rvector = AIMap.GetTileIndex(1, 0);
			stationdir = AIRail.RAILTRACK_NW_SE;
			if (src_x > dst_x) reverse = true;
			break;
		case DIR_NE:
			vector = AIMap.GetTileIndex(-1, 0);
			rvector = AIMap.GetTileIndex(0, 1);
			stationdir = AIRail.RAILTRACK_NE_SW;
			if (src_y > dst_y) reverse = true;
			break;
		case DIR_SW:
			vector = AIMap.GetTileIndex(1, 0);
			rvector = AIMap.GetTileIndex(0, 1);
			stationdir = AIRail.RAILTRACK_NE_SW;
			if (src_y > dst_y) reverse = true;
			break;
		case DIR_SE:
			vector = AIMap.GetTileIndex(0, 1);
			rvector = AIMap.GetTileIndex(1, 0);
			stationdir = AIRail.RAILTRACK_NW_SE;
			if (src_x > dst_x) reverse = true;
			break;
	}
	// Set the top and the bottom tile of the station
	if (direction == DIR_NW || direction == DIR_NE) {
		stabottom = tile;
		statop = tile + (platform_length - 1) * vector;
		staextracrg = statop - (platform_length / 2).tointeger() * vector;
		statile = statop;
	} else {
		statop = tile;
		stabottom = tile + (platform_length - 1) * vector;
		staextracrg = statop + (platform_length / 2).tointeger() * vector;
		statile = stabottom;
	}
	staoffset1 = tile + ((platform_length - 1) / 2).tointeger() * vector;
	staoffset2 = tile + ((platform_length + 1) / 2).tointeger() * vector;
	if (!is_source) reverse = !reverse;
	if (reverse) {
		rvector = -rvector;
		statile = statile - rvector;
	}

	// Set the tiles for the station parts
	lane2 = statile + rvector;
	if (!AISettings.IsSignalTypePBS()) {
		front1 = statile + vector;
		front2 = lane2 + vector;
	} else {
		front1 = statile;
		front2 = lane2;
	}
	depfront = front1 + vector;
	stafront = front2 + vector;
	deptile = depfront + vector;
	frontfront = stafront + vector;
	if (need_signal) morefront = frontfront + vector;
	else morefront = frontfront;
	stavector = vector;
	starvector = rvector;
	staoption = 0;
	depoption = 0;
	// Try the second place for the station exit if the first one is not suitable
	if (!AITile.IsBuildable(frontfront) || (need_signal && (!AITile.IsBuildable(morefront) || !AIRail.BuildRail(stafront, frontfront, morefront))) || !CheckRailHead(stafront, stavector, starvector)) {
		stavector = rvector;
		starvector = vector;
		frontfront = stafront + rvector;
		morefront = frontfront + rvector;
		station_is_first_place = false;
		staoption = 1;
	}
	// Try the second place for the depot if the first one is not suitable
	if ((station_is_first_place && AIGameSettings.GetValue("forbid_90_deg")) || !AIRail.BuildRailDepot(deptile, depfront)) {
		deptile = depfront - rvector;
		depoption = 1;
	}
	// Do the tests
	if (!AIRail.BuildRailStation(statop, stationdir, 2, platform_length, AIStation.STATION_NEW)) return false;
	if (industry_2 != null) {
		local station_tile_list = AITileList();
		station_tile_list.AddRectangle(statop, stabottom);
		local found = false;
		if (is_source) {
			foreach (stile, dummy in station_tile_list) if (AITile.GetCargoProduction(stile, extracrg, 1, 1, rad) && MyAIIndustry.IsTileValidForRailStation(stile, industry_2, true)) {
				found = true;
				break;
			}
		} else {
			foreach (stile, dummy in station_tile_list) if (AITile.GetCargoAcceptance(stile, extracrg, 1, 1, rad) && MyAIIndustry.IsTileValidForRailStation(stile, industry_2, false)) {
				found = true;
				break;
			}
		}
		if (!found) return false;
	}
	if (industry != null) {
		local station_tile_list = AITileList();
		station_tile_list.AddRectangle(statile, lane2 + (platform_length - 1) * vector);
		local found = false;
		if (is_source) {
			foreach (stile, dummy in station_tile_list) if (AITile.GetCargoProduction(stile, crg, 1, 1, rad) && MyAIIndustry.IsTileValidForRailStation(stile, industry, true)) {
				found = true;
				break;
			}
		} else {
			foreach (stile, dummy in station_tile_list) if (AITile.GetCargoAcceptance(stile, crg, 1, 1, rad) && MyAIIndustry.IsTileValidForRailStation(stile, industry, false)) {
				found = true;
				break;
			}
		}
		if (!found) return false;
	}
	if (!AISettings.IsSignalTypePBS()) {
		if (!AITile.IsBuildable(front1)) return false;
		if (!AIRail.BuildRail(statile, front1, depfront)) return false;
		if (!AITile.IsBuildable(front2)) return false;
		if (!AIRail.BuildRail(lane2, front2, stafront)) return false;
	}
	if (!AITile.IsBuildable(depfront)) return false;
	if (!AIRail.BuildRail(front1, depfront, deptile)) return false;
	if (!AITile.IsBuildable(stafront)) return false;
	if (!AIRail.BuildRail(front2, stafront, frontfront)) return false;
	if (!AIRail.BuildRail(front1, depfront, stafront)) return false;
	if (!AIRail.BuildRail(front2, stafront, depfront)) return false;
	if (!AIRail.BuildRail(depfront, stafront, frontfront)) return false;
	if (!AIRail.BuildRail(stafront, depfront, deptile)) return false;
	if (!station_is_first_place || need_signal) if (!AITile.IsBuildable(frontfront) || !AIRail.BuildRail(stafront, frontfront, morefront)) return false;
	if (!CheckRailHead(frontfront, stavector, starvector)) return false;
	if (!AIRail.BuildRailDepot(deptile, depfront)) return false;
	// Check if there is a station just at the back of the proposed station
	if (AIRail.IsRailStationTile(statile - platform_length * vector)) {
		if (AICompany.IsMine(AITile.GetOwner(statile - platform_length * vector)) && AIRail.GetRailStationDirection(statile - platform_length * vector) == stationdir) return false;
	}
	if (AIRail.IsRailStationTile(lane2 - platform_length * vector)) {
		if (AICompany.IsMine(AITile.GetOwner(lane2 - platform_length * vector)) && AIRail.GetRailStationDirection(lane2 - platform_length * vector) == stationdir) return false;
	}
	test = null;
	LogDebug("Testing if we can build a double station: Yes, it is possible");
	return true;
}

/**
 * Build a double passing lane rail station at an industry.
 * Builder class variables used: extracrg, src, dst, srcplace, dstplace, srcistown, dstistown,
 *   statile, deptile, stafront, depfront, frontfront, front1, front2, lane2, morefront
 * Builder class variables set: stasrc, stadst, homedepot
 * @param is_source True if we are building the source station.
 * @param platform_length The length of the proposed station's platform.
 * @param check_build True to check if its buildable, false to build it.
 * @return True if the construction succeeded.
 */
function cBuilder::BuildDoubleRailPassingStation(platform_length)		{ return BuildOrCheckDoubleRailPassingStation(platform_length, false); }
function cBuilder::CheckDoubleRailPassingStation(platform_length)		{ return BuildOrCheckDoubleRailPassingStation(platform_length, true); }
function cBuilder::BuildOrCheckDoubleRailPassingStation(platform_length, check_build)
{
	local dir, altdir, tilelist, thisplace, otherplace, isneartown = false, success = false;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN) + platform_length - 1;
	local need_signal = false;
	local signaltype = (AISettings.IsSignalTypePBS()) ? AIRail.SIGNALTYPE_PBS : AIRail.SIGNALTYPE_NORMAL_TWOWAY;
	local industry = isneartown ? null : extra_dst;
	local end = [[], [], [], [], []];
	end[0] = [null, null]; end[1] = [null, null]; end[2] = [null, null]; end[3] = [null, null], end[4] = [null, null];

	// Get the tile list
	dir = MyAIMap.GetDirection(srcplace, dstplace);
	altdir = MyAIMap.GetSecondaryDirection(srcplace, dstplace);
	if (passtile_tested != null) {
		// Try to build the station at previously tested tile.
		if (CanBuildDoubleRailPassingStation(passtile_tested, dir, platform_length, industry)) success = true;
		if (!success && CanBuildDoubleRailPassingStation(passtile_tested, altdir, platform_length, industry)) {
			success = true;
			dir = altdir;
		}
	}
	if (!success) {
		if (passistown) {
			tilelist = MyAITile.GetTilesAroundTown(extra_dst, 2, 2);
			isneartown = true;
			thisplace = AITown.GetLocation(extra_dst);
		} else {
			tilelist = AITileList_IndustryAccepting(extra_dst, rad);
			thisplace = AIIndustry.GetLocation(extra_dst);
		}
		otherplace = srcplace;
		tilelist.Valuate(AITile.IsBuildable);
		tilelist.KeepValue(1);
		// Sort the tile list
		if (isneartown) {
			tilelist.Valuate(AITile.GetCargoAcceptance, extracrg, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_TRAIN));
			tilelist.KeepAboveValue(10);
		} else {
			if (AISettings.IsClosestStation()) tilelist.Valuate(AIMap.DistanceManhattan, thisplace);
			else tilelist.Valuate(AIMap.DistanceManhattan, otherplace);
		}
		tilelist.Sort(AIList.SORT_BY_VALUE, !isneartown);
		// Find a place where the station can be built
		foreach (tile, dummy in tilelist) {
			if (CanBuildDoubleRailPassingStation(tile, dir, platform_length, industry)) {
				success = true;
				passtile_tested = tile;
				break;
			} else continue;
		}
	}
	if (!success) {
		// Find a place where the perpendicular station can be built
		foreach (tile, dummy in tilelist) {
			if (CanBuildDoubleRailPassingStation(tile, altdir, platform_length, industry)) {
				success = true;
				dir = altdir;
				passtile_tested = tile;
				break;
			} else continue;
		}
	}
	if (!success) return null;
	if (check_build) return MyAIRail.CanBuildRailStation(statop, stationdir, 2, platform_length, AIStation.STATION_NEW) ? true : null;

	// Build the station itself
	local newsta = AIMap.DistanceManhattan(srcplace, statop) > AIMap.DistanceManhattan(srcplace, stabottom) ? statop : stabottom;
	success = success && AIRail.BuildRailStation(newsta, stationdir, 1, 1, AIStation.STATION_NEW);
	if (!success) {
		LogError("Station could not be built: " + AIError.GetLastErrorString());
		return null;
	}
	success = success && WaitAndBuildNewGRFRailStation(statop, stationdir, 2, platform_length, AIStation.GetStationID(newsta), extracrg, AIIndustry.GetIndustryType(src), AIIndustry.GetIndustryType(extra_dst), AIMap.DistanceManhattan(srcplace, dstplace), false);

	// Build the station parts
	success = success && WaitAndBuildRail(front2, stafront, frontfront);
	if (AISettings.FastRailBuild()) {
		success = success && WaitAndBuildRail(front1, depfront, frontfront);
	} else {
		success = success && WaitAndBuildRail(front1, depfront, stafront);
		success = success && WaitAndBuildRail(depfront, stafront, frontfront);
	}
	success = success && AIRail.BuildSignal(depfront, front1, AIRail.SIGNALTYPE_PBS_ONEWAY);
	morefront = frontfront;
	frontfront = stafront;
	if (success) {
		local headtiles = BuildRailHead(frontfront, stavector, starvector);
		if (headtiles == null) success = false;
		else {
			morefront = morefront + headtiles * stavector;
			frontfront = frontfront + headtiles * stavector;
			if (headtiles == 0 && MyAIRail.CanBuildRail(stafront, morefront, deptile)) end[2] = [deptile, depfront];
		}
	}
	end[0] = [morefront, frontfront];
	success = success && WaitAndBuildRail(passfront2, passstafront, passfrontfront);
	if (AISettings.FastRailBuild()) {
		success = success && WaitAndBuildRail(passfront1, passdepfront, passfrontfront);
	} else {
		success = success && WaitAndBuildRail(passfront1, passdepfront, passstafront);
		success = success && WaitAndBuildRail(passdepfront, passstafront, passfrontfront);
	}
	success = success && AIRail.BuildSignal(passdepfront, passfront1, AIRail.SIGNALTYPE_PBS_ONEWAY);
	passmorefront = passfrontfront;
	passfrontfront = passstafront;
	if (success) {
		local headtiles = BuildRailHead(passfrontfront, -stavector, -starvector);
		if (headtiles == null) success = false;
		else {
			passmorefront = passmorefront - headtiles * stavector;
			passfrontfront = passfrontfront - headtiles * stavector;
			if (headtiles == 0 && MyAIRail.CanBuildRail(passstafront, passmorefront, deppasstile)) end[3] = [deppasstile, passdepfront];
		}
	}
	end[1] = [passmorefront, passfrontfront];
	end[4] = [staoffset1, staoffset2];

	// Handle it if the construction was interrupted for any reason
	if (!success) {
		LogError("Station construction was interrupted.");
		RemoveRailLine(statile);
		RemoveRailLine(front2);
		RemoveRailLine(newsta);
		return null;
	}
	// Register the station
	stapass = AIStation.GetStationID(statile);
	return end;
}

/**
 * Determine whether a double rail station can be built at a given place.
 * Builder class variables set: statile, deptile, stafront, depfront, front1, front2,
 *   lane2, frontfront, morefront, statop, stabottom
 * @param tile The tile to be checked.
 * @param direction The direction of the proposed station.
 * @param platform_length The length of the proposed station's platform.
 * @param industry The industry to be linked, null if it's linked to a town.
 * @return Ture if a double rail passing station can be built at the given position.
 */
function cBuilder::CanBuildDoubleRailPassingStation(tile, direction, platform_length, industry)
{
	if (!AITile.IsBuildable(tile)) return false;
	local test = AITestMode();
	local vector = null, rvector = null;
	local reverse = false;
	local station_is_first_place = true;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	// Determine whether we're building a flipped station
	local src_x, src_y, dst_x, dst_y, ps_x, ps_y;
	src_x = AIMap.GetTileX(tile);
	src_y = AIMap.GetTileY(tile);
	dst_x = AIMap.GetTileX(srcplace);
	dst_y = AIMap.GetTileY(srcplace);
	// Set the direction vectors
	switch (direction) {
		case DIR_NW:
			vector = AIMap.GetTileIndex(0, -1);
			rvector = AIMap.GetTileIndex(1, 0);
			stationdir = AIRail.RAILTRACK_NW_SE;
			if (src_x > dst_x) reverse = true;
			break;
		case DIR_NE:
			vector = AIMap.GetTileIndex(-1, 0);
			rvector = AIMap.GetTileIndex(0, 1);
			stationdir = AIRail.RAILTRACK_NE_SW;
			if (src_y > dst_y) reverse = true;
			break;
		case DIR_SW:
			vector = AIMap.GetTileIndex(1, 0);
			rvector = AIMap.GetTileIndex(0, 1);
			stationdir = AIRail.RAILTRACK_NE_SW;
			if (src_y > dst_y) reverse = true;
			break;
		case DIR_SE:
			vector = AIMap.GetTileIndex(0, 1);
			rvector = AIMap.GetTileIndex(1, 0);
			stationdir = AIRail.RAILTRACK_NW_SE;
			if (src_x > dst_x) reverse = true;
			break;
	}
	// Set the top and the bottom tile of the station
	if (direction == DIR_NW || direction == DIR_NE) {
		stabottom = tile;
		statop = tile + (platform_length - 1) * vector;
		statile = statop;
		stapasstile = stabottom;
	} else {
		statop = tile;
		stabottom = tile + (platform_length - 1) * vector;
		statile = stabottom;
		stapasstile = statop;
	}
	staoffset1 = tile + ((platform_length - 1) / 2).tointeger() * vector;
	staoffset2 = tile + ((platform_length + 1) / 2).tointeger() * vector;
	reverse = !reverse;
	if (reverse) {
		rvector = -rvector;
		statile = statile - rvector;
		stapasstile = stapasstile - rvector;
	}

	// Set the tiles for the station parts
	lane2 = statile + rvector;
	front1 = statile;
	front2 = lane2;
	depfront = front1 + vector;
	stafront = front2 + vector;
	deptile = depfront + vector;
	frontfront = stafront + vector;
	morefront = frontfront;
	stavector = vector;
	starvector = rvector;
	staoption = 0;
	// Do the tests
	if (!CheckRailHead(stafront, stavector, starvector)) return false;
	if (!AIRail.BuildRailStation(statop, stationdir, 2, platform_length, AIStation.STATION_NEW)) return false;
	if (industry != null) {
		local station_tile_list = AITileList();
		station_tile_list.AddRectangle(statile, lane2 + (platform_length - 1) * vector);
		local found = false;
		foreach (stile, dummy in station_tile_list) if (AITile.GetCargoAcceptance(stile, extracrg, 1, 1, rad) && MyAIIndustry.IsTileValidForRailStation(stile, industry, false)) {
			found = true;
			break;
		}
		if (!found) return false;
	}
	if (!AITile.IsBuildable(depfront)) return false;
	if (!AITile.IsBuildable(stafront)) return false;
	if (!AIRail.BuildRail(front2, stafront, frontfront)) return false;
	if (!AIRail.BuildRail(front1, depfront, stafront)) return false;
	if (!AIRail.BuildRail(depfront, stafront, frontfront)) return false;
	if (!AITile.IsBuildable(frontfront)) return false;
	if (!CheckRailHead(frontfront, stavector, starvector)) return false;
	passfront1 = stapasstile + rvector;
	passfront2 = stapasstile;
	passdepfront = passfront1 - vector;
	passstafront = passfront2 - vector;
	deppasstile = passdepfront - vector;
	passfrontfront = passstafront - vector;
	passmorefront = passfrontfront;
	if (!CheckRailHead(passstafront, -stavector, -starvector)) return false;
	if (!AITile.IsBuildable(passdepfront)) return false;
	if (!AITile.IsBuildable(passstafront)) return false;
	if (!AIRail.BuildRail(passfront2, passstafront, passfrontfront)) return false;
	if (!AIRail.BuildRail(passfront1, passdepfront, passstafront)) return false;
	if (!AIRail.BuildRail(passdepfront, passstafront, passfrontfront)) return false;
	if (!AITile.IsBuildable(passfrontfront)) return false;
	if (!CheckRailHead(passfrontfront, -stavector, -starvector)) return false;
	test = null;
	LogDebug("Testing if we can build a passing station: Yes, it is possible");
	return true;
}

/**
 * Delete a rail station together with the rail line.
 * Builder class variables used and set:
 * @param sta The StationID of the station to be deleted.
 */
function cBuilder::DeleteRailStation(sta)
{
	if (sta == null || !AIStation.IsValidStation(sta)) return;
	// Don't delete the station if there are trains using it
	local vehiclelist = AIVehicleList_Station(sta);
	if (vehiclelist.Count() > 0) {
		LogError("" + AIStation.GetName(sta) + " cannot be removed, it's still in use!");
		return;
	}
	local place = AIStation.GetLocation(sta);
	if (!AIRail.IsRailStationTile(place)) return;
	// Get the positions of the station parts
	local dir = AIRail.GetRailStationDirection(place);
	local vector = MyAIMap.GetVector(dir);
	local rvector = MyAIMap.GetRVector(dir);
	local twolane = false;
	// Determine if it is a single or a double rail station
	if (AIRail.IsRailStationTile(place + rvector)) {
		local otherstation = AIStation.GetStationID(place + rvector);
		if (AIStation.IsValidStation(otherstation) && otherstation == sta) twolane = true;
	}
	local depfront = null, stafront = place, stabottom = place, depfront = null;
	while (AIRail.IsRailStationTile(stafront) && AIStation.GetStationID(stafront) == sta) stafront -= vector;
	if (!MyAIRail.AreConnectedRailTiles(stafront, stafront + vector)) stafront = null;
	while (AIRail.IsRailStationTile(stabottom) && AIStation.GetStationID(stabottom) == sta) stabottom += vector;
	if (!MyAIRail.AreConnectedRailTiles(stabottom - vector, stabottom)) stabottom = null;
	if (twolane) {
		if (stafront != null && MyAIRail.AreConnectedRailTiles(stafront + rvector, stafront + vector + rvector)) depfront = stafront + rvector;
		if (stabottom != null && MyAIRail.AreConnectedRailTiles(stabottom + rvector, stabottom - vector + rvector)) depfront = stabottom + rvector;
	}
	cBuilder.WaitAndDemolish(place);
	// Remove the rail line, including the station parts, and the other station if it is connected
	if (stafront != null) RemoveRailLine(stafront);
	if (depfront != null) RemoveRailLine(depfront);
	if (stabottom != null) RemoveRailLine(stabottom);
}

/**
 * Get the platform length of a route.
 * @param sta1 The StationID of the source station.
 * @param sta2 The StationID of the destination station.
 * @param sta3 The StationID of the passing station (can be null).
 * @return The length of the station's platform in tiles.
 */
function cBuilder::GetRailRoutePlatformLength(sta1, sta2, sta3 = null)
{
	if (sta3 == null) return MyMath.Min(MyAIRail.GetRailStationPlatformLength(sta1), MyAIRail.GetRailStationPlatformLength(sta2));
	else return MyMath.Min(cBuilder.GetRailRoutePlatformLength(sta1, sta2),MyAIRail.GetRailStationPlatformLength(sta3));
}

/**
 * Check if an industry is connected to station.
 * @param ind The industry ID.
 * @param sta The station ID.
 * @param is_source If its source or destination station.
 * @return True if they are connected.
 */
function cBuilder::IsIndustryConnectedToSourceStation(ind, sta)		{ return cBuilder.IsIndustryConnectedToStation(ind, sta, true); }
function cBuilder::IsIndustryConnectedToDestinationStation(ind, sta)	{ return cBuilder.IsIndustryConnectedToStation(ind, sta, false); }
function cBuilder::IsIndustryConnectedToStation(ind, sta, is_source)
{
	if (!AIIndustry.IsValidIndustry(ind)) return false;
	local stiles = MyAIRail.GetRailStationTiles(sta);
	if (stiles.Count() == 0) return false;
	foreach (idx, stile in stiles) if (stile != null && MyAIIndustry.IsTileValidForStation(stile, ind, AIStation.GetStationCoverageRadius(sta), is_source)) return true;
	return false;
}

/**
 * Swap the variables of destination stations (for dual cargo trains).
 */
function cBuilder::SwapDestinationStationVars()
{
	local tmp = crg;
	crg = extracrg;
	extracrg = tmp;
	tmp = dst;
	dst = extra_dst;
	extra_dst = tmp;
	tmp = passplace;
	passplace = dstplace;
	dstplace = tmp;
}

/**
 * Build a NewGRF or standard rail station, if we have money.
 * Builder class variables used: srcistown, dstistown.
 * @param tile Place to build the station.
 * @param direction The direction to build the station.
 * @param num_platforms The number of platforms to build.
 * @param platform_length The length of each platform.
 * @param station_id The station to join, AIStation::STATION_NEW or AIStation::STATION_JOIN_ADJACENT.
 * @param cargo_id The CargoID of the cargo that will be transported from / to this station.
 * @param source_industry The IndustryType of the industry you'll transport goods from, AIIndustryType::INDUSTRYTYPE_UNKNOWN or AIIndustryType::INDUSTRYTYPE_TOWN.
 * @param goal_industry The IndustryType of the industry you'll transport goods to, AIIndustryType::INDUSTRYTYPE_UNKNOWN or AIIndustryType::INDUSTRYTYPE_TOWN.
 * @param distance The manhattan distance you'll transport the cargo over.
 * @param source_station True if this is the source station, false otherwise.
 * @return Whether the station has been/can be build or not.
 */
function cBuilder::WaitAndBuildNewGRFRailStation(tile, direction, num_platforms, platform_length, station_id, cargo_id, source_industry, goal_industry, distance, source_station)
{
	if (!cBuilder.WaitForMoney(MyAIRail.GetRailStationCost(tile, direction, num_platforms, platform_length, station_id))) return false;
	if (AISettings.UseNewGRFStations() && (!srcistown || !dstistown)) {
		return AIRail.BuildNewGRFRailStation(tile, direction, num_platforms, platform_length, station_id, cargo_id, source_industry, goal_industry, distance, source_station);
	} else {
		return AIRail.BuildRailStation(tile, direction, num_platforms, platform_length, station_id);
	}
}

