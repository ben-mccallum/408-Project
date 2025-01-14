/**
 * This file is part of SuperSimpleAI: An OpenTTD AI.
 *
 * Based on code from PAXLink.
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
 * Define the MyAIMap class which extends the AIMap functions.
 */
class MyAIMap /* extends AIMap */
{
	/**
	 * Gives an estimate for the cost to flattern an area.
	 * It is a function from PAXLink.
	 * @param top_left_tile The top left tile of the area.
	 * @param width The width of the area.
	 * @param height The height of the area.
	 * @return The estimated cost, -1 if not possible.
	 */
	static function CostToFlattern(top_left_tile, width, height);

	/**
	 * Return the vector from direction.
	 * @param dir The direction.
	 * @return vector.
	 */
	static function GetVector(dir);

	/**
	 * Return the rvector from direction.
	 * @param dir The direction.
	 * @return vector.
	 */
	static function GetRVector(dir);

	/**
	 * Get the direction from one tile to another.
	 * @param tilefrom The first tile.
	 * @param tileto The second tile
	 * @return The direction from the first tile to the second tile.
	 */
	static function GetDirection(tilefrom, tileto);

	/**
	 * Get the secondary (90 grade) direction from one tile to another.
	 * @param tilefrom The first tile.
	 * @param tileto The second tile
	 * @return The secondary (90 grade) direction from the first tile to the second tile.
	 */
	static function GetSecondaryDirection(tilefrom, tileto);
}

function MyAIMap::CostToFlattern(top_left_tile, width, height)
{
	if(!AITile.IsBuildableRectangle(top_left_tile, width, height))
		return -1; // not buildable
	local level_cost = 0;
	{
		local test = AITestMode();
		local account = AIAccounting();
		local bottom_right_tile = top_left_tile + AIMap.GetTileIndex(width, height);
		if(!AITile.LevelTiles(top_left_tile, bottom_right_tile))
			return -1;
		level_cost = account.GetCosts();
	}
	return level_cost;
}

function MyAIMap::GetVector(dir)
{
	return (dir == AIRail.RAILTRACK_NE_SW) ? AIMap.GetTileIndex(1, 0) : AIMap.GetTileIndex(0, 1);
}

function MyAIMap::GetRVector(dir)
{
	return (dir == AIRail.RAILTRACK_NE_SW) ? AIMap.GetTileIndex(0, 1) : AIMap.GetTileIndex(1, 0);
}

function MyAIMap::GetDirection(tilefrom, tileto)
{
	local distx = AIMap.GetTileX(tileto) - AIMap.GetTileX(tilefrom);
	local disty = AIMap.GetTileY(tileto) - AIMap.GetTileY(tilefrom);
	local ret = 0;
	if (abs(distx) > abs(disty)) {
		ret = 2;
		disty = distx;
	}
	if (disty > 0) ret = ret + 1;
	return ret;
}

function MyAIMap::GetSecondaryDirection(tilefrom, tileto)
{
	local distx = AIMap.GetTileX(tileto) - AIMap.GetTileX(tilefrom);
	local disty = AIMap.GetTileY(tileto) - AIMap.GetTileY(tilefrom);
	local ret = 0;
	if (abs(distx) < abs(disty)) {
		ret = 2;
		disty = distx;
	}
	if (disty > 0) ret = ret + 1;
	return ret;
}

