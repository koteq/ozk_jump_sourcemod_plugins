#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "JM SoundHook",
	author = "Reflex",
	description = "Mutes some annoing sounds",
	version = "$Rev: 42 $"
};

public OnPluginStart()
{
	AddNormalSoundHook(NormalSHook:SoundHook);
}

public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrEqual(sample, "items/regenerate.wav", false) ||
	    StrEqual(sample, "items/ammo_pickup.wav", false) ||
	    StrContains(sample, "_painsevere", false) != -1
	) {
		numClients = 0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
