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
 * Define the MyAIRoad class which extends the AIRoad functions.
 */
class MyAIRoad /* extends AIRoad */
{
	/**
	 * Test if we can build a piece of road.
	 * @param start The start tile of the road.
	 * @param end The end tile of the road.
	 * @return True if success.
	 */
	static function CanBuildRoad(start, end);

	/**
	 * Get the cost to build a proposed fragment of road.
	 * @param start The start tile of the road.
	 * @param end The end tile of the road.
	 * @return Cost of new tracks to build, -1 if is not buildable.
	 */
	static function GetRoadCost(start, end);

	/**
	 * Test if we can build a road station.
	 * @param tile Place to build the station.
	 * @param front The tile exactly in front of the station.
	 * @param road_veh_type Whether to build a truck or bus station.
	 * @param station_id The station to join, AIStation::STATION_NEW or AIStation::STATION_JOIN_ADJACENT.
	 * @return True if success.
	 */
	static function CanBuildRoadStation(tile, front, road_veh_type, station_id);

	/**
	 * Return the station cost.
	 * @param tile Place to build the station.
	 * @param front The tile exactly in front of the station.
	 * @param road_veh_type Whether to build a truck or bus station.
	 * @param station_id The station to join, AIStation::STATION_NEW or AIStation::STATION_JOIN_ADJACENT.
	 * @return Cost of station, -1 if we can't build it.
	 */
	static function GetRoadStationCost(tile, front, road_veh_type, station_id);

	/**
	 * Test if we can build a road depot.
	 * @param tile Place to build the station.
	 * @param front The tile exactly in front of the station.
	 * @return True if success.
	 */
	static function CanBuildRoadDepot(tile, front);

	/**
	 * Return the depot cost.
	 * @param tile Place to build the station.
	 * @param front The tile exactly in front of the station.
	 * @return Cost of station, -1 if we can't build it.
	 */
	static function GetRoadDepotCost(tile, front);
}

function MyAIRoad::CanBuildRoad(start, end)
{
	if (start == null || end == null) return false;
	local ret = true;
	local test = AITestMode();
	if (!AIRoad.BuildRoad(start, end)) if (AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) ret = false;
	test = null;
	return ret;
}

function MyAIRoad::GetRoadCost(start, end)
{
	if (start == null || end == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AIRoad.BuildRoad(start, end)) if (AIError.GetLastError() != AIError.ERR_ALREADY_BUILT) return -1;
	test = null;
	return cost.GetCosts();
}

function MyAIRoad::CanBuildRoadStation(tile, front, road_veh_type, station_id)
{
	if (tile == null || front == null || road_veh_type == null) return false;
	local ret = true;
	local test = AITestMode();
	if (!AIRoad.BuildRoadStation(tile, front, road_veh_type, station_id)) ret = false;
	test = null;
	return ret;
}

function MyAIRoad::GetRoadStationCost(tile, front, road_veh_type, station_id)
{
	if (tile == null || front == null || road_veh_type == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AIRoad.BuildRoadStation(tile, front, road_veh_type, station_id)) return -1;
	test = null;
	return cost.GetCosts();
}

function MyAIRoad::CanBuildRoadDepot(tile, front)
{
	if (tile == null || front == null) return false;
	local test = AITestMode();
	if (!AIRoad.BuildRoadDepot(tile, front)) return false;
	test = null;
	return true;
}

function MyAIRoad::GetRoadDepotCost(tile, front)
{
	if (tile == null || front == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AIRoad.BuildRoadDepot(tile, front)) return -1;
	test = null;
	return cost.GetCosts();
}
