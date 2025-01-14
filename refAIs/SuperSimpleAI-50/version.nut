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
 * Warning: This file is loaded both by main.nut and info.nut
 * thus, don't place anything here that is heavy or not required
 * to be available when OpenTTD scans the info.nut file.
 */

/**
 * Current version of this AI.
 */
SELF_VERSION <- 50;

/**
 * Minium version of loaded games with this AI.
 */
SELF_LOAD_VERSION <- 26;

/**
 * Date of current version of this AI.
 */
SELF_DATE <- "2024-09-19";

/**
 * Configurtion levels of info.nut file.
 * Values: 0 <= Minium configuration.
 *         1 <= Short configuration, for BaNaNaS releases.
 *         2 <= Extended configuration, for Expert releases with undocumented settings.
 *         3 <= Debug configuration, for Developer.
 */
SELF_INFO_VERSION <- 1;
