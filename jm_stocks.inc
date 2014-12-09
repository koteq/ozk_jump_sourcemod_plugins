#if defined _jm_stocks_included
 #endinput
#endif
#define _jm_stocks_included

stock bool:IsValidClient(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool:IsAdmin(client, AdminFlag:flag = Admin_Generic)
{
	new AdminId:admin = GetUserAdmin(client);

	if (admin != INVALID_ADMIN_ID) {
		return GetAdminFlag(admin, flag);
	}
			
	return false;
}

stock Float:ZERO_VECTOR[3] = {0.0, 0.0, 0.0};

stock bool:IsZeroVector(const Float:vector[3])
{
	return vector[0] == 0.0 && vector[1] == 0.0 && vector[2] == 0.0;
}