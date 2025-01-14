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
 * Define the MyRoadVehs class.
 * @depends: This class uses some mylib classes.
 */

class MyRoadVehs
{
	/**
	 * Choose a road vehicle for the given cargo.
	 * @param cargo The cargo that the road vehicle will transport.
	 * @return The EngineID of the selected vehicle. Null if no suitable vehicle was found.
	 */
	static function ChooseRoadVeh(cargo);
}

function MyRoadVehs::ChooseRoadVeh(cargo)
{
	local vehlist = AIEngineList(AIVehicle.VT_ROAD);
	vehlist.Valuate(AIEngine.GetRoadType);
	vehlist.KeepValue(AIRoad.ROADTYPE_ROAD);
	// Exclude articulated vehicles
	vehlist.Valuate(AIEngine.IsArticulated);
	vehlist.KeepValue(0);
	// Remove zero cost cars
	vehlist.Valuate(AIEngine.GetPrice);
	vehlist.RemoveValue(0);
	// Remove cars with very low capacity
	vehlist.Valuate(AIEngine.GetCapacity);
	vehlist.RemoveBelowValue(5);
	// Filter by cargo
	vehlist.Valuate(AIEngine.CanRefitCargo, cargo);
	vehlist.KeepValue(1);
	// Valuate the vehicles using krinn's valuator
	vehlist.Valuate(MyAIEngine.GetEngineEfficiency, cargo, true);
	vehlist.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	local veh = vehlist.Begin();
	if (vehlist.Count() == 0) veh = null;
	return veh;
}

