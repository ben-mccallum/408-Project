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
 * Define the MyAIGroup class which extends the AIGroup functions.
 */
class MyAIGroup /* extends AIGroup */
{
	/**
	 * Get the current profit of a group.
	 * @param group_id The group to get the profit of.
	 * @return The current profit the group has.
	 */
	static function GetProfitThisYear(group_id);

	/**
	 * Get the profit of last year of a group.
	 * @param group_id The group to get the profit of.
	 * @return The current profit the group had last year.
	 */
	static function GetProfitLastYear(group_id);
}

if ("GetProfitThisYear" in AIGroup) {
	function MyAIGroup::GetProfitThisYear(group_id)
	{
		return AIGroup.GetProfitThisYear(group_id);
	}
} else {
	// Some versions of OpenTTD doesn't have this function.
	function MyAIGroup::GetProfitThisYear(group_id)
	{
		local ret = 0;
		local vehicles = AIVehicleList_Group(group_id);
		foreach (vehicle, dummy in vehicles) {
			ret += AIVehicle.GetProfitThisYear(vehicle);
		}
		return ret;
	}
}

if ("GetProfitLastYear" in AIGroup) {
	function MyAIGroup::GetProfitLastYear(group_id)
	{
		return AIGroup.GetProfitLastYear(group_id);
	}
} else {
	// Some versions of OpenTTD doesn't have this function.
	function MyAIGroup::GetProfitLastYear(group_id)
	{
		local ret = 0;
		local vehicles = AIVehicleList_Group(group_id);
		foreach (vehicle, dummy in vehicles) {
			ret += AIVehicle.GetProfitLastYear(vehicle);
		}
		return ret;
	}
}

