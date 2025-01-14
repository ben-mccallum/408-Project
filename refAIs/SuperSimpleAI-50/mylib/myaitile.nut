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
 * Define the MyAITile class which extends the AITile functions.
 */

class MyAITile /* extends AITile */
{
	/**
	 * Checks whether a given rectangle is within the influence of a given town.
	 * @param tile The topmost tile of the rectangle.
	 * @param town_id The TownID of the town to be checked.
	 * @param width The width of the rectangle.
	 * @param height The height of the rectangle.
	 * @return True if the rectangle is within the influence of the town.
	 */
	static function IsRectangleWithinTownInfluence(tile, town_id, width, height);

	/**
	 * Get a TileList around a town.
	 * @param town_id The TownID of the given town.
	 * @param width The width of the proposed station.
	 * @param height The height of the proposed station.
	 * @return A TileList containing tiles around a town.
	 */
	static function GetTilesAroundTown(town_id, width, height);

	/**
	 * Return true if tile is flat.
	 * @param tile The tile.
	 * @return True if tile is flat
	 */
	static function IsFlatTile(tile);

	/**
	 * Get the cost to demolish a tile.
	 * @param tile The tile.
	 * @return Cost to demolish the tile, -1 if fails.
	 */
	static function GetDemolishCost(tile);

	/**
	 * Determine if the tile is a downslope (and if it is buildable).
	 * @param tile The tile.
	 * @param vector The vector of the tile.
	 * @return True if tile is a downslope.
	 */
	static function IsDownslopeTile(tile, vector);
}

function MyAITile::IsRectangleWithinTownInfluence(tile, town_id, width, height)
{
	if (width <= 1 && height <= 1) return AITile.IsWithinTownInfluence(tile, town_id);
	local offsetX = AIMap.GetTileIndex(width - 1, 0);
	local offsetY = AIMap.GetTileIndex(0, height - 1);
	return AITile.IsWithinTownInfluence(tile, town_id) || AITile.IsWithinTownInfluence(tile + offsetX + offsetY, town_id) || AITile.IsWithinTownInfluence(tile + offsetX, town_id) || AITile.IsWithinTownInfluence(tile + offsetY, town_id);
}

function MyAITile::GetTilesAroundTown(town_id, width, height)
{
	local tiles = AITileList();
	local townplace = AITown.GetLocation(town_id);
	local distedge = AIMap.DistanceFromEdge(townplace);
	local offset = null;
	local radius = 15;
	if (AITown.GetPopulation(town_id) > 5000) radius = 30;
	// A bit different is the town is near the edge of the map
	if (distedge < radius + 1) offset = AIMap.GetTileIndex(distedge - 1, distedge - 1);
	else offset = AIMap.GetTileIndex(radius, radius);
	tiles.AddRectangle(townplace - offset, townplace + offset);
	tiles.Valuate(MyAITile.IsRectangleWithinTownInfluence, town_id, width, height);
	tiles.KeepValue(1);
	return tiles;
}

function MyAITile::IsFlatTile(tile)
{
	return (AITile.GetSlope(tile) == AITile.SLOPE_FLAT);
}

function MyAITile::GetDemolishCost(tile) {
	if (tile == null) return -1;
	local test = AITestMode();
	local cost = AIAccounting();
	cost.ResetCosts();
	if (!AITile.DemolishTile(tile)) return -1;
	test = null;
	return cost.GetCosts();
}

function MyAITile::IsDownslopeTile(tile, vector)
{
	if (!AITile.IsBuildable(tile) || MyAITile.IsFlatTile(tile)) return false;
	local test = AITestMode();
	if (AIRail.BuildRailDepot(tile, tile + vector)) {
		test = null;
		return false;
	} else {
		test = null;
		return true;
	}
}

