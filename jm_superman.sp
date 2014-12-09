#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "JM Superman",
	author = "Reflex",
	description = "Personal godmode",
	version = "1.0"
};

#define PROP_TAKEDAMAGE_SIZE 1
#define PROP_TAKEDAMAGE_NAME "m_takedamage"

#define TAKEDAMAGE_DISABLED 0
#define TAKEDAMAGE_EVENTS_ONLY 1 // Call damage functions, but don't modify health
#define TAKEDAMAGE_ENABLED 2

public OnPluginStart() {
	RegConsoleCmd("sm_superman", Command_Superman, "Makes you strong like superman");
	LoadTranslations("jm_superman.phrases");
}

public Action:Command_Superman(client, args)
{
	if (IsValidEntity(client)) {
		new takedamage = GetEntProp(client, Prop_Data, PROP_TAKEDAMAGE_NAME, PROP_TAKEDAMAGE_SIZE);
		if (takedamage == TAKEDAMAGE_ENABLED) {
			SetEntProp(client, Prop_Data, PROP_TAKEDAMAGE_NAME, TAKEDAMAGE_EVENTS_ONLY, PROP_TAKEDAMAGE_SIZE);
			PrintToChat(client, "[JM] %t", "Superman Enabled");
		} else {
			SetEntProp(client, Prop_Data, PROP_TAKEDAMAGE_NAME, TAKEDAMAGE_ENABLED, PROP_TAKEDAMAGE_SIZE);
			PrintToChat(client, "[JM] %t", "Superman Disabled");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
