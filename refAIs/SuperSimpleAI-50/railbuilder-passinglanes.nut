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
 * Build or check a passing lane section between the current source and destination.
 * Builder class variables used: stasrc, stadst, srcplace, passplace, dstplace.
 * @param source The source location.
 * @param destination The destination location.
 * @param num_lanes Number of passing lanes pending to build.
 * @param lane_length The length of passing lane.
 * @param fake_passinglane True if isn't a passing lane, only a check point.
 * @param tested_tile The tile tested before.
 * @return Two heads, two forbidden tiles and two tiles from the center if the passing lane can be build, null if can't.
 */
function cBuilder::CheckPassingLaneSection(source, destination, num_lanes, lane_length, fake_passinglane)			{ return cBuilder.BuildOrCheckPassingLaneSection(source, destination, num_lanes, lane_length, fake_passinglane, true, null); }
function cBuilder::BuildPassingLaneSection(source, destination, num_lanes, lane_length, fake_passinglane, tested_tile = null)	{ return cBuilder.BuildOrCheckPassingLaneSection(source, destination, num_lanes, lane_length, fake_passinglane, false, tested_tile); }
function cBuilder::BuildOrCheckPassingLaneSection(source, destination, num_lanes, lane_length, fake_passinglane, check_build, tested_tile)
{
	// Determine what signal type to use
        local signaltype = AISettings.GetSignalType();
        if (signaltype == AIRail.SIGNALTYPE_PBS_ONEWAY) lane_length--;;
        lane_length += 2;
	local startvectors = (lane_length / 2).tointeger();
	local centralvectors, startingvectors, endingvectors, centralrvectors, startingrvectors, endingrvectors, allrvectors;
	local tilelist, centre, ps_x, ps_y, dist_x, dist_y;
	local end = [[], [], [], [], []];
	end[0] = [null, null]; end[1] = [null, null]; end[2] = [null, null]; end[3] = [null, null], end[4] = [null, null];
	local reverse = false, success = false, diagonal_start = false, diagonal_end = false, diagonal_centre = false, prefer_diagonal = false, option1 = false, passing_type = 1;
	// Get the direction of the passing lane section
	local src_x = AIMap.GetTileX(source[0]);
	local src_y = AIMap.GetTileY(source[0]);
	local dst_x = AIMap.GetTileX(destination[0]);
	local dst_y = AIMap.GetTileY(destination[0]);
	local dir = MyAIRail.GetRailDirection(MyAIMap.GetDirection(srcplace, passplace == null ? dstplace : passplace));
	// Get the direction vectors
	local vector = MyAIMap.GetVector(dir);
	local rvector = MyAIMap.GetRVector(dir);
	// Determine whether we're building a flipped passing lane section
	if ((!(dst_x > src_x) && (dst_y > src_y)) || ((dst_x > src_x) && !(dst_y > src_y))) reverse = true;
	if (reverse) rvector = -rvector;
	// Propose a place for the passing lane section, it is num_lanes/(num_lanes + 1) on the line between the two stations
	ps_x = ((num_lanes * src_x + dst_x) / (num_lanes + 1)).tointeger();
	ps_y = ((num_lanes * src_y + dst_y) / (num_lanes + 1)).tointeger();
	// Get a tile list around the proposed place
	local tile = null;
	local lastZ = AITile.GetMaxHeight(source[0]);
	local nextZ = AITile.GetMaxHeight(destination[0]);
	local use_bridges = true;
	tilelist = AITileList();
	centre = AIMap.GetTileIndex(ps_x, ps_y);
	tilelist.AddRectangle(centre - AIMap.GetTileIndex(20, 20), centre + AIMap.GetTileIndex(20, 20));
	tilelist.Valuate(AIMap.DistanceManhattan, centre);
	if (tested_tile != null && tilelist.HasItem(tested_tile)) tilelist.SetValue(tested_tile,-1);
	tilelist.Sort(AIList.SORT_BY_VALUE, true);
	if (src_x > dst_x) dist_x = src_x - dst_x; else dist_x = dst_x - src_x;
	if (src_y > dst_y) dist_y = src_y - dst_y; else dist_y = dst_y - src_y;
	if ((dist_x > dist_y && 2 * dist_y > dist_x) || (dist_y > dist_x && 2 * dist_x > dist_y)) prefer_diagonal = true;
	// Find a place where the passing lane section can be built
	foreach (itile, dummy in tilelist) {
		if (prefer_diagonal && cBuilder.CheckHeightDifference(AITile.GetMaxHeight(itile), lastZ, nextZ, num_lanes)) {
			if (CanBuildDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				passing_type = 1;
				break;
			}
			if (CanBuildDiagonalRasNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_centre = true;
				passing_type = 6;
				break;
			}
			if (CanBuildNormalRasDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				diagonal_end = true;
				passing_type = 6;
				break;
			}
			if (CanBuildDiagonalNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_end = true;
				passing_type = 3;
				break;
			}
			if (CanBuildDiagonalDiagonalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_centre = true;
				passing_type = 3;
				break;
			}
			if (CanBuildNormalDiagonalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				diagonal_end = true;
				passing_type = 3;
				break;
			}
			if (CanBuildNormalRasNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				passing_type = 6;
				break;
			}
			if (CanBuildDiagonalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 2;
				break;
			}
			if (CanBuildNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 2;
				break;
			}
			if (CanBuildDiagonalFatDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_end = true;
				passing_type = 6;
				break;
			}
			if (CanBuildNormalDiagonalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				passing_type = 3;
				break;
			}
			if (CanBuildDiagonalDoubleNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 5;
				break;
			}
			if (CanBuildDoubleNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 4;
				break;
			}
			if (CanBuildDiagonalNormalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 3;
				break;
			}
			if (CanBuildNormalNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 3;
				break;
			}
			if (CanBuildDoubleFatDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 8;
				break;
			}
			if (CanBuildDiagonalDoubleFatPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 7;
				break;
			}
		}
		if (cBuilder.CheckHeightDifference(AITile.GetMaxHeight(itile - startvectors * vector), lastZ, nextZ, num_lanes)) {
			if (CanBuildNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				passing_type = 1;
				break;
			}
			if (CanBuildDoublePassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				passing_type = 2;
				break;
			}
			if (CanBuildTriple13PassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				passing_type = 4;
				break;
			}
			if (CanBuildTriple23PassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				passing_type = 5;
				break;
			}
			if (CanBuildTriplePassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				passing_type = 3;
				break;
			}
		}
		if (!prefer_diagonal && cBuilder.CheckHeightDifference(AITile.GetMaxHeight(itile), lastZ, nextZ, num_lanes)) {
			if (CanBuildDoubleFatDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 8;
				break;
			}
			if (CanBuildDiagonalDoubleFatPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 7;
				break;
			}
			if (CanBuildDoubleNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 4;
				break;
			}
			if (CanBuildDiagonalDoubleNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 5;
				break;
			}
			if (CanBuildNormalNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 3;
				break;
			}
			if (CanBuildDiagonalNormalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 3;
				break;
			}
			if (CanBuildNormalDiagonalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				passing_type = 3;
				break;
			}
			if (CanBuildDiagonalFatDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_end = true;
				passing_type = 6;
				break;
			}
			if (CanBuildNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_end = true;
				passing_type = 2;
				break;
			}
			if (CanBuildDiagonalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				passing_type = 2;
				break;
			}
			if (CanBuildNormalRasNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				passing_type = 6;
				break;
			}
			if (CanBuildNormalDiagonalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				diagonal_end = true;
				passing_type = 3;
				break;
			}
			if (CanBuildDiagonalDiagonalNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_centre = true;
				passing_type = 3;
				break;
			}
			if (CanBuildDiagonalNormalDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_end = true;
				passing_type = 3;
				break;
			}
			if (CanBuildNormalRasDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				diagonal_end = true;
				passing_type = 6;
				break;
			}
			if (CanBuildDiagonalRasNormalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_start = true;
				diagonal_centre = true;
				passing_type = 6;
				break;
			}
			if (CanBuildDiagonalPassingLaneSection(itile, dir, reverse, lane_length, use_bridges, fake_passinglane)) {
				success = true;
				tile = itile;
				diagonal_centre = true;
				passing_type = 1;
				break;
			}
		}
		continue;
	}
	startingvectors = GetNumStartingTiles(lane_length - 1, passing_type);
	startingrvectors = (diagonal_start) ? startingvectors : 0;
	centralvectors = GetNumCentralTiles(lane_length - 1, passing_type);
	centralrvectors = (diagonal_centre) ? centralvectors : 0;
	endingvectors = GetNumEndingTiles(lane_length - 1, passing_type);
	endingrvectors = (diagonal_end) ? endingvectors : 0;
	allrvectors = centralrvectors + startingrvectors + endingrvectors;
	if (!success) return null;
	if (check_build) {
		end[0] = [tile, tile + rvector];
		return end;
	}
	// Build the passing lane section
	local headtiles = 0;
	local need_tmp_depot = false;
	centre = tile;
	if (!fake_passinglane) {
		tile = centre - (startingvectors + (centralvectors / 2).tointeger()) * vector - (allrvectors / 2).tointeger() * rvector;
		local deptile = tile - vector + rvector;
		if (!CheckRailHead(tile, -vector, -rvector)) {
			headtiles = BuildRailHead(tile, -rvector, -vector);
			if (headtiles == null) return null;
			end[0] = [tile - (headtiles + 1) * rvector, tile - headtiles * rvector];
			success = success && WaitAndBuildRail(tile - rvector, tile, tile + vector);
			deptile = tile + vector - rvector;
			need_tmp_depot = MyAIRail.CanBuildRail(tile, tile - rvector, deptile);
			option1 = true;
		} else {
			headtiles = BuildRailHead(tile, -vector, -rvector);
			if (headtiles == null) return null;
			success = success && WaitAndBuildRail(tile - vector, tile, tile + vector);
			end[0] = [tile - (headtiles + 1) * vector, tile - headtiles * vector];
			deptile = tile - vector + rvector;
			need_tmp_depot = MyAIRail.CanBuildRail(tile, tile - vector, deptile);
		}
		if (need_tmp_depot && headtiles == 0) end[2] = [deptile, deptile + vector];
		tile += vector;
		if (diagonal_start) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, startingvectors, false, reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, startingvectors, false);
			if (!AISettings.IsSignalTypePBS()) success = success && AIRail.BuildSignal(centre - (startvectors - 1) * vector, centre - startvectors * vector, signaltype);
		}
		tile += startingvectors * vector + startingrvectors * rvector;
		if (diagonal_centre) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, centralvectors, false, reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, centralvectors, false);
		}
		tile += centralvectors * vector + centralrvectors * rvector;
		if (diagonal_end) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, endingvectors, false, reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, endingvectors, false);
		}
		tile += endingvectors * vector + endingrvectors * rvector;
		success = success && WaitAndBuildRail(tile - vector, tile, tile + rvector);
		success = success && AIRail.BuildSignal(tile, tile - vector, signaltype);
		tile = centre + (endingvectors + (centralvectors - (centralvectors / 2).tointeger()) + 1) * vector + (allrvectors - (allrvectors / 2).tointeger() + 1) * rvector;
		if (success) {
			if (!CheckRailHead(tile, vector, rvector)) {
				success = success && WaitAndBuildRail(tile - rvector, tile, tile  + rvector);
				success = success && WaitAndBuildRail(tile - vector, tile, tile + rvector);
				headtiles = BuildRailHead(tile, rvector, vector);
				if (headtiles == null) return null;
				end[1] = [tile + (headtiles + 1) * rvector, tile + headtiles * rvector];
				deptile = tile - vector + rvector;
				need_tmp_depot = MyAIRail.CanBuildRail(tile, tile + rvector, deptile);
			} else {
				success = success && WaitAndBuildRail(tile - rvector, tile, tile + vector);
				success = success && WaitAndBuildRail(tile + vector, tile, tile - vector);
				headtiles = BuildRailHead(tile, vector, rvector);
				if (headtiles == null) return null;
				end[1] = [tile + (headtiles + 1) * vector, tile + headtiles * vector];
				deptile = tile + vector - rvector;
				need_tmp_depot = MyAIRail.CanBuildRail(tile, tile + vector, deptile);
			}
			if (need_tmp_depot && headtiles == 0) end[3] = [deptile, deptile - vector];
			end[4] = [centre, centre + rvector];
		}
		tile -= vector;
		if (diagonal_end) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, endingvectors, true, !reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, endingvectors, true);
			if (!AISettings.IsSignalTypePBS()) success = success && AIRail.BuildSignal(centre + rvector + (lane_length - startvectors - 1) * vector, centre + rvector + (lane_length - startvectors) * vector, signaltype);
		}
		tile -= endingvectors * vector + endingrvectors * rvector;
		if (diagonal_centre) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, centralvectors, true, !reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, centralvectors, true);
		}
		tile -= centralvectors * vector + centralrvectors * rvector;
		if (diagonal_start) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, startingvectors, true, !reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, startingvectors, true);
		}
		tile -= startingvectors * vector + startingrvectors * rvector;
		success = success && WaitAndBuildRail(tile + vector, tile, tile - rvector);
		success = success && AIRail.BuildSignal(tile, tile + vector, signaltype);
		if (option1) success = success && WaitAndBuildRail(tile, tile - rvector, tile - rvector - rvector);
		else success = success && WaitAndBuildRail(tile, tile - rvector, tile - rvector - vector);

	} else {
		tile = centre - (startingvectors + (centralvectors / 2).tointeger()) * vector - (allrvectors / 2).tointeger() * rvector;
		local deptile = tile - vector;
		headtiles = BuildRailHead(tile, -vector, -rvector);
		if (headtiles == null) return null;
		end[0] = [tile - (headtiles + 1) * vector, tile - headtiles * vector];
		need_tmp_depot = MyAIRail.CanBuildRail(deptile + rvector, deptile, deptile + vector);
		if (need_tmp_depot && headtiles == 0) end[2] = [deptile + rvector, deptile + rvector + vector];
		if (diagonal_start) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, startingvectors, false, reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, startingvectors, false);
		}
		tile += startingvectors * vector + startingrvectors * rvector;
		if (diagonal_centre) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, centralvectors, false, reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, centralvectors, false);
		}
		tile += centralvectors * vector + centralrvectors * rvector;
		if (diagonal_end) {
			success = success && BuildDiagonalTracksOnPassingLane(tile, dir, endingvectors, false, reverse);
		} else {
			success = success && BuildNormalTracksOnPassingLane(tile, dir, endingvectors, false);
		}
		tile += endingvectors * vector + endingrvectors * rvector;
		if (success) {
			headtiles = BuildRailHead(tile - vector, vector, rvector);
			if (headtiles == null) return null;
			end[1] = [tile + headtiles * vector, tile + (headtiles - 1) * vector];
			deptile = tile - rvector;
			need_tmp_depot = MyAIRail.CanBuildRail(tile - vector, tile, deptile);
			if (need_tmp_depot && headtiles == 0) end[3] = [deptile, deptile - vector];
			end[4] = [centre, centre + rvector];
		}
	}
	if (!success) {
		LogWarning("Passing lane construction was interrupted.");
		RemoveRailLine(end[0][1]);
		RemoveRailLine(end[1][1]);
		return null;
	}
	return end;
}

