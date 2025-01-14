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
 * Define the MyPathfinderUtils class.
 */

class MyPathfinderUtils
{
	/**
	 * Converts a PathFinder path to TileList.
	 * @param PFpath The path object returned by PathFinder FindPath().
	 * @return TileList() object.
	 */
	static function PathToTileList(PFpath);
}

function MyPathfinderUtils::PathToTileList(PFpath)
{
	local tilelist = AITileList();
        while (PFpath != null) {
		tilelist.AddTile(PFpath.GetTile());
		PFpath = PFpath.GetParent();
        }
        return tilelist;
}

