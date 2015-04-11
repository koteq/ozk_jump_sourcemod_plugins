#pragma semicolon 1

#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <tf2items>

#define MAX_BOMBS_OVERRIDE 3
#define MAX_BOMBS_STICKYBOMB_LAUNCHER 8
#define MAX_BOMBS_SCOTTISH_RESISTANCE 14

// https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes
#define ITEM_INDEX_ROCKET_JUMPER 237
#define ITEM_INDEX_STICKYBOMB_JUMPER 265
#define ITEM_INDEX_SCOTTISH_RESISTANCE 130
#define ITEM_INDEX_ULLAPOOL_CABER 307
#define ITEM_INDEX_BASE_JUMPER 1101
#define ITEM_INDEX_LOOSE_CANNON 996

#define WEAPON_CLASS_STICKYBOMB_LAUNCHER "tf_weapon_pipebomblauncher"

// https://wiki.teamfortress.com/wiki/List_of_item_attributes
#define ATTRIBUTE_NO_SELF_BLAST_DMG 181
#define ATTRIBUTE_MAX_PIPEBOMBS_DECREASED 89
#define ATTRIBUTE_PIPE_BOMB_BLAST_RADIUS_INCREACE 99

new Handle:g_hSilentRocketLauncher = INVALID_HANDLE;
new Handle:g_hSilentStickybombLauncher = INVALID_HANDLE;
new Handle:g_hTrainingStickybombLauncher = INVALID_HANDLE;
new Handle:g_hTrainingScottishResistance = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "JM Weapon Attributes",
    author = "Reflex",
    description = "Disables annoing jumper sound and stripp off 8x pipe jump",
    version = "1.0"
};

public OnPluginStart()
{
    g_hSilentRocketLauncher = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES);
    TF2Items_SetNumAttributes(g_hSilentRocketLauncher, 0);
    
    g_hSilentStickybombLauncher = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES);
    TF2Items_SetNumAttributes(g_hSilentStickybombLauncher, 1);
    TF2Items_SetAttribute(g_hSilentStickybombLauncher, 0, ATTRIBUTE_MAX_PIPEBOMBS_DECREASED, float(-MAX_BOMBS_STICKYBOMB_LAUNCHER + MAX_BOMBS_OVERRIDE));
    
    g_hTrainingStickybombLauncher = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
    TF2Items_SetNumAttributes(g_hTrainingStickybombLauncher, 1);
    TF2Items_SetAttribute(g_hTrainingStickybombLauncher, 0, ATTRIBUTE_MAX_PIPEBOMBS_DECREASED, float(-MAX_BOMBS_STICKYBOMB_LAUNCHER + MAX_BOMBS_OVERRIDE));
    
    g_hTrainingScottishResistance = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
    TF2Items_SetNumAttributes(g_hTrainingScottishResistance, 1);
    TF2Items_SetAttribute(g_hTrainingScottishResistance, 0, ATTRIBUTE_MAX_PIPEBOMBS_DECREASED, float(-MAX_BOMBS_SCOTTISH_RESISTANCE + MAX_BOMBS_OVERRIDE));
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
    //PrintToChatAll("%N got %s [%d]", client, classname, iItemDefinitionIndex);
    
    if (iItemDefinitionIndex == ITEM_INDEX_ROCKET_JUMPER) {
        hItem = g_hSilentRocketLauncher;
        return Plugin_Changed;
    }
    
    if (iItemDefinitionIndex == ITEM_INDEX_STICKYBOMB_JUMPER) {
        hItem = g_hSilentStickybombLauncher;
        return Plugin_Changed;
    }
    
    if (iItemDefinitionIndex == ITEM_INDEX_SCOTTISH_RESISTANCE) {
        hItem = g_hTrainingScottishResistance;
        return Plugin_Changed;
    }
    
    if (StrEqual(classname, WEAPON_CLASS_STICKYBOMB_LAUNCHER)) {
        hItem = g_hTrainingStickybombLauncher;
        return Plugin_Changed;
    }
    
    // block ullapool caber
    if (iItemDefinitionIndex == ITEM_INDEX_ULLAPOOL_CABER) {
        return Plugin_Stop;
    }
    
    // block parachute
    if (iItemDefinitionIndex == ITEM_INDEX_BASE_JUMPER) {
        return Plugin_Stop;
    }
    
    // block loose cannon
    //if (iItemDefinitionIndex == ITEM_INDEX_LOOSE_CANNON) {
    //    return Plugin_Stop;
    //}
    
    return Plugin_Continue;
}
