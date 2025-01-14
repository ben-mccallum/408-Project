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
 * Define the MyPlanes class.
 * @depends: This class uses some mylib classes.
 */

class MyPlanes
{
	/**
	 * Chooses a plane to be used. Helicopters are excluded.
	 * @param crg The type of cargo to carry.
	 * @param is_small If true, only small planes are accepted.
	 * @param distance The order distance of the source and destination.
	 * @param cheapest If true, the cheapest plane will be chosen. If false, the highest capacity plane that is still affordable.
	 * @return The plane type. Null if there are none available.
	 */
	static function ChoosePlane(crg, is_small, distance, cheapest);
}

function MyPlanes::ChoosePlane(crg, is_small, distance, cheapest)
{
	local planelist = AIEngineList(AIVehicle.VT_AIR);
	planelist.Valuate(AIEngine.GetMaximumOrderDistance);
	planelist.KeepAboveValue(distance);
	local planelist2 = AIEngineList(AIVehicle.VT_AIR);
	planelist2.Valuate(AIEngine.GetMaximumOrderDistance);
	planelist2.KeepValue(0);
	// The union of the above two lists
	planelist.AddList(planelist2);
	planelist.Valuate(AIEngine.GetPlaneType);
	planelist.RemoveValue(AIAirport.PT_INVALID);
	planelist.RemoveValue(AIAirport.PT_HELICOPTER);
	if (is_small) planelist.RemoveValue(AIAirport.PT_BIG_PLANE);
	planelist.Valuate(AIEngine.CanRefitCargo, crg);
	planelist.KeepValue(1);
	planelist.Valuate(AIEngine.GetPrice);
	if (cheapest) {
		// Sort ascending by price
		planelist.Sort(AIList.SORT_BY_VALUE, true);
	} else {
		// Sort	descending by capacity, but discard those that are too expensive
		planelist.KeepBelowValue(MyAICompany.GetMyMaxBankBalance());
		if (planelist.Count() == 0) return null;
		planelist.Valuate(AIEngine.GetCapacity);
		planelist.Sort(AIList.SORT_BY_VALUE, false);
	}
	return planelist.Begin();
}


