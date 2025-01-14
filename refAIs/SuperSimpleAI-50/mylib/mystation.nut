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
 * Define the MyStation class.
 */
class MyStation
{
	/**
	 * Set the new name of the station.
	 * @param station_id The basestation to set the name of.
	 * @param prefix Prefix to set (somethink like "SRC", "DST, "AIR"...)
	 * @param counter The router counter.
	 * @param postfix Postfix to set (optional)
	 * @return True.
	 */
	static function SetName(station_id, prefix, counter, postfix = "");
}

function MyStation::SetName(station_id, prefix, counter, postfix = "")
{
	if (station_id == null || prefix == null || counter == null) return false;
	local companyname = MyAICompany.GetMyName();
	local changed = false;
	if (!AIStation.SetName(station_id, companyname + " " + prefix + "_0000 (" + AIDate.GetYear(AIDate.GetCurrentDate()) + ").tmp")) {
		// Shorten the company name if it is too long (Unicode character problems)
		while (AIError.GetLastError() == AIError.ERR_PRECONDITION_STRING_TOO_LONG) {
			companyname = companyname.slice(0, companyname.len() - 1);
			AIStation.SetName(station_id, companyname + ". " + prefix + "_0000 (" + AIDate.GetYear(AIDate.GetCurrentDate()) + ").tmp");
		}
		changed = true;
	}
	if (changed) AIStation.SetName(station_id, companyname + ". " + prefix + "_" + counter + " (" + AIDate.GetYear(AIDate.GetCurrentDate()) + ")" + postfix);
	else AIStation.SetName(station_id, companyname + " " + prefix + "_" + counter + " (" + AIDate.GetYear(AIDate.GetCurrentDate()) + ")" + postfix);
	return true;
}

