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
 * Define the MyAIGameSettings class which extends the AIGameSettings functions.
 */
class MyAIGameSettings /* extends AIGameSettings */
{
	/**
	 * Get the value of setting profile from Game Configuration -> Competitors.
	 */
	static function GetSettingsProfile();

	/**
	 * Get the name of setting profile from Game Configuration -> Competitors.
	 */
	static function GetSettingsProfileName();

	/**
	 * Calculates the percentage of inflation since the start of the game.
	 * @return The percentage by which prices have risen since the start of the game.
	 * It is 1.0 if there is no inflation, 2.0 if prices have doubled, etc.
	 */
	static function GetInflationRate();

	/**
	 * Returns the efective max length of trains, from vehicle.max_train_length and station.station_spread
	 * @return efective max length.
	 */
	static function EfectiveMaxTrainLength();
}

function MyAIGameSettings::GetSettingsProfile()
{
	return AIGameSettings.GetValue("settings_profile");
}

function MyAIGameSettings::GetSettingsProfileName()
{
	return (MyAIGameSettings.GetSettingsProfile() == 0) ? "easy" : (MyAIGameSettings.GetSettingsProfile() == 1) ? "medium" : "hard";
}

function MyAIGameSettings::GetInflationRate()
{
        return (AIGameSettings.GetValue("inflation")) ? (AICompany.GetMaxLoanAmount().tofloat() + 50000)/ AIGameSettings.GetValue("difficulty.max_loan").tofloat() : AICompany.GetMaxLoanAmount().tofloat() / AIGameSettings.GetValue("difficulty.max_loan").tofloat();
}

function MyAIGameSettings::EfectiveMaxTrainLength()
{
	return MyMath.Min(AIGameSettings.GetValue("vehicle.max_train_length"), AIGameSettings.GetValue("station.station_spread"));
}