/**
 * Chech the difference of height between a tile, last and next tiles (passing lanes or stations).
 * @param tile The height of a tile where to build a passing lane.
 * @param lastZ The height of last passing lane or station.
 * @param nextZ The height of next passing lane or station.
 * @param num_lanes Number of passing lanes pending to build.
 * @return True if the difference is between the limits.
 */
function cBuilder::CheckHeightDifference(tile, lastZ, nextZ, num_lanes)
{
	local maxZ = AISettings.MaxDiffPassingLaneHeigh();
	return (!(tile > lastZ && tile - lastZ > maxZ) && !(tile < lastZ && lastZ - tile > maxZ) && !(tile > nextZ && tile - nextZ > maxZ * num_lanes) && !(tile < nextZ && nextZ - tile > maxZ * num_lanes));
}

/**
 * Determine whether a diagonal passing lane section can be built at a given position.
 * @param centre The centre tile of the proposed passing lane section.
 * @param direction The direction of the proposed passing lane section.
 * @param reverse True if we are trying to build a flipped passing lane section.
 * @param lane_length The length of passing lane.
 * @param use_bridges Boolean, use tunnels or bridges if it is required.
 * @param fake_passinglane True for one-way fake passinglane.
 * @return True if a passing lane section can be built.
 */
function cBuilder::CanBuildNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)			{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 1, false, false, false); }
function cBuilder::CanBuildDoublePassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)			{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 2, false, false, false); }
function cBuilder::CanBuildTriplePassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)			{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 3, false, false, false); }
function cBuilder::CanBuildTriple13PassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)			{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 4, false, false, false); }
function cBuilder::CanBuildTriple23PassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)			{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 5, false, false, false); }
function cBuilder::CanBuildNormalNormalDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 3, false, false, true); }
function cBuilder::CanBuildDiagonalNormalNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 3, true, false, false); }
function cBuilder::CanBuildDoubleNormalDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 4, false, false, true); }
function cBuilder::CanBuildDoubleFatDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)		{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 8, false, false, true); }
function cBuilder::CanBuildDiagonalDoubleNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 5, true, false, false); }
function cBuilder::CanBuildDiagonalDoubleFatPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)		{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 7, true, false, false); }
function cBuilder::CanBuildNormalDiagonalNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 3, false, true, false); }
function cBuilder::CanBuildNormalRasNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)		{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 6, false, true, false); }
function cBuilder::CanBuildNormalDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)		{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 2, false, false, true); }
function cBuilder::CanBuildDiagonalNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)		{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 2, true, false, false); }
function cBuilder::CanBuildDiagonalNormalDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 3, true, false, true); }
function cBuilder::CanBuildDiagonalFatDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 6, true, false, true); }
function cBuilder::CanBuildDiagonalDiagonalNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 3, true, true, false); }
function cBuilder::CanBuildDiagonalRasNormalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)		{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 6, true, true, false); }
function cBuilder::CanBuildNormalDiagonalDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)	{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 3, false, true, true); }
function cBuilder::CanBuildNormalRasDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)		{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 6, false, true, true); }
function cBuilder::CanBuildDiagonalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane)			{ return cBuilder.CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, 1, false, true, false); }
/**
 * @param divisions Number of segments to build.
 */
