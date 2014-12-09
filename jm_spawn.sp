#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <jm_stocks>

#undef REQUIRE_PLUGIN
#include <jm_noob_mark>
#define REQUIRE_PLUGIN

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>

#define ENTITY_ANTI_CRASH_GAP 64
#define ENTITY_AUTOKILL_TIME 900.0

#define MDL_GIFT "models/props_halloween/halloween_gift.mdl"
#define MDL_PALLET "models/props_farm/pallet001.mdl"

new bool:g_bLibrary_SdkHooks;
new bool:g_bLibrary_JmNoobMark;

#define PROPS_ARRAY_LIMIT 1000
new g_PropsArr_EntId[PROPS_ARRAY_LIMIT + 1];
new g_PropsArr_Qwner[PROPS_ARRAY_LIMIT + 1];

public Plugin:myinfo = {
	name = "Junk spawner",
	author = "Reflex, Jocker",
	description = "Allows admins to spawn various junk"
};

public OnPluginStart()
{
	RegAdminCmd("sm_gift", Command_SpawnGift, ADMFLAG_CUSTOM3, "Spawn gift");
	RegAdminCmd("sm_pump", Command_SpawnPumpkin, ADMFLAG_CUSTOM3, "Spawn pumpkin");
	RegAdminCmd("sm_pallet", Command_SpawnPallet, ADMFLAG_CUSTOM3, "Spawn pallet");
	RegAdminCmd("sm_rm", Command_RemoveObject, ADMFLAG_CUSTOM3, "Remove any spawned object");
}

public OnAllPluginsLoaded()
{
	g_bLibrary_SdkHooks = LibraryExists("sdkhooks");
	g_bLibrary_JmNoobMark = LibraryExists("jm_noob_mark");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sdkhooks")) {
		g_bLibrary_SdkHooks = true;
	}
	else if (StrEqual(name, "jm_noob_mark"))
	{
		g_bLibrary_JmNoobMark = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sdkhooks")) {
		g_bLibrary_SdkHooks = false;
	}
	else if (StrEqual(name, "jm_noob_mark"))
	{
		g_bLibrary_JmNoobMark = false;
	}
}

public OnMapStart()
{
	PrecacheModel(MDL_GIFT, true);
	PrecacheModel(MDL_PALLET, true);
}

public OnClientConnected(client)
{
	PropsArr_DestroyClientProps(client);
}

// COMMANDS
public Action:Command_SpawnGift(client, args)
{
	new Float:spawnPoint[3];
	new bool:traceSucceed = TracePoint(client, spawnPoint);
	
	if (!traceSucceed) {
		ReplyToCommand(client, "[SM] Could not trace spawn point.");
		return Plugin_Handled;
	}
	
	MovePointCloserToClient(client, spawnPoint, 35.0);
	spawnPoint[2] -= 10.0;

	if (IsEntityLimitReached()) {
		ReplyToCommand(client, "[SM] Entity limit is reached.");
		return Plugin_Handled;
	}

	new ent = CreateEntityByName("prop_physics_override");
	
	if (IsValidEntity(ent)) {
		PropsArr_Push(client, ent);
	
		if (g_bLibrary_JmNoobMark) {
			JM_NoobMark_Activate(client);
		}
		
		SetEntityModel(ent, MDL_GIFT);
		
		DispatchKeyValue(ent, "StartDisabled", "false");
		DispatchKeyValue(ent, "ExplodeDamage", "0");
		DispatchKeyValue(ent, "ExplodeRadius", "100");
		DispatchSpawn(ent);
		
		TeleportEntity(ent, spawnPoint, NULL_VECTOR, NULL_VECTOR);

		SetEntityMoveType(ent, MOVETYPE_NONE);
		
		SetEntProp(ent, Prop_Data, "m_takedamage", 2);
		
		decl String:autokill[64];
		Format(autokill, sizeof(autokill), "OnUser1 !self:kill::%f:1", ENTITY_AUTOKILL_TIME);
		SetVariantString(autokill);
		
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
		AcceptEntityInput(ent, "Enable");
		
		HookSingleEntityOutput(ent, "OnBreak", OnGiftBreak, true);
		
		if (g_bLibrary_SdkHooks) {
			SDKHook(ent, SDKHook_Touch, OnGiftTouch);
		}
	}

	return Plugin_Handled;
} /* Command_SpawnGift */

