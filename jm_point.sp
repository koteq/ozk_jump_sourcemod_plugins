#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include "dev.inc"

public Plugin:myinfo = {
    name = "JM Point",
    author = "Reflex",
    description = "Ranks for players",
    version = "1.0"
};

#define TRIGGER_NAME_PREFIX "_jm_point_"
#define MODEL_POINT_BASE "models/props_gameplay/cap_point_base.mdl"
#define MODEL_POINT_BASE_SMALL "models/props_doomsday/cap_point_small.mdl"

new g_iControlPointsCount;
new bool:g_bLateLoading = false;
new Handle:g_hPointsCaptionsTrie = INVALID_HANDLE;
new Handle:g_hOnStartTouchForward = INVALID_HANDLE;
new Handle:g_hOnPointsCountChangedForward = INVALID_HANDLE;

enum ControlPointType {
    ControlPointType_Default,
    ControlPointType_Small,
    ControlPointType_IntelOnly,
    ControlPointType_IntelPoint,
    ControlPointType_TriggerOnly,
}

public OnPluginStart()
{
    g_hPointsCaptionsTrie = CreateTrie();
    HookEvent("teamplay_round_start", Event_RoundStart);
    HookEntityOutput("trigger_multiple", "OnStartTouch", EntityOutput_OnStartTouch);

    if (g_bLateLoading) {
        CreatePointsFromSettings();
    }
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    g_bLateLoading = late;

    g_hOnStartTouchForward = CreateGlobalForward("JM_Point_OnStartTouch", ET_Ignore, Param_Cell, Param_Cell, Param_String);
    g_hOnPointsCountChangedForward = CreateGlobalForward("JM_Point_OnPointsCountChanged", ET_Ignore, Param_Cell);
    
    RegPluginLibrary("jm_point");  

    return APLRes_Success;
}

public OnPluginEnd()
{
    if (g_hPointsCaptionsTrie != INVALID_HANDLE) {
        CloseHandle(g_hPointsCaptionsTrie);
    }
}

public OnMapStart()
{
    PrecacheModel(MODEL_POINT_BASE);
    PrecacheModel(MODEL_POINT_BASE_SMALL);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    CreatePointsFromSettings();
}

public EntityOutput_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
    new String:sTargetName[32];
    GetEntPropString(caller, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
    if (StrContains(sTargetName, TRIGGER_NAME_PREFIX) == 0) {
        decl String:sPointId[3];
        strcopy(sPointId, sizeof(sPointId), sTargetName[strlen(TRIGGER_NAME_PREFIX)]);
        new pointId = StringToInt(sPointId);

        new String:pointCaption[64];
        GetTrieString(g_hPointsCaptionsTrie, sPointId, pointCaption, sizeof(pointCaption));

        Call_StartForward(g_hOnStartTouchForward);
        Call_PushCell(activator);
        Call_PushCell(pointId);
        Call_PushString(pointCaption);
        Call_Finish();
    }
}

CreatePointsFromSettings()
{
    g_iControlPointsCount = GetEntityCountByClassname("trigger_capture_area");
    
    ClearTrie(g_hPointsCaptionsTrie);

    new Handle:kv = CreateKeyValues("JM Point");

    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/jm_point.cfg");

    if (FileToKeyValues(kv, path)) {
        decl String:map[64];
        GetCurrentMap(map, sizeof(map));

        if (KvJumpToKey(kv, map)) {
            if (KvGotoFirstSubKey(kv, false)) {
                decl String:key[64];
                decl String:value[128];

                do {
                    KvGetSectionName(kv, key, sizeof(key));
                    KvGetString(kv, NULL_STRING, value, sizeof(value));

                    new ControlPointType:type;
                    new Float:origin[3];
                    ParseTypeAndOrigin(value, type, origin);

                    origin[2] -= 68.0;  // getpos height shift

                    new pointId = CreateControlPoint(origin, type);
                    if (pointId != -1) {
                        decl String:sPointId[3];
                        IntToString(pointId, sPointId, sizeof(sPointId));
                        SetTrieString(g_hPointsCaptionsTrie, sPointId, key);
                    }
                } while (KvGotoNextKey(kv, false));

                Call_StartForward(g_hOnPointsCountChangedForward);
                Call_PushCell(g_iControlPointsCount);
                Call_Finish();
            }
            else {
                // Section empty
            }
        }
        else {
            // Section not found
        }
    }
    else {
        SetFailState("Error in %s: File not found, corrupt or in the wrong format", path);
    }

    CloseHandle(kv);
} /* CreatePointsFromSettings */