function cBuilder::CanBuildUniversalPassingLaneSection(centre, direction, reverse, lane_length, use_bridges, fake_passinglane, divisions, startdiagonal, centraldiagonal, enddiagonal)
{
	if ((divisions > 1 && lane_length < 5) || (divisions > 2 && lane_length < 7) || (divisions > 5 && lane_length < 9) || (divisions == 1 && !centraldiagonal && !AISettings.IsSignalTypePBS())) return false;
	lane_length--;
	local centralvectors = GetNumCentralTiles(lane_length, divisions);
	local centralrvectors = (centraldiagonal) ? centralvectors : 0;
	local startingvectors = GetNumStartingTiles(lane_length, divisions);
	local startingrvectors = (startdiagonal) ? startingvectors : 0;
	local endingvectors = GetNumEndingTiles(lane_length, divisions);
	local endingrvectors = (enddiagonal) ? endingvectors : 0
	local allrvectors = centralrvectors + startingrvectors + endingrvectors;
	// Get the direction vectors
	local vector = MyAIMap.GetVector(direction);
	local rvector = MyAIMap.GetRVector(direction);
	if (reverse) rvector = -rvector;
	local tile = centre - (startingvectors + (centralvectors / 2).tointeger()) * vector - (allrvectors / 2).tointeger() * rvector;
	// Do the tests
	if (!fake_passinglane) {
		if (startdiagonal) {
			if ((!MyAIRail.CanBuildRailDepot(tile, tile + rvector) || !MyAIRail.CanBuildRailDepot(tile, tile - rvector)) && (!MyAIRail.CanBuildRailDepot(tile, tile + vector) || !MyAIRail.CanBuildRailDepot(tile, tile - vector))) return false;
			if (!CanBuildDiagonalPassingLaneHead(tile, direction, false, reverse)) return false;
			tile += vector;
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, startingvectors, false, reverse, use_bridges)) return false;
		} else {
			if (!MyAIRail.CanBuildRailDepot(tile, tile + vector) || !MyAIRail.CanBuildRailDepot(tile, tile - vector)) return false;
			if (!CanBuildNormalPassingLaneHead(tile, direction, false, reverse)) return false;
			tile += vector;
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, startingvectors, false, use_bridges)) return false;
		}
		tile += startingvectors * vector + startingrvectors * rvector;
		if (centraldiagonal) {
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, centralvectors, false, reverse, use_bridges)) return false;
		} else {
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, centralvectors, false, use_bridges)) return false;
		}
		tile += centralvectors * vector + centralrvectors * rvector;
		if (enddiagonal) {
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, endingvectors, false, reverse, use_bridges)) return false;
		} else {
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, endingvectors, false, use_bridges)) return false;
		}
		tile += endingvectors * vector + endingrvectors * rvector;
		if (!AITile.IsBuildable(tile) || !MyAIRail.CanBuildRail(tile - vector, tile, tile + rvector)) return false;
		tile = centre + (endingvectors + (centralvectors - (centralvectors / 2).tointeger() + 1)) * vector + (allrvectors - (allrvectors / 2).tointeger() + 1) * rvector;
		if (enddiagonal) {
			if ((!MyAIRail.CanBuildRailDepot(tile, tile + rvector) || !MyAIRail.CanBuildRailDepot(tile, tile - rvector)) && (!MyAIRail.CanBuildRailDepot(tile, tile + vector) || !MyAIRail.CanBuildRailDepot(tile, tile - vector))) return false;
			if (!CanBuildDiagonalPassingLaneHead(tile, direction, true, !reverse)) return false;
			tile -= vector;
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, endingvectors, true, !reverse, use_bridges)) return false;
		} else {
			if (!MyAIRail.CanBuildRailDepot(tile, tile + vector) || !MyAIRail.CanBuildRailDepot(tile, tile - vector)) return false;
			if (!CanBuildNormalPassingLaneHead(tile, direction, true, !reverse)) return false;
			tile -= vector;
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, endingvectors, true, use_bridges)) return false;
		}
		tile -= endingvectors * vector + endingrvectors * rvector;
		if (centraldiagonal) {
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, centralvectors, true, !reverse, use_bridges)) return false;
		} else {
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, centralvectors, true, use_bridges)) return false;
		}
		tile -= centralvectors * vector + centralrvectors * rvector;
		if (startdiagonal) {
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, startingvectors, true, !reverse, use_bridges)) return false;
		} else {
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, startingvectors, true, use_bridges)) return false;
		}
		tile -= startingvectors * vector + startingrvectors * rvector;
		if (!AITile.IsBuildable(tile) || !MyAIRail.CanBuildRail(tile + vector, tile, tile - rvector)) return false;
	} else {
		if (!CanBuildNormalPassingLaneHead(tile, direction, false, reverse)) return false;
		if (startdiagonal) {
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, startingvectors, false, reverse, use_bridges)) return false;
		} else {
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, startingvectors, false, use_bridges)) return false;
		}
		tile += startingvectors * vector + startingrvectors * rvector;
		if (centraldiagonal) {
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, centralvectors, false, reverse, use_bridges)) return false;
		} else {
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, centralvectors, false, use_bridges)) return false;
		}
		tile += centralvectors * vector + centralrvectors * rvector;
		if (enddiagonal) {
			if (!CanBuildDiagonalTracksOnPassingLane(tile, direction, endingvectors, false, reverse, use_bridges)) return false;
		} else {
			if (!CanBuildNormalTracksOnPassingLane(tile, direction, endingvectors, false, use_bridges)) return false;
		}
		tile += endingvectors * vector + endingrvectors * rvector;
		if (!CanBuildNormalPassingLaneHead(tile - vector, direction, true, !reverse)) return false;
	}
	return true;
}

