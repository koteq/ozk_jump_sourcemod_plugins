#if defined _dev_included
 #endinput
#endif
#define _dev_included

stock PrintToMe(const String:message[], any:...)
{
	new client = FindTarget(0, "Reflex", false, false);
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		decl String:buffer[256];
		SetGlobalTransTarget(client);
		VFormat(buffer, sizeof(buffer), message, 2);
		PrintToChat(client, "%s", buffer);
	}
}