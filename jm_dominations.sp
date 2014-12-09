#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "JM Dominations",
	author = "Reflex",
	description = "Allow others plugins to set number of dominations",
	version = "$Rev: 42 $"
};

new Handle:g_hSetNumberOfDominations = INVALID_HANDLE;

public OnPluginStart() {
	new Handle:config_handle = LoadGameConfigFile("jm_dominations.games");
	if (config_handle != INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(config_handle, SDKConf_Signature, "SetNumberOfDominations");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetNumberOfDominations = EndPrepSDKCall();
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("jm_dominations");	
	CreateNative("SetNumberOfDominations", Native_SetNumberOfDominations);
	return APLRes_Success;
}

/* native SetNumberOfDominations(client, count); */
public Native_SetNumberOfDominations(Handle:plugin, numParams)
{	
	if (g_hSetNumberOfDominations != INVALID_HANDLE) {
		SDKCall(g_hSetNumberOfDominations, GetNativeCell(1), GetNativeCell(2));
	}
}