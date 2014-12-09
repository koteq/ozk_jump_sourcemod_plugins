#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "JM Spectator Anchor",
	author = "Reflex",
	description = "Anchors observers to their corpses",
	version = "$Rev: 44 $"
};

public OnPluginStart()
{
	AddCommandListener(CommandListener, "jointeam");
	AddCommandListener(CommandListener, "spectate");
}

public Action:CommandListener(client, const String:command[], argc)
{
	new String:args[9];
	if (argc) {
		GetCmdArgString(args, sizeof(args));
	}
	if (StrEqual(command, "spectate", false) ||
	    StringToInt(args) == 1 ||
		StrContains(args, "spec", false) != -1)
	{
		new Float:angle[3];
		new Float:position[3];

		GetClientEyeAngles(client, angle);
		GetClientAbsOrigin(client, position);
		position[2] += 73.0;  // player height offset

		// TODO: ref: ask community about pros & cons DataTimer vs. Globals
		new Handle:datapack;
		CreateDataTimer(0.1, TeleportSpectator, datapack);
		
		WritePackCell(datapack, client);
		
		WritePackFloat(datapack, angle[0]);
		WritePackFloat(datapack, angle[1]);
		WritePackFloat(datapack, angle[2]);
		
		WritePackFloat(datapack, position[0]);
		WritePackFloat(datapack, position[1]);
		WritePackFloat(datapack, position[2]);
	}
	
	return Plugin_Continue;
}

public Action:TeleportSpectator(Handle:timer, Handle:datapack)
{
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	
	if (IsClientInGame(client) && IsClientObserver(client))
	{
		new Float:angle[3];
		new Float:position[3];
		
		angle[0] = ReadPackFloat(datapack);
		angle[1] = ReadPackFloat(datapack);
		angle[2] = ReadPackFloat(datapack);
		
		position[0] = ReadPackFloat(datapack);
		position[1] = ReadPackFloat(datapack);
		position[2] = ReadPackFloat(datapack);
		
		//FakeClientCommand(client, "spec_mode 6");  // set freelook mode
		SetEntProp(client, Prop_Send, "m_iObserverMode", 6);  // set freelook mode
		TeleportEntity(client, position, angle, NULL_VECTOR);
	}
}