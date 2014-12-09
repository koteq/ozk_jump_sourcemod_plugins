#pragma semicolon 1

#include <colors>
#include <sdktools>
#include <sourcemod>
#include <jm_stocks>
#undef REQUIRE_PLUGIN
#include <jm_dominations>

#define MAX_CONTROL_POINTS 8
#define MAX_FAKE_CONTROL_POINTS 4
#define CONTROL_POINT_MODEL "models/props_gameplay/cap_point_base.mdl"

public Plugin:myinfo =
{
	name = "JM Control Point",
	author = "Reflex",
	description = "Disables control points",
	version = "$Rev: 42 $"
};

new Handle:g_hScoreForward = INVALID_HANDLE;

new Handle:g_Cvar_IntelPos[3];
new Handle:g_Cvar_ControlPointPos[MAX_FAKE_CONTROL_POINTS][3];

new g_FakeControlPointCount;
new g_RealControlPointCount;
new Float:g_IntelPos[3];
new Float:g_FakeControlPointPos[MAX_FAKE_CONTROL_POINTS][3];

new g_Score[MAXPLAYERS + 1];
new bool:g_Touched[MAXPLAYERS + 1][MAX_CONTROL_POINTS];

new String:g_AchievementSound[32] = "misc/achievement_earned.wav";
new g_AchievementSoundCount = 0;  // tracks how many sounds are emitted at the time

new bool:g_DominationLibraryExists;

public OnPluginStart() {
	LoadTranslations("jm_control_point.phrases");
	
	g_Cvar_IntelPos[0] = CreateConVar("sm_control_point_intel_x", "0.0");
	g_Cvar_IntelPos[1] = CreateConVar("sm_control_point_intel_y", "0.0");
	g_Cvar_IntelPos[2] = CreateConVar("sm_control_point_intel_z", "0.0");
	
	decl String:cvar_name[32];
	for (new i = 0; i < MAX_FAKE_CONTROL_POINTS; i++) {
		Format(cvar_name, sizeof(cvar_name), "sm_control_point_x%d", i);
		g_Cvar_ControlPointPos[i][0] = CreateConVar(cvar_name, "0.0");
		Format(cvar_name, sizeof(cvar_name), "sm_control_point_y%d", i);
		g_Cvar_ControlPointPos[i][1] = CreateConVar(cvar_name, "0.0");
		Format(cvar_name, sizeof(cvar_name), "sm_control_point_z%d", i);
		g_Cvar_ControlPointPos[i][2] = CreateConVar(cvar_name, "0.0");
	}

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("controlpoint_starttouch", Event_ControlPointTouch);
	
	g_hScoreForward = CreateGlobalForward("OnJumpModeScore", ET_Ignore, Param_Cell);
	
	g_DominationLibraryExists = LibraryExists("jm_dominations");
	
	CreateTimer(1.0, Timer_FakeControlPointTouchCheck, _, TIMER_REPEAT);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "jm_dominations")) {
		g_DominationLibraryExists = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "jm_dominations")) {
		g_DominationLibraryExists = true;
	}
}

public OnMapStart() {
	// reset scores
	for (new client = 0; client <= MAXPLAYERS; client++) {
		g_Score[client] = 0;
		for (new i = 0; i < MAX_CONTROL_POINTS; i++) {
			g_Touched[client][i] = false;
		}
	}

	g_AchievementSoundCount = 0;
	PrecacheSound(g_AchievementSound);
	PrecacheModel(CONTROL_POINT_MODEL);
	
	// lets fix unneded behavior of plugin
	// this cvars have to be set per map
	// so it's safe to clear values from previous map
	SetConVarString(g_Cvar_IntelPos[0], "0.0");
	SetConVarString(g_Cvar_IntelPos[1], "0.0");
	SetConVarString(g_Cvar_IntelPos[2], "0.0");
	
	for (new i = 0; i < MAX_FAKE_CONTROL_POINTS; i++) {
		SetConVarString(g_Cvar_ControlPointPos[i][0], "0.0");
		SetConVarString(g_Cvar_ControlPointPos[i][1], "0.0");
		SetConVarString(g_Cvar_ControlPointPos[i][2], "0.0");
	}
}

