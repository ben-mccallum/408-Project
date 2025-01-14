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
 * Define the MyAIIndustry class which extends the AIIndustry functions.
 */
class MyAIIndustry /* extends AIIndustry */
{
	/**
	 * Get the percentage of transported cargo from a given industry.
	 * @param ind The index of the industry.
	 * @param cargo The index of the cargo.
	 * @return The percentage transported, ranging from 0 to 100.
	 */
	static function GetLastMonthTransportedPercentage(ind, cargo);

	/**
	 * Get production percentage of cargo1 from cargo1 + cargo2.
	 * @param ind The index of the industry.
	 * @param cargo1 The index of the cargo1.
	 * @param cargo2 The index of the cargo2.
	 * @return The percentage of cargo1, ranging from 0 to 100.
	 */
	static function GetProductionPercentage(ind, cargo1, cargo2);

	/**
	 * Return true if the tile is valid for build a station.
	 * @param tile The tile to build a station.
	 * @param ind The industry to connect.
	 * @param rad The radius of coverage tiles of the station.
	 * @param is_source Boolean parameter, true if is source station, false for destination station.
	 * @return True if tile is over industry coverage.
	 */
	static function IsTileValidForStation(tile, ind, rad, is_source);

	/**
	 * Return true if the tile is valid for build a rail station.
	 * @param tile The tile to build a station.
	 * @param ind The industry to connect.
	 * @param is_source Boolean parameter, true if is source station, false for destination station.
	 * @return True if tile is over industry coverage.
	 */
	static function IsTileValidForRailStation(tile, ind, rad, is_source);
}

function MyAIIndustry::GetLastMonthTransportedPercentage(ind, cargo)
{
	local indprod = AIIndustry.GetLastMonthProduction(ind, cargo);
	if (indprod == 0 || indprod == null) return 99; // FindService do nothing.
	else return (100 * AIIndustry.GetLastMonthTransported(ind, cargo) / indprod);
}

function MyAIIndustry::GetProductionPercentage(ind, cargo1, cargo2)
{
	if (cargo2 == null) return 100;
	local prod1 = AIIndustry.GetLastMonthProduction(ind, cargo1);
	// Secondary indrustries can produce 0 in one month, we don't want divisions by 0.
	return (prod1 == 0) ? 50 : MyMath.Percent(prod1, prod1 + AIIndustry.GetLastMonthProduction(ind, cargo2));
}

function MyAIIndustry::IsTileValidForStation(tile, ind, rad, is_source)
{
	if (!AIIndustry.IsValidIndustry(ind)) return false;
	local itiles = (is_source) ? AITileList_IndustryProducing(ind, rad) : AITileList_IndustryAccepting(ind, rad);
	if (itiles.Count() == 0) return false;
	foreach (itile, dummy in itiles) if (itile != null && AITile.GetDistanceManhattanToTile(itile, tile) == 0) return true;
	return false;
}

function MyAIIndustry::IsTileValidForRailStation(tile, ind, is_source)
{
	return MyAIIndustry.IsTileValidForStation(tile, ind, AIStation.GetCoverageRadius(AIStation.STATION_TRAIN), is_source);
}