/**
 * Determine whether a normal passing lane section can be built at a given position.
 * @param tile The tile of the proposed passing lane head.
 * @param direction The direction.
 * @param reverse Boolean, if true vector = -vector.
 * @param flipped Boolean, if true rvector = -rvector.
 * @return True if a passing lane head can be built.
 */
function cBuilder::CanBuildNormalPassingLaneHead(tile, direction, reverse, flipped)
{
	local test = AITestMode();
	local vector = (reverse) ? -MyAIMap.GetVector(direction) : MyAIMap.GetVector(direction);
	local rvector = (flipped) ? -MyAIMap.GetRVector(direction) : MyAIMap.GetRVector(direction);
	if (!CheckRailHead(tile, -vector, -rvector)) return false;
	if (!AIRail.BuildRail(tile - vector, tile, tile + rvector)) return false;
	if (!AIRail.BuildRail(tile, tile + rvector, tile + vector + rvector)) return false;
	if (!AIRail.BuildRailStation(tile, direction, 1, 1, AIStation.STATION_NEW)) return false;
	test = null;
	return true;
}

/**
 * Determine whether a diagonal passing lane section can be built at a given position.
 * @param tile The tile of the proposed passing lane head.
 * @param direction The direction.
 * @param reverse Boolean, if true vector = -vector.
 * @param flipped Boolean, if true rvector = -rvector.
 * @param only_normal Boolean, if true only normal head is tested..
 * @return True if a passing lane head can be built.
 */
