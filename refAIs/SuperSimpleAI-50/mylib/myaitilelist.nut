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
 * Define the MyAITileList class which extends the AITileList functions.
 */

class MyAITileList extends AITileList
{
	/**
	 * Returns a tile that have this value..
	 * @param value The value to search from it.
	 * @param list The list where to search item.
	 * @return The tile that have a value.
	 */
	static function GetTileByValue(value, list);

	//constructor()
	//{
	//	::AITileList.constructor();
	//}
}

function MyAITileList::GetTileByValue(value, list)
{
	local templist = AITileList();
	templist.AddList(list);
	templist.KeepValue(value);
	return templist.Begin();
}
