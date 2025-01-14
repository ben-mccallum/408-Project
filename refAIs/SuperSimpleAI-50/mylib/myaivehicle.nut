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
 * Define the MyAIVehicle class which extends the AIVehicle functions.
 */
class MyAIVehicle /* extends AIVehicle */
{
	/**
	 * A workaround for refitting the mail wagon separately.
	 * @param mailwagon The mail wagon to be refitted.
	 * @param firstwagon The wagon to which the mail wagon is attached.
	 * @param trainengine The locomotive of the train, used to move the wagons.
	 * @param crg The cargo which the mail wagon will be refitted to.
	 */
	static function MailWagonWorkaround(mailwagon, firstwagon, trainengine, crg);
}

function MyAIVehicle::MailWagonWorkaround(mailwagon, firstwagon, trainengine, crg)
{
	if (mailwagon == null || firstwagon == null || trainengine == null || crg == null) return false;
	AIVehicle.MoveWagon(firstwagon, 0, trainengine, 0);
	AIVehicle.RefitVehicle(mailwagon, crg);
	AIVehicle.MoveWagon(trainengine, 1, mailwagon, 0);
	AIVehicle.MoveWagon(mailwagon, 0, trainengine, 0);
	AIVehicle.MoveWagon(trainengine, 1, firstwagon, 0);
	return true;
}