function cBuilder::CanBuildDiagonalPassingLaneHead(tile, direction, reverse, flipped, only_normal = false)
{
	local test = AITestMode();
	local vector = (reverse) ? -MyAIMap.GetVector(direction) : MyAIMap.GetVector(direction);
	local rvector = (flipped) ? -MyAIMap.GetRVector(direction) : MyAIMap.GetRVector(direction);
	if (!CheckRailHead(tile, -vector, -rvector)) {
		if (!CheckRailHead(tile, -rvector, -vector)) return false;
		if (!AIRail.BuildRail(tile - rvector, tile, tile + vector)) return false;
		if (!AIRail.BuildRailStation(tile, MyAIRail.GetPerpendicular(direction), 1, 1, AIStation.STATION_NEW)) return false;
	} else {
		if (only_normal) return false;
		if (!AIRail.BuildRail(tile - vector, tile, tile + rvector)) return false;
		if (!AIRail.BuildRailStation(tile, direction, 1, 1, AIStation.STATION_NEW)) return false;
	}
	if (!AIRail.BuildRail(tile, tile + rvector, tile + vector + rvector)) return false;
	test = null;
	return true;
}

/**
 * Determine whether a non-diagonal track can be built at a given position.
 * @param tile Start tile.
 * @param direction The direction of passing lane.
 * @param len The lenght of this section.
 * @param reverse Boolean, if true vector = -vector.
 * @param use_bridges Boolean, use tunnels or bridges if it is required.
 * @return True if is buildable.
 */