public Action:Command_SpawnPumpkin(client, args)
{
	new Float:spawnPoint[3];
	new bool:traceSucceed = TracePoint(client, spawnPoint);
	
	if (!traceSucceed) {
		ReplyToCommand(client, "[SM] Could not trace spawn point.");
		return Plugin_Handled;
	}

	if (IsClientLookingAtPumpkin(client)) {
		MovePointCloserToClient(client, spawnPoint, 35.0);
		spawnPoint[2] -= 17.0;
	}

	if (IsEntityLimitReached()) {
		ReplyToCommand(client, "[SM] Entity limit is reached.");
		return Plugin_Handled;
	}

	new ent = CreateEntityByName("tf_pumpkin_bomb");

	if (IsValidEntity(ent)) {
		PropsArr_Push(client, ent);
		
		if (g_bLibrary_JmNoobMark) {
			JM_NoobMark_Activate(client);
		}
		
		DispatchSpawn(ent);
		
		TeleportEntity(ent, spawnPoint, NULL_VECTOR, NULL_VECTOR);

		decl String:autokill[64];
		Format(autokill, sizeof(autokill), "OnUser1 !self:kill::%f:1", ENTITY_AUTOKILL_TIME);
		SetVariantString(autokill);
		
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}

	return Plugin_Handled;
} /* Command_SpawnPumpkin */

public Action:Command_SpawnPallet(client, args)
{
	if (IsEntityLimitReached()) {
		ReplyToCommand(client, "[SM] Entity limit is reached.");
		return Plugin_Handled;
	}

	new ent = CreateEntityByName("prop_dynamic_override");

	if (IsValidEntity(ent)) {
		PropsArr_Push(client, ent);
		
		if (g_bLibrary_JmNoobMark) {
			JM_NoobMark_Activate(client);
		}
		
		SetEntityModel(ent, MDL_PALLET);
		
		DispatchKeyValue(ent, "disableshadows", "1");
		DispatchKeyValue(ent, "disablereceiveshadows", "1");

		DispatchSpawn(ent);
		
		DispatchKeyValue(ent, "Solid", "6");

		SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 5);
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
		
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);

		AcceptEntityInput(ent, "DisableCollision");
		AcceptEntityInput(ent, "EnableCollision");

		decl String:autokill[64];
		Format(autokill, sizeof(autokill), "OnUser1 !self:kill::%f:1", ENTITY_AUTOKILL_TIME);
		SetVariantString(autokill);
		
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");

		decl Float:spawnPos[3];
		GetClientAbsOrigin(client, spawnPos);
		spawnPos[2] -= 5;
		
		decl Float:spawnAngle[3];
		GetClientEyeAngles(client, spawnAngle);
		spawnAngle[0] = 0.0;
		spawnAngle[2] = 0.0;
		
		decl Float:spawnVector[3];
		GetAngleVectors(spawnAngle, spawnVector, NULL_VECTOR, NULL_VECTOR);

		NormalizeVector(spawnVector, spawnVector);
		ScaleVector(spawnVector, 47.0);
		AddVectors(spawnPos, spawnVector, spawnPos);

		TeleportEntity(ent, spawnPos, spawnAngle, NULL_VECTOR);
	}

	return Plugin_Handled;
} /* Command_SpawnPallet */

