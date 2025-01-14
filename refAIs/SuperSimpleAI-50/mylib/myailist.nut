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
 * Define the MyAIList class which extends the AIList functions.
 */

class MyAIList /* extends AIList */
{
	/**
	 * Converts an AIList to an array.
	 * @param list The AIList to be converted.
	 * @return The converted array.
	 */
	static function ListToArray(list);

	/**
	 * Converts an array to an AIList.
	 * @param The array to be converted.
	 * @return The converted AIList.
	 */
	static function ArrayToList(array);

	/**
	 * Check if a list has an item.
	 * @param item The item to search.
	 * @param list The list where to search item.
	 * @return True if item is found in list.
	 */
	static function ListContainsValuator(item, list);

	/**
	 * Check if a list has an item with value of 0.
	 * @param item The item to search.
	 * @param list The list where to search item.
	 * @return True if item with value of 0 is found in list.
	 */
	static function ListContainsValuatorWithZeroValue(item, list);
}

function MyAIList::ListToArray(list)
{
	local array = [];
	if (list == null) return array;
	local templist = AIList();
	templist.AddList(list);
	while (templist.Count() > 0) {
		local arrayitem = [templist.Begin(), templist.GetValue(templist.Begin())];
		array.append(arrayitem);
		templist.RemoveTop(1);
	}
	return array;
}

function MyAIList::ArrayToList(array)
{
	local list = AIList();
	if (array == null) return list;
	local temparray = [];
	temparray.extend(array);
	while (temparray.len() > 0) {
		local arrayitem = temparray.pop();
		list.AddItem(arrayitem[0], arrayitem[1]);
	}
	return list;
}

function MyAIList::ListContainsValuator(item, list)
{
	return list.HasItem(item);
}

function MyAIList::ListContainsValuatorWithZeroValue(item, list)
{
	return list.HasItem(item) && (list.GetValue(item) == 0);
}

