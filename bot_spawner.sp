/*  SM Bot Spawner
 *
 *  Copyright (C) 2017-2022 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <cstrike>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "2.0.1"

#pragma newdecls required

Handle g_bots;
EngineVersion game;

public Plugin myinfo =
{
	name = "SM Bot Spawner",
	author = "Franc1sco franug",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	game = GetEngineVersion();
	
	if(game != Engine_CSGO && game != Engine_CSS && game != Engine_TF2)
		SetFailState("Game not supported.");


	CreateConVar("sm_botspawner_version", PLUGIN_VERSION, "", FCVAR_SPONLY|FCVAR_NOTIFY);

	RegAdminCmd("sm_bot", Bot, ADMFLAG_ROOT);
	RegAdminCmd("sm_nobot", NoBot, ADMFLAG_ROOT);

	LoadTranslations("common.phrases");
	
	g_bots = CreateArray();
}

public Action Bot(int client,int args)
{ 
	if (args == 3) {
		
		char szArgs[32];
		float origin[3];
		GetCmdArg(1,szArgs,sizeof(szArgs));
		origin[0] = StringToFloat(szArgs);
		GetCmdArg(2,szArgs,sizeof(szArgs));
		origin[1] = StringToFloat(szArgs);
		GetCmdArg(3,szArgs,sizeof(szArgs));
		origin[2] = StringToFloat(szArgs);
		
		char botname[128];
		Format(botname, sizeof(botname), "Spawned (%i)", GetArraySize(g_bots)+1);
		
		int ent = CreateFakeClient(botname);
			
		if(ent == -1)
			return Plugin_Handled;
			
		PushArrayCell(g_bots, GetClientUserId(ent));
		ChangeClientTeam(ent, GetClientTeam(client) == 2 ? 3:2);
		
		if(game == Engine_CSGO || game == Engine_CSS)
			CS_RespawnPlayer(ent);
		if(game == Engine_TF2)
			TF2_RespawnPlayer(ent);
			
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR); 
		
		return Plugin_Handled;
		
	} else if (args == 0) {
		
		if(client == 0)
		{
			PrintToServer("%t","Command is in-game only");
			return Plugin_Handled;
		}
	
		float start[3], angle[3], end[3], normal[3]; 
		GetClientEyePosition(client, start); 
		GetClientEyeAngles(client, angle); 
	     
		TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, RayDontHitSelf, client); 
		if (TR_DidHit(INVALID_HANDLE)) 
		{ 
			TR_GetEndPosition(end, INVALID_HANDLE); 
			TR_GetPlaneNormal(INVALID_HANDLE, normal); 
			GetVectorAngles(normal, normal); 
			normal[0] += 90.0; 
			
			char botname[128];
			Format(botname, sizeof(botname), "Spawned (%i)", GetArraySize(g_bots)+1);
			
			int ent = CreateFakeClient(botname);
				
			if(ent == -1)
				return Plugin_Handled;
				
			PushArrayCell(g_bots, GetClientUserId(ent));
			ChangeClientTeam(ent, GetClientTeam(client) == 2 ? 3:2);
			
			if(game == Engine_CSGO || game == Engine_CSS)
				CS_RespawnPlayer(ent);
			if(game == Engine_TF2)
				TF2_RespawnPlayer(ent);
				
			TeleportEntity(ent, end, normal, NULL_VECTOR); 
	
		} 
	
		PrintToChat(client, " \x04[BotSpawner] \x01You have spawned a bot");
	
		return Plugin_Handled;
	}
	else {
		ReplyToCommand(client, "[SM] Usage: sm_bot [x] [y] [z] or sm_bot");
		return Plugin_Handled;	
	}
}  

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))return;
	
	int find = FindValueInArray(g_bots, GetClientUserId(client));
	
	if (find == -1)return;
	
	RemoveFromArray(g_bots, find);
}

public Action NoBot(int client,int args)
{ 
	if(GetArraySize(g_bots) == 0)
	{
		if (client > 0) PrintToChat(client, " \x04[BotSpawner] \x01No bots spawned by the !bot command.");
		else ReplyToCommand(client, "No bots spawned by the !bot command.");
		
		return Plugin_Handled;
	}
	int botindex;
	for (int i = 0; i < GetArraySize(g_bots); ++i)
	{
		botindex = GetClientOfUserId(GetArrayCell(g_bots, i));
		
		if (botindex == 0)continue;
		
		KickClient(botindex);
	}
	
	ClearArray(g_bots);
	
	return Plugin_Handled;
	
}

public bool RayDontHitSelf(int entity,int contentsMask, any data) 
{ 
	return (entity != data); 
} 
   