#pragma semicolon 1
	
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "JM HUD Timeleft",
	author = "Reflex",
	description	= "Shows map timeleft on the HUD",
	version = "1.0"
};

#define ENT_TIMER_NAME "hud_timeleft_timer"
#define ENDS_IN_5MIN "vo/announcer_ends_5min.wav"

new Handle:g_hTimerAnnonce5Min = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_RoundStart);
}

public OnMapStart()
{
	PrecacheSound(ENDS_IN_5MIN);
}

public OnMapEnd()
{
	g_hTimerAnnonce5Min = INVALID_HANDLE;
}

public OnMapTimeLeftChanged()
{
	SetHudTimeleft();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetHudTimeleft();
}

SetHudTimeleft()
{
	decl timeleft;
	if (GetMapTimeLeft(timeleft)) {
		new Handle:h_endvote_starttime = FindConVar("sm_umc_endvote_starttime");
		if (h_endvote_starttime != INVALID_HANDLE) {
			timeleft -= GetConVarInt(h_endvote_starttime) * 60;
		}
		SetHudTime(timeleft);
		
		if (g_hTimerAnnonce5Min != INVALID_HANDLE) {
			KillTimer(g_hTimerAnnonce5Min);
		}
		if (timeleft > 300) {
			g_hTimerAnnonce5Min = CreateTimer(float(timeleft - 300), Timer_Annonce5Min, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

SetHudTime(time)
{
	new entity = -1;
	new hud_timeleft_entity = -1;
	decl String:ent_name[32];
	
	while ((entity = FindEntityByClassname(entity, "team_round_timer")) != -1) {
		GetEntPropString(entity, Prop_Data, "m_iName", ent_name, sizeof(ent_name));
		if (StrEqual(ent_name, ENT_TIMER_NAME)) {
			hud_timeleft_entity = entity;
		} else {
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	if (hud_timeleft_entity == -1) {
		hud_timeleft_entity = CreateEntityByName("team_round_timer");
		decl String:timer_length[16];
		IntToString(time, timer_length, sizeof(timer_length));
		DispatchKeyValue(hud_timeleft_entity, "timer_length", timer_length);
		DispatchKeyValue(hud_timeleft_entity, "targetname", ENT_TIMER_NAME);
		DispatchKeyValue(hud_timeleft_entity, "start_paused", "0");
		DispatchKeyValue(hud_timeleft_entity, "show_in_hud", "1");
		DispatchKeyValue(hud_timeleft_entity, "setup_length", "0");
		DispatchKeyValue(hud_timeleft_entity, "reset_time", "0");
		DispatchKeyValue(hud_timeleft_entity, "max_length", "0");
		DispatchKeyValue(hud_timeleft_entity, "auto_countdown", "1");
		DispatchKeyValue(hud_timeleft_entity, "show_time_remaining", "1");
		DispatchSpawn(hud_timeleft_entity);
		AcceptEntityInput(hud_timeleft_entity, "Enable");
	} else {
		SetVariantInt(time);
		AcceptEntityInput(hud_timeleft_entity, "SetTime");
	}
}

public Action:Timer_Annonce5Min(Handle:timer, any:data)
{
	EmitSoundToAll(ENDS_IN_5MIN, SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
	g_hTimerAnnonce5Min = INVALID_HANDLE;
}