function cBuilder::CanBuildNormalTracksOnPassingLane(tile, direction, len, reverse, use_bridges)
{
	local test = AITestMode();
	local vector = (reverse) ? -MyAIMap.GetVector(direction) : MyAIMap.GetVector(direction);
	local upslope = false;
	local bridgestart = null;
	local tunnelstart = null;
	for (local x = 0; x < len; x++) {
		if (AISettings.IsFlatLane()) {
			if (!(MyAITile.IsFlatTile(tile) && AITile.IsBuildable(tile) && AIRail.BuildRail(tile - vector, tile, tile + vector) || AIRail.BuildRailStation(tile, direction, 1, 1, AIStation.STATION_NEW))) {
				if (bridgestart == null && tunnelstart == null && MyAITile.IsDownslopeTile(tile, -vector)) tunnelstart = tile; 
				if (bridgestart == null && tunnelstart == null && MyAITile.IsDownslopeTile(tile, vector)) bridgestart = tile; 
				if (bridgestart == null && tunnelstart == null) return false;
			} else {
				if (!use_bridges && !MyAITile.IsFlatTile(tile)) return false;
			}
			if (!AITile.IsBuildable(tile + vector) && bridgestart == null && tunnelstart == null) {
				bridgestart = tile;
				upslope = true;
			}
		} else {
			if (!AITile.IsBuildable(tile)) return false;
			if (!AIRail.BuildRail(tile - vector, tile, tile + vector)) return false;
		}
		tile += vector;
	}
	local othertile = tile - vector;
	local bridgeend = null;
	local tunnelend = null;
	if (bridgestart != null || tunnelstart != null) {
		for (local x = len; x > 0; x--) {
			if (AISettings.IsFlatLane()) {
				if (!(MyAITile.IsFlatTile(othertile) && AITile.IsBuildable(othertile) && AIRail.BuildRail(othertile - vector, othertile, othertile + vector) || AIRail.BuildRailStation(othertile, direction, 1, 1, AIStation.STATION_NEW))) {
					if (tunnelstart != null && bridgeend == null && tunnelend == null && MyAITile.IsDownslopeTile(othertile, vector)) tunnelend = othertile;
					if (bridgestart != null && bridgeend == null && tunnelend == null && MyAITile.IsDownslopeTile(othertile, -vector)) bridgeend = othertile;
					if (bridgeend == null && tunnelend == null) return false;
				} else {
					if (!use_bridges && !MyAITile.IsFlatTile(othertile)) return false;
				}
				if (upslope && !AITile.IsBuildable(othertile - vector) && bridgeend == null && tunnelend == null && tunnelstart == null) bridgeend = othertile;
			} else {
				if (!AITile.IsBuildable(othertile)) return false;
				if (!AIRail.BuildRail(othertile - vector, othertile, othertile + vector)) return false;
			}
			othertile -= vector;
		}
	}
	if (bridgeend != null) {
		if (!use_bridges || AISettings.IsOldStyleRailLine()) return false;
		if (!cBuilder.CanBuildRailBridge(bridgestart, bridgeend)) return false;
	}
	if (tunnelend != null) {
		if (!use_bridges || AISettings.IsOldStyleRailLine()) return false;
		if (!cBuilder.CanBuildRailTunnel(tunnelstart, tunnelend)) return false;
	}
	if (!MyAIRail.CanBuildRailDepot(tile, tile - vector) && !MyAIRail.CanBuildRailDepot(tile, tile + vector)) return false;
	test = null;
	return true;
}