public Action:Command_RemoveObject(client, args)
{
	new ent = TraceEntity(client);

	if (!IsValidEdict(ent)) {
		return Plugin_Handled;
	}

	decl String:name[64];
	GetEntPropString(ent, Prop_Data, "m_iClassname", name, sizeof(name));

	if (StrEqual(name, "tf_pumpkin_bomb")) {
		RemoveEdict(ent);
		return Plugin_Handled;
	}

	if (StrEqual(name, "headless_hatman")) {
		Dissolve(ent);
		return Plugin_Handled;
	}

	if (StrEqual(name, "tf_zombie")) {
		Dissolve(ent);
		return Plugin_Handled;
	}

	if (StrEqual(name, "eyeball_boss")) {
		Dissolve(ent);
		return Plugin_Handled;
	}

	if (StrEqual(name, "prop_physics")) {
		decl String:m_ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(ent, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));

		if (StrEqual(m_ModelName, MDL_GIFT)) {
			RemoveEdict(ent);
			return Plugin_Handled;
		}
		if (StrEqual(m_ModelName, MDL_PALLET)) {
			RemoveEdict(ent);
			return Plugin_Handled;
		}
	}

	if (StrEqual(name, "prop_dynamic")) {
		decl String:m_ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(ent, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));

		if (StrEqual(m_ModelName, MDL_PALLET)) {
			RemoveEdict(ent);
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
} /* Command_RemoveObject */

public JM_NoobMark_OnBeforeDeactivate(client)
{
	PropsArr_DestroyClientProps(client);
}

bool:IsEntityLimitReached()
{
	new entCount = GetEntityCount();
	new entCountMax = GetMaxEntities() - ENTITY_ANTI_CRASH_GAP;
	new bool:entCountOk = (entCount >= entCountMax);
	new bool:entStoreOk = (PropsArr_GetFreeSlot() > -1);
	
	return entCountOk && entStoreOk;
}

PropsArr_DestroyClientProps(client)
{
	for (new i = 0; i <= PROPS_ARRAY_LIMIT; i++) {
		if (g_PropsArr_Qwner[i] == client) {
			if (IsValidEntity(g_PropsArr_EntId[i])) {
				RemoveEdict(g_PropsArr_EntId[i]);
			}
			g_PropsArr_EntId[i] = -1;
			g_PropsArr_Qwner[i] = -1;
		}
	}
}

PropsArr_Push(client, ent)
{
	new slotId = PropsArr_GetFreeSlot();
	if (slotId == -1) return;
	
	g_PropsArr_EntId[slotId] = ent;
	g_PropsArr_Qwner[slotId] = client;
}

PropsArr_GetFreeSlot()
{
	for (new i = 0; i <= PROPS_ARRAY_LIMIT; i++) {
		if (!(IsValidEntity(g_PropsArr_EntId[i]) && IsValidClient(g_PropsArr_Qwner[i]))) {
			return i;
		}
	}
	
	return -1;
}

bool:IsClientLookingAtPumpkin(client)
{
	new ent = TraceEntity(client);
	decl String:name[64];
	GetEntPropString(ent, Prop_Data, "m_iClassname", name, sizeof(name));
	
	return StrEqual(name, "tf_pumpkin_bomb");
}

TraceEntity(client)
{
	decl Float:rayStartPosition[3];
	GetClientEyePosition(client, rayStartPosition);
	
	decl Float:rayAngles[3];
	GetClientEyeAngles(client, rayAngles);
	
	new Handle:ray = TR_TraceRayFilterEx(rayStartPosition, rayAngles, MASK_SOLID, RayType_Infinite, TraceFilter_SkipPlayersAndTriggers);
	new entity = TR_GetEntityIndex(ray);
	CloseHandle(ray);

	return entity;
}

