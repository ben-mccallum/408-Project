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
 * DEPENDENCES: SuperSimpleAI, like SimpleAI, depends on the following libraries to build road routes:
 * - Pathfinder.Road v4
 * - Graph.AyStar v6 (a dependency of the road pathfinder)
 * - Queue.BinaryHeap v1 (a dependency of Graph.AyStar)
 *
 * If you have a SimpleAI based AI code, you can replace your pathfinder-road.nut code with this.
 * This code is 100% compatible, and without extra parameters it will work like original code.
 * Warning: WormAI code uses _cost_farmtile, but in this code the parameter name is _cost_farm_tile.
 */
import("pathfinder.road", "RoadPathFinder", 4);

/**
 * Define the MyRoadPF class which extends the RoadPathFinder functions.
 */
class MyRoadPF extends RoadPathFinder
{
	_cost_level_crossing = null;	// Penalty for level crossings with rails.
	_cost_farm_tile = null;		// Penalty for farm tiles.
	_cost_non_flat_tile = null;	// Penalty for non flat tiles.
	_goals = null;

	constructor()
	{
		this._cost_level_crossing = 500;
		this._cost_farm_tile = 30;
		this._cost_non_flat_tile = 0;
		::RoadPathFinder.constructor();
	}

	/**
	 * Print all values, for debuging.
	 */
	static function PrintAllValues();
}

/**
 * Overrides the road pathfinder's InitialzePath function in order to store the goals.
 * This is needed to avoid having roads ending with a bridge.
 */
function MyRoadPF::InitializePath(sources, goals)
{
	::RoadPathFinder.InitializePath(sources, goals);
	_goals = AIList();
	for (local i = 0; i < goals.len(); i++) _goals.AddItem(goals[i], 0);
}

/**
 * Overrides the road pathfinder's _Cost function to add a penalty for level crossings and farm tiles.
 */
function MyRoadPF::_Cost(self, path, new_tile, new_direction)
{
	// First line added from AdmiralAI.
	if (AITile.GetMaxHeight(new_tile) == 0) return self._max_cost;
	local cost = ::RoadPathFinder._Cost(self, path, new_tile, new_direction);
	// Add a penalty for level crossings.
	if (AITile.HasTransportType(new_tile, AITile.TRANSPORT_RAIL)) cost += self._cost_level_crossing;
	// Taken from WormAI: Check if the new tile is a farmland tile.
	if (AITile.IsFarmTile(new_tile)) cost += self._cost_farm_tile;
	// Penalty for non flat tiles.
	if (self._cost_non_flat_tile != 0) if (AITile.GetSlope(new_tile) != AITile.SLOPE_FLAT) cost += self._cost_non_flat_tile;
	return cost;
}

/**
 * Overrides the road pathfinder's _GetTunnelsBridges function in order to enable the AI
 * to build road bridges on flat terrain. (e.g. to avoid level crossings)
 */
function MyRoadPF::_GetTunnelsBridges(last_node, cur_node, bridge_dir)
{
	local slope = AITile.GetSlope(cur_node);
	if (slope == AITile.SLOPE_FLAT && AITile.IsBuildable(cur_node + (cur_node - last_node))) return [];
	local tiles = [];
	for (local i = 2; i < this._max_bridge_length; i++) {
		local bridge_list = AIBridgeList_Length(i + 1);
		local target = cur_node + i * (cur_node - last_node);
		if (!bridge_list.IsEmpty() && !_goals.HasItem(target) && AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), cur_node, target)) tiles.push([target, bridge_dir]);
	}

	if (slope != AITile.SLOPE_SW && slope != AITile.SLOPE_NW && slope != AITile.SLOPE_SE && slope != AITile.SLOPE_NE) return tiles;
	local other_tunnel_end = AITunnel.GetOtherTunnelEnd(cur_node);
	if (!AIMap.IsValidTile(other_tunnel_end)) return tiles;

	local tunnel_length = AIMap.DistanceManhattan(cur_node, other_tunnel_end);
	local prev_tile = cur_node + (cur_node - other_tunnel_end) / tunnel_length;
	if (AITunnel.GetOtherTunnelEnd(other_tunnel_end) == cur_node && tunnel_length >= 2 && prev_tile == last_node && tunnel_length < _max_tunnel_length && AITunnel.BuildTunnel(AIVehicle.VT_ROAD, cur_node)) tiles.push([other_tunnel_end, bridge_dir]);
	return tiles;
}

function MyRoadPF::PrintAllValues()
{
        ::print("MyRoadPF._max_cost = " + _max_cost);
        ::print("MyRoadPF._cost_tile = " + _cost_tile);
        ::print("MyRoadPF._cost_diagonal_tile = " + _cost_diagonal_tile);
        ::print("MyRoadPF._cost_turn = " + _cost_turn);
        ::print("MyRoadPF._cost_slope = " + _cost_slope);
        ::print("MyRoadPF._cost_bridge_per_tile = " + _cost_bridge_per_tile);
        ::print("MyRoadPF._cost_tunnel_per_tile = " + _cost_tunnel_per_tile);
        ::print("MyRoadPF._cost_coast = " + _cost_coast);
        ::print("MyRoadPF._cost_level_crossing = " + _cost_level_crossing);
        ::print("MyRoadPF._cost_farm_tile = " + _cost_farm_tile);
	::print("MyRoadPF._cost_non_flat_tile = " + _cost_non_flat_tile);
        ::print("MyRoadPF._max_bridge_length = " + _max_bridge_length);
        ::print("MyRoadPF._max_tunnel_length = " + _max_tunnel_length);
}

