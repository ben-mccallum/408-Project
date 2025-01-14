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
 * Define the MyAIRail class which extends the AIRail functions.
 */
class MyAIRail /* extends AIRail */
{
	/**
	 * Determine whether two tiles are connected with rail directly.
	 * @param tilefrom The first tile to check.
	 * @param tileto The second tile to check.
	 * @return True if the two tiles are connected.
	 */
	static function AreConnectedRailTiles(tilefrom, tileto);

	/**
	 * Check if we can build a piece of rail.
	 * @param from The tile just before the tile to build on.
	 * @param tile The first tile to build on.
	 * @param to The tile just after the last tile to build on.
	 * @return True if is buildable.
	 */
	static function CanBuildRail(from, tile, to);

	/**
	 * Get the cost to build a proposed fragment of rail.
	 * @param from The tile just before the tile to build on.
	 * @param tile The first tile to build on.
	 * @param to The tile just after the last tile to build on.
	 * @return cost of new tracks to build, -1 if is not buildable.
	 */
	static function GetRailCost(from, tile, to);

	/**
	 * Check if we can build a rail depot.
	 * @param tile Place to build the depot.
	 * @param front The tile exactly in front of the depot.
	 * @return True if is buildable.
	 */
	static function CanBuildRailDepot(tile, front);

	/**
	 * Return the depot cost.
	 * @param tile Place to build the station.
	 * @param front The tile exactly in front of the depot.
	 * @return Cost of tunnel, -1 if we can't build it.
	 */
	static function GetRailDepotCost(tile, front);

	/**
	 * Get the rail direction from direction.
	 * @param direction the direction
	 * @return The direction from the first tile to the second tile.
	 */
	static function GetRailDirection(direction);

	/**
	 * Check if we can build a rail station.
	 * @param tile Place to build the station.
	 * @param direction The direction to build the station.
	 * @param num_platforms The number of platforms to build.
	 * @param platform_length The length of each platform.
	 * @param station_id The station to join, AIStation::STATION_NEW or AIStation::STATION_JOIN_ADJACENT.
	 * @return True if is buildable.
	 */
	static function CanBuildRailStation(tile, direction, num_platforms, platform_length, station_id);

	/**
	 * Return the station cost.
	 * @param tile Place to build the station.
	 * @param direction The direction to build the station.
	 * @param num_platforms The number of platforms to build.
	 * @param platform_length The length of each platform.
	 * @param station_id The station to join, AIStation::STATION_NEW or AIStation::STATION_JOIN_ADJACENT.
	 * @return Cost of tunnel, -1 if we can't build it.
	 */
	static function GetRailStationCost(tile, direction, num_platforms, platform_length, station_id);

	/**
	 * Get the perpendicular from direction.
	 * @param direction.
	 */
	static function GetPerpendicular(direction);

	/**
	 * Get the platform length of a station.
	 * @param sta The StationID of the station.
	 * @return The length of the station's platform in tiles.
	 */
	static function GetRailStationPlatformLength(sta);

	/**
	 * Return all station tiles.
	 * @param sta The StationID of the station.
	 * @return An AIList with all station tiles.
	 */
	static function GetRailStationTiles(sta);
}

function MyAIRail::AreConnectedRailTiles(tilefrom, tileto)
{
	// Check some preconditions
	if (!AITile.HasTransportType(tilefrom, AITile.TRANSPORT_RAIL)) return false;
	if (!AITile.HasTransportType(tileto, AITile.TRANSPORT_RAIL)) return false;
	if (!AICompany.IsMine(AITile.GetOwner(tilefrom))) return false;
	if (!AICompany.IsMine(AITile.GetOwner(tileto))) return false;
	if (AIRail.GetRailType(tilefrom) != AIRail.GetRailType(tileto)) return false;
	// Determine the dircetion
	local dirfrom = MyAIMap.GetDirection(tilefrom, tileto);
	local dirto = null;
	// Some magic bitmasks
	local acceptable = [22, 42, 37, 25];
	// Determine the direction pointing backwards
	if (dirfrom == 0 || dirfrom == 2) dirto = dirfrom + 1;
	else dirto = dirfrom - 1;
	if (AITunnel.IsTunnelTile(tilefrom)) {
		// Check a tunnel
		local otherend = AITunnel.GetOtherTunnelEnd(tilefrom);
		if (MyAIMap.GetDirection(otherend, tilefrom) != dirfrom) return false;
	} else {
		if (AIBridge.IsBridgeTile(tilefrom)) {
			// Check a bridge
			local otherend = AIBridge.GetOtherBridgeEnd(tilefrom);
			if (MyAIMap.GetDirection(otherend, tilefrom) != dirfrom) return false;
		} else {
			// Check rail tracks
			local tracks = AIRail.GetRailTracks(tilefrom);
			if ((tracks & acceptable[dirfrom]) == 0) return false;
		}
	}
	// Do this check the other way around as well
	if (AITunnel.IsTunnelTile(tileto)) {
		local otherend = AITunnel.GetOtherTunnelEnd(tileto);
		if (MyAIMap.GetDirection(otherend, tileto) != dirto) return false;
	} else {
		if (AIBridge.IsBridgeTile(tileto)) {
			local otherend = AIBridge.GetOtherBridgeEnd(tileto);
			if (MyAIMap.GetDirection(otherend, tileto) != dirto) return false;
		} else {
			local tracks = AIRail.GetRailTracks(tileto);
			if ((tracks & acceptable[dirto]) == 0) return false;
		}
	}
	return true;
}

