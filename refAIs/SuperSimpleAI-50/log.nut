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
 * Warning: this file should be required after SuperSimpleAI, cManager and cBuilder classes are declared.
 */

/**
 * Write to log all info messages from cbuilder class
 * @param string Text to write to log
 */
function cBuilder::LogInfo(string)
{
	if (cBuilder.PrintLog()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Builder(" + root.buildcounter + ")] " + string);
}

/**
 * Write to log all warning messages from cbuilder class
 * @param string Text to write to log
 */
function cBuilder::LogWarning(string)
{
	if (cBuilder.PrintLog()) AILog.Warning(SuperSimpleAI.GetCurrentDate() + "[Builder(" + root.buildcounter + ")] " + string);
}

/**
 * Write to log all error messages from cbuilder class
 * @param string Text to write to log
 */
function cBuilder::LogError(string)
{
	if (cBuilder.PrintLog()) AILog.Error(SuperSimpleAI.GetCurrentDate() + "[Builder(" + root.buildcounter + ")] " + string);
}

/**
 * Write to log all error messages from cbuilder class
 * @param string Text to write to log
 */
function cBuilder::LogDebug(string)
{
	if (cBuilder.Debug()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Builder(" + root.buildcounter + ")] [Debug] " + string);
}

/**
 * Write to log all info messages from cManager class
 * @param string Text to write to log
 */
function cManager::LogInfo(string)
{
	if (cManager.PrintLog()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Manager] " + string);
}

/**
 * Write to log all warning messages from cManager class
 * @param string Text to write to log
 */
function cManager::LogWarning(string)
{
	if (cManager.PrintLog()) AILog.Warning(SuperSimpleAI.GetCurrentDate() + "[Manager] " + string);
}

/**
 * Write to log all error messages from cManager class
 * @param string Text to write to log
 */
function cManager::LogError(string)
{
	if (cManager.PrintLog()) AILog.Error(SuperSimpleAI.GetCurrentDate() + "[Manager] " + string);
}

/**
 * Write to log all info messages from cManager class
 * @param string Text to write to log
 */
function cManager::LogDebug(string)
{
	if (cManager.Debug()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Manager] [Debug] " + string);
}

/**
 * Write to log all info messages from SuperSimpleAI class
 * @param string Text to write to log
 */
function SuperSimpleAI::LogInfo(string)
{
	if (SuperSimpleAI.PrintLog()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Main] " + string);
}

/**
 * Write to log all warning messages from SuperSimpleAI class
 * @param string Text to write to log
 */
function SuperSimpleAI::LogWarning(string)
{
	if (SuperSimpleAI.PrintLog()) AILog.Warning(SuperSimpleAI.GetCurrentDate() + "[Main] " + string);
}

/**
 * Write to log all error messages from SuperSimpleAI class
 * @param string Text to write to log
 */
function SuperSimpleAI::LogError(string)
{
	if (SuperSimpleAI.PrintLog()) AILog.Error(SuperSimpleAI.GetCurrentDate() + "[Main] " + string);
}

/**
 * Write to log all notice messages from SuperSimpleAI class
 * @param string Text to write to log
 */
function SuperSimpleAI::LogNotice(string)
{
	if (SuperSimpleAI.PrintLog()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Info] " + string);
}

/**
 * Write to log all configuration messages from SuperSimpleAI class
 * @param string Text to write to log
 */
function SuperSimpleAI::LogConfig(string)
{
	if (SuperSimpleAI.PrintLog()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Config] " + string);
}

/**
 * Write to log all loading game messages from SuperSimpleAI class
 * @param string Text to write to log
 */
function SuperSimpleAI::LogLoad(string)
{
	if (SuperSimpleAI.PrintLog()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Load game] " + string);
}

/**
 * Write to log all debug messages from SuperSimpleAI class
 * @param string Text to write to log
 */
function SuperSimpleAI::LogDebug(string)
{
	if (SuperSimpleAI.Debug()) AILog.Info(SuperSimpleAI.GetCurrentDate() + "[Main] [Debug] " + string);
}

/**
 * Transform a date in a human-readable format
 * @return Current date in format [YYYY-MM-DD]
 */
function SuperSimpleAI::GetCurrentDate()
{
	local date = AIDate.GetCurrentDate();
	local format = AISettings.GetDateFormat();
	if (format == 0) return AIDate.GetYear(date) + "-" + AIDate.GetMonth(date) + "-" + AIDate.GetDayOfMonth(date) + " ";
	if (format == 1) return AIDate.GetDayOfMonth(date) + "/" + AIDate.GetMonth(date) + "/" + AIDate.GetYear(date) + " ";
	if (format == 2) return AIDate.GetMonth(date) + "/" + AIDate.GetDayOfMonth(date) + "/" + AIDate.GetYear(date) + " ";
}

