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
 * Define the MyRoutes class.
 * @depends: This class uses some mylib classes.
 */

class MyRoutes
{
	/**
	 * Load de data from a SaveGame and put into route table.
	 * @param route Savegame data of routes.
	 * @return The Route table.
	 */
	static function SaveDataToRouteTable(routes);

	/**
	 * Creates a table with only the data to be saved.
	 * @param route Table of routes.
	 * @return The table to be saved, without cache data.
	 */
	static function RouteTableToSaveData(routes);

	/**
	 * Get the maximum speed of trains or road vehicles from a group.
	 * @param groupid GroupID.
	 * @return Maximum speed of this vehicle.
	 */
	static function GetRouteMaxCurrentSpeed(groupid);
}

function MyRoutes::RouteTableToSaveData(routes)
{
	local saveroutes = [];
	foreach (idx, route in routes) {
		local savedata = {
			src = null
			dst = null
			stasrc = null
			stadst = null
			homedepot = null
			group = null
			crg = null
			extracrg = null
			vehtype = null
			railtype = null
			maxvehicles = null
			slopes = null
		}
		savedata.src = route.src;
		savedata.dst = route.dst;
		savedata.stasrc = route.stasrc;
		savedata.stadst = route.stadst;
		savedata.homedepot = route.homedepot;
		savedata.group = route.group;
		savedata.crg = route.crg;
		savedata.extracrg = route.extracrg;
		savedata.vehtype = route.vehtype;
		savedata.railtype = route.railtype;
		savedata.maxvehicles = route.maxvehicles;
		savedata.slopes = route.slopes;
		saveroutes.push(savedata);
	}
	return saveroutes;
}

function MyRoutes::SaveDataToRouteTable(routes)
{
	local saveroutes = [];
	foreach (idx, route in routes) {
		local savedata = {
			src = null
			dst = null
			stasrc = null
			stadst = null
			homedepot = null
			group = null
			crg = null
			extracrg = null
			vehtype = null
			railtype = null
			maxvehicles = null
			slopes = null
			cur_max_speed = null
			last_wagon = null
			last_extra_wagon = null
			last_engine = null
			last_date = null
		}
		savedata.src = route.src;
		savedata.dst = route.dst;
		savedata.stasrc = route.stasrc;
		savedata.stadst = route.stadst;
		savedata.homedepot = route.homedepot;
		savedata.group = route.group;
		savedata.crg = route.crg;
		savedata.extracrg = route.extracrg;
		savedata.vehtype = route.vehtype;
		savedata.railtype = route.railtype;
		savedata.maxvehicles = route.maxvehicles;
		savedata.slopes = route.slopes;
		savedata.cur_max_speed = MyRoutes.GetRouteMaxCurrentSpeed(route.group);
		savedata.last_wagon = null;
		savedata.last_extra_wagon = null;
		savedata.last_engine = null;
		savedata.last_date = AIDate.GetCurrentDate() - 1000;
		saveroutes.push(savedata);
	}
	return saveroutes;
}

function MyRoutes::GetRouteMaxCurrentSpeed(groupid)
{
	if (groupid == null) return 0;
	// I don't know how to get the engine and wagons that train has,
	// so the maximum speed can be the maximum of current speed of
	// all vehicles of a group.
	local max_speed = 0;
	local vehicles = AIVehicleList_Group(groupid);
	foreach (vehid, dummy in vehicles) max_speed = MyMath.Max(max_speed, AIVehicle.GetCurrentSpeed(vehid));
	return max_speed;
}