/**
 * Determine whether a non-diagonal track can be built at a given position.
 * @param tile Start tile.
 * @param direction The direction of passing lane.
 * @param len The lenght of this section.
 * @param reverse Boolean, if true vector = -vector.
 * @return True if is buildable.
 */
function cBuilder::BuildNormalTracksOnPassingLane(tile, direction, len, reverse)
{
	local vector = (reverse) ? -MyAIMap.GetVector(direction) : MyAIMap.GetVector(direction);
	local upslope = false;
	local bridgestart = null;
	local tunnelstart = null;
	local railpending = 0;
	local success = true;
	for (local x = 0; x < len; x++) {
		if (AISettings.IsFlatLane()) {
			if (MyAITile.IsDownslopeTile(tile, -vector) && bridgestart == null && tunnelstart == null) tunnelstart = tile;
			if (MyAITile.IsDownslopeTile(tile, vector) && bridgestart == null && tunnelstart == null) bridgestart = tile;
		}
		if (!AITile.IsBuildable(tile + vector) && bridgestart == null && tunnelstart == null) {
			bridgestart = tile;
			upslope = true;
		}
		if (AISettings.FastRailBuild()) {
			if (bridgestart == null && tunnelstart == null) railpending++;
		} else {
			if (bridgestart == null && tunnelstart == null) success = success && WaitAndBuildRail(tile - vector, tile, tile + vector);
		}
		tile += vector;
	}
	if (railpending > 0) success = success && WaitAndBuildRail(tile - (len + 1) * vector, tile - len * vector, tile + (railpending - len) * vector);
	railpending = 0;
	local othertile = tile - vector;
	local bridgeend = null;
	local tunnelend = null;
	if (success && (bridgestart != null || tunnelstart != null)) {
		for (local x = len; x > 0; x--) {
			if (AISettings.IsFlatLane()) {
				if (MyAITile.IsDownslopeTile(othertile, vector) && bridgeend == null && tunnelend == null) {
					tunnelend = othertile;
					x = 0;
				}
				if (MyAITile.IsDownslopeTile(othertile, -vector) && bridgeend == null && tunnelend == null) {
					bridgeend = othertile;
					x = 0;
				}
			}
			if (upslope && !AITile.IsBuildable(othertile - vector) && bridgeend == null && tunnelend == null) {
				bridgeend = othertile;
				x = 0;
			}
			if (bridgeend == null && tunnelend == null) railpending++;
			othertile -= vector;
		}
	}
	if (bridgeend != null) success = success && WaitAndBuildRailBridge(bridgestart, bridgeend);
	if (tunnelend != null) success = success && WaitAndBuildRailTunnel(tunnelstart, tunnelend);
	if (AISettings.FastRailBuild()) {
		if (railpending > 0) success = success && WaitAndBuildRail(othertile + vector, othertile + 2 * vector, othertile + 2 * vector + railpending * vector);
	} else {
		for (local x = 1; x <= railpending; x++) success = success && WaitAndBuildRail(othertile + x * vector, othertile + vector + x * vector, othertile + 2 * vector + x * vector);
	}
	return success;
}

