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
 * Define the MyAIController class which extends the AIController functions.
 */
class MyAIController /* extends AIController */
{
	/**
	 * Get the version string of OTT (thank you idioty).
	 * @return String with version of OpenTTD in an human readable format.
	 */
	static function GetVersionString();
}

function MyAIController::GetVersionString()
{
	local v = AIController.GetVersion();
	local major = (v & 0xF0000000) >> 28;
	local minor = (v & 0x0F000000) >> 24;
	local build = (v & 0x00F00000) >> 20;
	local revision = v & 0x0007FFFF;
	return major + "." + minor + "." + build + "." + revision;
}
