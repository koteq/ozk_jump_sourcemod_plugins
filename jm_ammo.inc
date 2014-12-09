#if defined _jm_ammo_included_
 #endinput
#endif
#define _jm_ammo_included_

/**
 * Regenerate client ammo.
 *
 * @param client      Client index
 * @param clip_regen  Also refill clip
 * @noreturn
 */
native JM_Ammo_RegenClient(client, bool:clip_regen=false);

public SharedPlugin:__pl_jm_ammo = 
{
	name = "jm_ammo",
	file = "jm_ammo.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_jm_ammo_SetNTVOptional()
{
	MarkNativeAsOptional("JM_Ammo_RegenClient");
}
