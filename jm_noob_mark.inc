#if defined _jm_noob_mark_included_
 #endinput
#endif
#define _jm_noob_mark_included_

/**
 * Returns noob mark status
 *
 * @param client      Client index
 * @return bool
 */
native bool:JM_NoobMark_IsActive(client);

/**
 * Prints warning about noob mark to client
 *
 * @param client      Client index
 * @noreturn
 */
native JM_NoobMark_PrintWarning(client);

/**
 * Should be called by other plugins before client cheat activated (noclip for example)
 *
 * @param client      Client index
 * @noreturn
 */
native JM_NoobMark_Activate(client);

/**
 * Should be called by other plugins if they wish to unmark client and telepotr him back
 *
 * @param client         Client index
 * @param resetPosition  Return client back to to position where he got his mark
 * @noreturn
 */
native JM_NoobMark_Deactivate(client, bool:resetPosition);

/**
 * Called when client (or other plugin) asks to set mark, miniclip shoud be cancelled
 *
 * @param client      Client index
 * @noreturn
 */
forward JM_NoobMark_OnBeforeActivate(client);

/**
 * Called when client (or other plugin) asks to remove mark, every single cheat should be disabled
 *
 * @param client      Client index
 * @noreturn
 */
forward JM_NoobMark_OnBeforeDeactivate(client);

public SharedPlugin:__pl_jm_noob_mark = 
{
	name = "jm_noob_mark",
	file = "jm_noob_mark.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_jm_noob_mark_SetNTVOptional()
{

}
