#if defined _jm_mapcfg_included_
 #endinput
#endif
#define _jm_mapcfg_included_

/**
 * @return  class to which this map is designed for
 */
native TFClassType:JM_MapConfig_GetMapPlayerClass();

/**
 * Called on map start when config loaded
 */
forward JM_MapConfig_OnConfigLoaded(const String:team[], const String:class[], const String:difficulty[]);

public SharedPlugin:__pl_jm_mapcfg = 
{
	name = "jm_mapcfg",
	file = "jm_mapcfg.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_jm_mapcfg_SetNTVOptional()
{

}