function MyAIRail::CanBuildRail(from, tile, to)
{
	if (from == null || tile == null || to == null) return false;
	local test = AITestMode();
	local ret = AIRail.BuildRail(from, tile, to);
	test = null;
	return ret;
}

function MyAIRail::GetRailCost(from, tile, to)
{
	if (from == null || tile == null || to == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AIRail.BuildRail(from, tile, to)) return -1;
	test = null;
	return cost.GetCosts();
}

function MyAIRail::CanBuildRailDepot(tile, front)
{
	if (tile == null || front == null) return false;
	local test = AITestMode();
	local ret = AIRail.BuildRailDepot(tile, front);
	test = null;
	return ret;
}

function MyAIRail::GetRailDepotCost(tile, front)
{
	if (tile == null || front == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AIRail.BuildRailDepot(tile, front)) return -1;
	test = null;
	return cost.GetCosts();
}

function MyAIRail::GetRailDirection(direction)
{
	return (direction == DIR_NW || direction == DIR_SE) ? AIRail.RAILTRACK_NW_SE : AIRail.RAILTRACK_NE_SW;
}

function MyAIRail::CanBuildRailStation(tile, direction, num_platforms, platform_length, station_id)
{
	if (tile == null || direction == null || num_platforms == null || platform_length == null) return false;
	local test = AITestMode();
	local ret = AIRail.BuildRailStation(tile, direction, num_platforms, platform_length, station_id);
	test = null;
	return ret;
}

function MyAIRail::GetRailStationCost(tile, direction, num_platforms, platform_length, station_id)
{
	if (tile == null || direction == null || num_platforms == null || platform_length == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AIRail.BuildRailStation(tile, direction, num_platforms, platform_length, station_id)) return -1;
	test = null;
	return cost.GetCosts();
}

function MyAIRail::GetPerpendicular(direction)
{
	return (direction == AIRail.RAILTRACK_NE_SW) ? AIRail.RAILTRACK_NW_SE : AIRail.RAILTRACK_NE_SW;
}

function MyAIRail::GetRailStationPlatformLength(sta)
{
	if (!AIStation.IsValidStation(sta)) return 0;
	local place = AIStation.GetLocation(sta);
	if (!AIRail.IsRailStationTile(place)) return 0;
	local dir = AIRail.GetRailStationDirection(place);
	local vector = MyAIMap.GetVector(dir);
	while (AIRail.IsRailStationTile(place) && AIStation.GetStationID(place) == sta) place += vector;
	place -= vector;
	local length = 0;
	while (AIRail.IsRailStationTile(place) && AIStation.GetStationID(place) == sta) {
		length++;
		place -= vector;
	}
	return length;
}

function MyAIRail::GetRailStationTiles(sta)
{
	// empty ailist on error
	local tiles = AIList();
	if (!AIStation.IsValidStation(sta)) return tiles;
	local place = AIStation.GetLocation(sta);
	if (!AIRail.IsRailStationTile(place)) {
		tiles.AddItem(0, place);
		return tiles;
	}
	local dir = AIRail.GetRailStationDirection(place);
	local vector = MyAIMap.GetVector(dir);
	local rvector = MyAIMap.GetRVector(dir);
	while (AIRail.IsRailStationTile(place) && AIStation.GetStationID(place) == sta) place += vector;
	place -= vector;
	// Test double station
	local twolane = false;
	local count = 0;
	if (AIRail.IsRailStationTile(place + rvector) && AIStation.GetStationID(place + rvector) == sta) twolane = true;
	if (AIRail.IsRailStationTile(place - rvector) && AIStation.GetStationID(place - rvector) == sta) {
		twolane = true;
		rvector = -rvector;
	}
	while (AIRail.IsRailStationTile(place) && AIStation.GetStationID(place) == sta) {
		tiles.AddItem(count, place);
		count++;
		if (twolane) {
			tiles.AddItem(count, place + rvector);
			count++;
		}
		place -= vector;
	}
	return tiles;
}

