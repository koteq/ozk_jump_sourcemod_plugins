#if defined _dev_included
 #endinput
#endif
#define _dev_included

stock DevPrintToChat(const String:message[], any: ...)
{
    new client = FindReflex();
    if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
        decl String:buffer[256];
        SetGlobalTransTarget(client);
        VFormat(buffer, sizeof(buffer), message, 2);
        PrintToChat(client, "%s", buffer);
    }
}

stock DevPrintToConsole(const String:message[], any: ...)
{
    new client = FindReflex();
    if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
        decl String:buffer[256];
        SetGlobalTransTarget(client);
        VFormat(buffer, sizeof(buffer), message, 2);
        PrintToConsole(client, "%s", buffer);
    }
}

stock FindReflex()
{
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[1], target_count, bool:tn_is_ml;

    new flags = COMMAND_FILTER_NO_MULTI;
    flags |= COMMAND_FILTER_NO_BOTS;
    flags |= COMMAND_FILTER_NO_IMMUNITY;

    if ((target_count = ProcessTargetString(
                "Reflex",
                0,
                target_list,
                1,
                flags,
                target_name,
                sizeof(target_name),
                tn_is_ml)) > 0) {
        return target_list[0];
    }
    else {
        return -1;
    }
}
