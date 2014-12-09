#if defined _jm_dominations_included_
 #endinput
#endif
#define _jm_dominations_included_

/**
 * Set number of dominations.
 *
 * @param client	Client index
 * @param count		Dominations count to set.
 * @noreturn
 */
native SetNumberOfDominations(client, count);

public SharedPlugin:__pl_jm_dominations = 
{
	name = "jm_dominations",
	file = "jm_dominations.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_jm_dominations_SetNTVOptional()
{
	MarkNativeAsOptional("SetNumberOfDominations");
}

