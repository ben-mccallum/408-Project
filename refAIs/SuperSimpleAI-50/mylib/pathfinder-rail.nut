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
 * DEPENDENCES: SuperSimpleAI, like SimpleAI, depends on the following libraries to build rail routes:
 * - Graph.AyStar v4 (a dependency of the rail pathfinder)
 * - Queue.BinaryHeap v1 (a dependency of Graph.AyStar)
 *
 * If you have a SimpleAI based AI code, you can replace your pathfinder-rail.nut code with this.
 * This code is 100% compatible, and without extra parameters it will work like original code.
 * Warning: WormAI code uses _cost_farmtile, but in this code the parameter name is _cost_farm_tile.
 */

/**
 * Use library.
 */
import("pathfinder.rail", "RailPathFinder", 1);

/**
 * Define the MyRailPF class which extends the RailPathFinder functions.
 */
class MyRailPF extends RailPathFinder
{
	_cost_level_crossing = null;	// Penalty for level crossings with road.
	_cost_farm_tile = null;		// Penalty for farm tiles.
	_cost_non_flat_tile = null;	// Penalty for non flat tiles.
	_cost_steep_slope_tile = null;	// Penalty for non flat tiles.
	_cost_over_height = null;	// Penalty for tile heights over max height or under min height.
	_max_tile_height = null;
	_min_tile_height = null;

	constructor()
	{
		this._cost_level_crossing = 300;
		this._cost_farm_tile = 0;
		this._cost_non_flat_tile = 0;
		this._cost_steep_slope_tile = 0;
		this._cost_over_height = 10;
		this._max_tile_height = 255;
		this._min_tile_height = 1;
		::RailPathFinder.constructor();
	}

	/**
	 * Print all values, for debuging.
	 */
	static function PrintAllValues();
}

/**
 * Overrides the rail pathfinder's _Cost function to add some penalties.
 */
function MyRailPF::_Cost(path, new_tile, new_direction, self)
{
	// First line added from AdmiralAI.
	if (AITile.GetMaxHeight(new_tile) == 0) return self._max_cost;
	local cost = ::RailPathFinder._Cost(path, new_tile, new_direction, self);
	// Add a penalty for level crossings.
	if (AITile.HasTransportType(new_tile, AITile.TRANSPORT_ROAD)) cost += self._cost_level_crossing;
        // Taken from WormAI: Check if the new tile is a farmland tile. 
        if (AITile.IsFarmTile(new_tile)) cost += self._cost_farm_tile;
	// Penalty for non flat tiles.
	if (self._cost_non_flat_tile != 0) if (AITile.GetSlope(new_tile) != AITile.SLOPE_FLAT) cost += self._cost_non_flat_tile;
	// Penalty for steep slope tiles.
	if (self._cost_steep_slope_tile != 0) if (AITile.IsSteepSlope(new_tile)) cost += self._cost_steep_slope_tile;
	// Penalty for heights over max height or under min height.
	if (AITile.GetMaxHeight(new_tile) < self._min_tile_height) cost += self._cost_over_height * (self._min_tile_height - AITile.GetMaxHeight(new_tile));
	if (AITile.GetMaxHeight(new_tile) > self._max_tile_height) cost += self._cost_over_height * (AITile.GetMaxHeight(new_tile) - self._max_tile_height);
	return cost;
}

function MyRailPF::PrintAllValues()
{
	::print("MyRailPF._max_cost = " + _max_cost);
	::print("MyRailPF._cost_tile = " + _cost_tile);
	::print("MyRailPF._cost_diagonal_tile = " + _cost_diagonal_tile);
	::print("MyRailPF._cost_turn = " + _cost_turn);
	::print("MyRailPF._cost_slope = " + _cost_slope);
	::print("MyRailPF._cost_bridge_per_tile = " + _cost_bridge_per_tile);
	::print("MyRailPF._cost_tunnel_per_tile = " + _cost_tunnel_per_tile);
	::print("MyRailPF._cost_coast = " + _cost_coast);
	::print("MyRailPF._cost_level_crossing = " + _cost_level_crossing);
	::print("MyRailPF._cost_farm_tile = " + _cost_farm_tile);
	::print("MyRailPF._cost_non_flat_tile = " + _cost_non_flat_tile);
	::print("MyRailPF._cost_steep_slope_tile = " + _cost_steep_slope_tile);
	::print("MyRailPF._cost_over_height = " + _cost_over_height);
	::print("MyRailPF._max_tile_height = " + _max_tile_height);
	::print("MyRailPF._min_tile_height = " + _min_tile_height);
	::print("MyRailPF._max_bridge_length = " + _max_bridge_length);
	::print("MyRailPF._max_tunnel_length = " + _max_tunnel_length);
}