/**
 * Build diagonal tracks.
 * @param tile Start tile.
 * @param direction The direction of passing lane.
 * @param len The lenght of this section.
 * @param reverse Boolean, if true vector = -vector.
 * @param flipped Boolean, if true rvector = -rvector.
 * @return True if is buildable.
 */
function cBuilder::BuildDiagonalTracksOnPassingLane(tile, direction, len, reverse, flipped)
{
	local vector = (reverse) ? -MyAIMap.GetVector(direction) : MyAIMap.GetVector(direction);
	local rvector = (flipped) ? -MyAIMap.GetRVector(direction) : MyAIMap.GetRVector(direction);
	local success = true;
	if (AISettings.FastRailBuild()) {
		return WaitAndBuildRail(tile - vector, tile, tile + len * rvector + len * vector);
	} else {
		for (local x = 0; x < len; x++) {
			success = success && WaitAndBuildRail(tile - vector, tile, tile + rvector);
			success = success && WaitAndBuildRail(tile, tile + rvector, tile + rvector + vector);
			tile += vector + rvector;
		}
	}
	return success;
}

/**
 * Determine whether a diagonal track can be built at a given position.
 * @param tile Start tile.
 * @param direction The direction of passing lane.
 * @param len The lenght of this section.
 * @param reverse Boolean, if true vector = -vector.
 * @param flipped Boolean, if true rvector = -rvector.
 * @param use_bridges Boolean, use tunnels or bridges if it is required.
 * @return True if is buildable.
 */
function cBuilder::CanBuildDiagonalTracksOnPassingLane(tile, direction, len, reverse, flipped, use_bridges)
{
	local test = AITestMode();
	local vector = (reverse) ? -MyAIMap.GetVector(direction) : MyAIMap.GetVector(direction);
	local rvector = (flipped) ? -MyAIMap.GetRVector(direction) : MyAIMap.GetRVector(direction);
	for (local x = 0; x < len; x++) {
		if (!AITile.IsBuildable(tile)) return false;
		if (!AITile.IsBuildable(tile + rvector)) return false;
		if (AICompany.IsMine(AITile.GetOwner(tile))) return false;
		if (AICompany.IsMine(AITile.GetOwner(tile + rvector))) return false;
		if (!AIRail.BuildRail(tile - vector, tile, tile + rvector)) return false;
		if (!AIRail.BuildRail(tile, tile + rvector, tile + vector + rvector)) return false;
		tile += vector + rvector;
	}
	test = null;
	return true;
}

/**
 * Determines the length of central of 3 segments of passing lanes.
 * @param len Length of passing lane.
 * @param div Divisor (valid values: 1..8).
 * @return Lenght of central segment of passing lane.
 */
function cBuilder::GetNumCentralTiles(len, div)
{
	if (div == 1) return len;
	if (div == 2 || div == 4 || div == 5 || div > 6) return 0;
	if (div == 6) return len - 4;
	if (len == 6 || len == 8) return 2;
	if (len == 7 || len == 9 || len == 11) return 3;
	if (len == 10 || len == 12 || len == 14) return 4;
	if (len == 13 || len == 15 || len == 17) return 5;
	if (len == 16 || len == 18 || len == 20) return 6;
	if (len == 19 || len == 21 || len == 23) return 7;
	if (len == 22 || len == 24) return 8;
}

/**
 * Determines the length of endings of 3 segments of passing lanes.
 * @param len Length of passing lane.
 * @param div Divisor (valid values: 1..8).
 * @return Lenght of ending segment of passing lane.
 */
function cBuilder::GetNumStartingTiles(len, div)	{ return (div == 2 || div == 4 || div == 5 || div > 6) ? (len - cBuilder.GetNumEndingTiles(len, div)) : cBuilder.GetNumEndingTiles(len, div); }
function cBuilder::GetNumEndingTiles(len, div)
{
	if (div == 1) return 0;
	if (div == 2) return (len / 2).tointeger();
	if (div == 5) return cBuilder.GetNumEndingTiles(len, 3) + cBuilder.GetNumCentralTiles(len, 3);
	if (div == 6 || div == 8) return 2;
	if (div == 7) return len - 2;
	if (len == 6 || len == 7) return 2;
	if (len == 8 || len == 9 || len == 10) return 3;
	if (len == 11 || len == 12 || len == 13) return 4;
	if (len == 14 || len == 15 || len == 16) return 5;
	if (len == 17 || len == 18 || len == 19) return 6;
	if (len == 20 || len == 21 || len == 22) return 7;
	if (len == 23 || len == 24) return 8;
}