public OnConfigsExecuted() {
	g_IntelPos[0] = GetConVarFloat(g_Cvar_IntelPos[0]);
	g_IntelPos[1] = GetConVarFloat(g_Cvar_IntelPos[1]);
	g_IntelPos[2] = GetConVarFloat(g_Cvar_IntelPos[2]);
	
	for (new i = 0; i < MAX_FAKE_CONTROL_POINTS; i++) {
		g_FakeControlPointPos[i][0] = GetConVarFloat(g_Cvar_ControlPointPos[i][0]);
		g_FakeControlPointPos[i][1] = GetConVarFloat(g_Cvar_ControlPointPos[i][1]);
		g_FakeControlPointPos[i][2] = GetConVarFloat(g_Cvar_ControlPointPos[i][2]);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = -1;
	decl Float:pos[3];
	g_RealControlPointCount = 0;
	g_FakeControlPointCount = 0;
	
	// init real control points
	while ((ent = FindEntityByClassname(ent, "trigger_capture_area")) != -1)
	{
		SetVariantString("2 0");
		AcceptEntityInput(ent, "SetTeamCanCap");
		SetVariantString("3 0");
		AcceptEntityInput(ent, "SetTeamCanCap");
		g_RealControlPointCount++;
	}
	
	// init intel
	if (!IsZeroVector(g_IntelPos) && (GetEntityCount() < GetMaxEntities() - 32)) {
		ent = CreateEntityByName("item_teamflag");
		pos = g_IntelPos;
		pos[2] -= 66.0;  // 66.0 is getpos z coordinate shift
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
	}

	// init fake control points
	for (new i = 0; i < MAX_FAKE_CONTROL_POINTS; i++) {
		if (IsZeroVector(g_FakeControlPointPos[i])) {
			break;
		}
		
		if (GetEntityCount() >= GetMaxEntities() - 32) {
			LogError("Entity limit is reached. Can't spawn fake control point.");
			break;
		}
		
		ent = CreateEntityByName("prop_dynamic_override");
		SetEntityModel(ent, CONTROL_POINT_MODEL);
		DispatchKeyValue(ent, "disableshadows", "1");
		DispatchKeyValue(ent, "disablereceiveshadows", "1");
		DispatchKeyValue(ent, "Solid", "6");
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 5);
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
		AcceptEntityInput(ent, "DisableCollision");
		AcceptEntityInput(ent, "EnableCollision");
		pos = g_FakeControlPointPos[g_FakeControlPointCount];
		// 66.0 is getpos z coordinate shift
		// 8.0 is intel ground offset
		pos[2] -= 66.0 - 16.0;
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		
		g_FakeControlPointCount++;
	}
}

public Action:Timer_FakeControlPointTouchCheck(Handle:timer)
{
	if (g_FakeControlPointCount == 0) return;
	
	new Float:pos[3];
	for (new client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && IsPlayerAlive(client)) {
			GetClientAbsOrigin(client, pos);
			for (new i = 0; i < g_FakeControlPointCount; i++) {
				// 128.0 is size of control point bounding box
				if (1
					&& pos[0] > g_FakeControlPointPos[i][0] - 128.0
					&& pos[0] < g_FakeControlPointPos[i][0] + 128.0
					&& pos[1] > g_FakeControlPointPos[i][1] - 128.0
					&& pos[1] < g_FakeControlPointPos[i][1] + 128.0
					&& pos[2] > g_FakeControlPointPos[i][2] - 66.0
					&& pos[2] < g_FakeControlPointPos[i][2] + 66.0
					)
				{
					if (!g_Touched[client][g_RealControlPointCount + i]) {
						g_Score[client]++;
						g_Touched[client][g_RealControlPointCount + i] = true;
						ClientScored(client);
					}
				}
			}
		}
	}
}

public Event_ControlPointTouch(Handle:event, const String:caption[], bool:dontBroadcast)
{
	new area = GetEventInt(event, "area");
	new client = GetEventInt(event, "player");
	
	if (!g_Touched[client][area]) {
		g_Score[client]++;	
		g_Touched[client][area] = true;
		ClientScored(client);
	}
}

ClientScored(client)
{
	Call_StartForward(g_hScoreForward);
	Call_PushCell(client);
	Call_Finish();
	
	AttachParticle(client, "achieved");
	EmitAchievementSound();
	
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	
	if (g_DominationLibraryExists) {
		SetNumberOfDominations(client, g_Score[client]);
	}

	if (g_Score[client] == g_RealControlPointCount + g_FakeControlPointCount) {
		CPrintToChatAll("%t", "final cp reached",  name);
	} else {
		CPrintToChatAll("%t", "cp reached", name, g_Score[client], g_RealControlPointCount + g_FakeControlPointCount);
	}
	
	LogToGame("\"%L\" triggered \"jm\" (event \"captured\") (%i of %i)",
			  client, g_Score[client], g_RealControlPointCount + g_FakeControlPointCount);
}

EmitAchievementSound()
{
	if (g_AchievementSoundCount > 3) return;
	g_AchievementSoundCount++;
	
	EmitSoundToAll(g_AchievementSound);
	
	CreateTimer(0.2, Timer_DecreaseAchievementSoundCount, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DecreaseAchievementSoundCount(Handle:timer, any:particle)
{
	g_AchievementSoundCount--;
}

AttachParticle(entity, String:effect_name[])
{
	// TODO ref: check 
	// http://wiki.alliedmods.net/SDKTools_(SourceMod_Scripting)#TempEnt_Functions
	// http://wiki.alliedmods.net/TempEnts_(SourceMod_SDKTools)
	// http://wiki.alliedmods.net/Mod_TempEnt_List_(Source)#Team_Fortress_2
	// [42] TFParticleEffect (CTETFParticleEffect)
	
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return;

	new Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
	
	decl String:target_name[128];
	Format(target_name, sizeof(target_name), "target%i", entity);
	
	DispatchKeyValue(entity, "targetname", target_name);
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", target_name);
	DispatchKeyValue(particle, "effect_name", effect_name);
	DispatchSpawn(particle);
	
	SetVariantString(target_name);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	
	SetVariantString("head");
	AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
	
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	
	CreateTimer(5.0, Timer_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		decl String:classname[256];
		GetEdictClassname(particle, classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}