bool:TracePoint(client, Float:point[3])
{
	decl Float:rayStartPosition[3];
	GetClientEyePosition(client, rayStartPosition);
	
	decl Float:rayAngles[3];
	GetClientEyeAngles(client, rayAngles);
	
	new Handle:ray = TR_TraceRayFilterEx(rayStartPosition, rayAngles, MASK_SOLID, RayType_Infinite, TraceFilter_SkipPlayersAndTriggers);
	if (TR_DidHit(ray)) {
		TR_GetEndPosition(point, ray);
		CloseHandle(ray);
		return true;
	}
	
	CloseHandle(ray);
	return false;
}

MovePointCloserToClient(client, Float:point[3], Float:distance)
{
	decl Float:eyePosition[3];
	GetClientEyePosition(client, eyePosition);

	decl Float:eyeAngles[3];
	GetClientEyeAngles(client, eyeAngles);
	
	decl Float:eyeVector[3];
	GetAngleVectors(eyeAngles, eyeVector, NULL_VECTOR, NULL_VECTOR);

	point[0] -= eyeVector[0] * distance;
	point[1] -= eyeVector[1] * distance;
	point[2] -= eyeVector[2] * distance;
}

public bool:TraceFilter_SkipPlayersAndTriggers(entity, contentsMask)
{
	// skip players
	if (entity <= MaxClients) {
		return false;
	}
	
	decl String:entClassname[64];
	GetEntPropString(entity, Prop_Data, "m_iClassname", entClassname, sizeof(entClassname));
	
	// skip respawn visualizer
	if (StrEqual("func_respawnroomvisualizer", entClassname)) {
		return false;
	}
	
	return true;
}

Dissolve(ent)
{
	if (!IsValidEntity(ent)) {
		return;
	}

	new dissolver = CreateEntityByName("env_entity_dissolver");
	if (dissolver > 0) {
		decl String:dissolverName[32];
		Format(dissolverName, sizeof(dissolverName), "dis_%d", EntIndexToEntRef(ent));
		DispatchKeyValue(dissolver, "target", dissolverName);
		
		// it's right, we're dispatching ent's value here
		DispatchKeyValue(ent, "targetname", dissolverName);
		
		DispatchKeyValue(dissolver, "magnitude", "10");
		DispatchKeyValue(dissolver, "dissolvetype", "0");

		AcceptEntityInput(dissolver, "Dissolve");
		AcceptEntityInput(dissolver, "Kill");
	}
}

public OnGiftTouch(entity, other)
{
	new rnd = GetRandomInt(0, 5);
	switch (rnd)
	{
		case 0: {
			if (IsValidClient(other) && IsPlayerAlive(other)) {
				TF2_StunPlayer(other, 3.0, _, TF_STUNFLAGS_LOSERSTATE);
			}
		}
		case 1: {
			if (IsValidClient(other) && IsPlayerAlive(other)) {
				TF2_StunPlayer(other, 3.0, _, TF_STUNFLAGS_BIGBONK);
			}
		}
		case 2: {
			if (IsValidClient(other) && IsPlayerAlive(other)) {
				TF2_StunPlayer(other, 3.0, _, TF_STUNFLAGS_GHOSTSCARE);
			}
		}
		case 3: {
			if (IsValidClient(other) && IsPlayerAlive(other)) {
				TF2_AddCondition(other, TFCond_Ubercharged, 10.0);
			}
		}
		case 4: {
			if (IsValidClient(other) && IsPlayerAlive(other)) {
				TF2_AddCondition(other, TFCond_Kritzkrieged, 10.0);
			}
		}
		case 5: {
			if (IsValidClient(other) && IsPlayerAlive(other)) {
				TF2_AddCondition(other, TFCond_OnFire, 3.0);
			}
		}
	}
	OnGiftBreak(NULL_STRING, entity, other, 0.0);
} /* OnGiftTouch */

public OnGiftBreak(const String:output[], caller, activator, Float:delay)
{
	UnhookSingleEntityOutput(caller, "OnBreak", OnGiftBreak);
	AcceptEntityInput(caller, "kill");
}