ParseTypeAndOrigin(const String:str[], &ControlPointType:type, Float:origin[3])
{
    new pos;
    new arg;
    new next;
    decl String:buff[64];
    origin = NULL_VECTOR;
    type = ControlPointType_Default;

    for (;;) {
        next = BreakString(str[pos], buff, sizeof(buff));

        switch (arg)
        {
            case 0, 1, 2: {
                origin[arg] = StringToFloat(buff);
            }
            case 3: {
                if (StrEqual(buff, "intel_only")) {
                    type = ControlPointType_IntelOnly;
                }
                else if (StrEqual(buff, "intel_point")) {
                    type = ControlPointType_IntelPoint;
                }
                else if (StrEqual(buff, "trigger_only")) {
                    type = ControlPointType_TriggerOnly;
                }
                else if (StrEqual(buff, "small_point")) {
                    type = ControlPointType_Small;
                }
            }
        }

        if (next != -1) {
            pos += next;
            arg++;
        }
        else {
            break;
        }
    }
}

// returns internal area index or -1
CreateControlPoint(const Float:origin[3], ControlPointType:type = ControlPointType_Default)
{
    switch (type) {
        case ControlPointType_Default: {
            CreateControlPointBase(origin);
            return CreateTrigger(origin);
        }
        case ControlPointType_Small: {
            CreateControlPointBase(origin, true);
            return CreateTrigger(origin, true);
        }
        case ControlPointType_IntelOnly: {
            CreateIntel(origin);
            return -1;
        }
        case ControlPointType_IntelPoint: {
            CreateIntel(origin);
            CreateControlPointBase(origin);  // still needed to reveal trigger position
            return CreateTrigger(origin);
        }
        case ControlPointType_TriggerOnly: {
            return CreateTrigger(origin);
        }
    }
    return -1;
}

// returns internal area index or -1
CreateTrigger(const Float:origin[3], bool:small = false)
{
    // spawnflags howto:
    // create entity in hammer
    // open entity properties and check needed flags
    // on first tab uncheck SmartEdit button and copy spawnflags value

    new trigger = CreateEntityByName("trigger_multiple");

    if (trigger != -1) {
        decl String:sTargetName[64];
        Format(sTargetName, sizeof(sTargetName), "%s%d", TRIGGER_NAME_PREFIX, g_iControlPointsCount);
        DispatchKeyValue(trigger, "targetname", sTargetName);

        DispatchKeyValue(trigger, "spawnflags", "1");  // clients can touch
        DispatchSpawn(trigger);
        ActivateEntity(trigger);
        TeleportEntity(trigger, origin, NULL_VECTOR, NULL_VECTOR);

        // magic stright ahead
        // details here https://forums.alliedmods.net/showthread.php?t=129597

        // set model to enable bounding box usage (wont be visible)
        SetEntityModel(trigger, MODEL_POINT_BASE);

        // set bounding box
        new Float:minbounds[3] = {-100.0, -100.0, 10.0};
        new Float:maxbounds[3] = {100.0, 100.0, 50.0};
        if (small) {
            minbounds = Float:{-32.0, -32.0, 10.0};
            maxbounds = Float:{32.0, 32.0, 50.0};
        }
        SetEntPropVector(trigger, Prop_Send, "m_vecMins", minbounds);
        SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxbounds);

        // change solid type to bounding box
        SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);

        // add nodraw flag to prevent console errors spam
        new effects = GetEntProp(trigger, Prop_Send, "m_fEffects");
        effects |= 32;  // nodraw
        SetEntProp(trigger, Prop_Send, "m_fEffects", effects);

        return g_iControlPointsCount++;
    }

    return -1;
}

CreateControlPointBase(const Float:origin[3], bool:small = false)
{
    new base = CreateEntityByName("prop_dynamic");

    if (base != -1) {
        if (small) {
            SetEntityModel(base, MODEL_POINT_BASE_SMALL);
        }
        else {
            SetEntityModel(base, MODEL_POINT_BASE);
        }
        DispatchKeyValue(base, "disableshadows", "1");
        DispatchKeyValue(base, "disablereceiveshadows", "1");
        DispatchKeyValue(base, "spawnflags", "256");  // start with collision disabled
        DispatchSpawn(base);
        TeleportEntity(base, origin, NULL_VECTOR, NULL_VECTOR);
    }

    return base;
}

CreateIntel(const Float:origin[3])
{
    new intel = CreateEntityByName("item_teamflag");
    if (intel != -1) {
        // plase intel abit higher
        decl Float:intelOrigin[3];
        AddVectors(origin, Float:{0.0, 0.0, 20.0}, intelOrigin);

        DispatchKeyValue(intel, "trail_effect", "0");
        // do mind the order of teleport and dispatch
        // intel will remember self position on spawn
        // and, if dropped, intel will return to that position
        TeleportEntity(intel, intelOrigin, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(intel);
    }
}

GetEntityCountByClassname(const String:classname[])
{
    new count = 0;
    new entity = -1;
    while ((entity = FindEntityByClassname(entity, classname)) != -1) {
        count += 1;
    }

    return count;
}
