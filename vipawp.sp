#pragma semicolon 1

// #define DEBUG

#define PLUGIN_AUTHOR "Jake"
#define PLUGIN_VERSION "1.0"
#define PREFIX " \x0C[Intensity]\x01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new credits[64];

ConVar g_cvarAWPCost;
ConVar g_cvarHalfTime;
ConVar g_cvarKillCredits;
ConVar g_cvarVIPCredits;
ConVar g_cvarVIPFlag;

public Plugin myinfo =
{
	name = "AWP Shop",
	author = PLUGIN_AUTHOR,
	description = "Allows players to earn and exchange credits for AWP",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart() {
	LoadTranslations("awpshop.phrases");
	RegisterAdminCommands();
	RegisterConsoleCommands();
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("cs_match_end_restart", Event_MatchEnd);

	AutoExecConfig(true, "vipawp");
	g_cvarAWPCost = CreateConVar("vipawp_awpcost", "5", "How many credits the awp will cost");
	g_cvarHalfTime = CreateConVar("vipawp_HalfTime", "15", "The round at which you switch sides (mp_maxrounds(30) / 2 = 15)");
	g_cvarKillCredits = CreateConVar("vipawp_killcredits", "1", "How many credits to give to the player for a kill");
	g_cvarVIPCredits = CreateConVar("vipawp_addCredits", "2", "How many credits you want your VIP players to have");
	g_cvarVIPFlag = CreateConVar("vipawp_VIPFlag", "ADMFLAG_RESERVATION", "What admin flag do you have set for VIP players. For flags check -> https://wiki.alliedmods.net/Checking_Admin_Flags_(SourceMod_Scripting)");
	CreateConVar("sm_vipawp_version", PLUGIN_VERSION, "VIP AWP Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
}

void RegisterAdminCommands()
{
	RegAdminCmd("sm_givecredits", Command_GiveCredits, ADMFLAG_RESERVATION, "Give players credits");
	RegAdminCmd("sm_credits", Command_Credits, ADMFLAG_RESERVATION, "Checks how many credits the user has");
	RegAdminCmd("sm_awp", Command_BuyAWP, ADMFLAG_RESERVATION, "Gives awp in exchange for credits");
}

void RegisterConsoleCommands()
{
	#if defined DEBUG
	RegConsoleCmd("sm_colours", Command_Colours, "Prints colours in chat");
	#endif
}

// When the player connects set their credits to 0
public void OnClientConnected(int client) {
	new addCredits = 0;
	credits[client] = addCredits;
}

// When a player dies give the attacker x amount of credits and print a message to their chat
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	char victimname[64];
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	GetClientName(victim, victimname, sizeof(victimname));

	int killCreds = GetConVarInt(g_cvarKillCredits);
	int vipCreds = GetConVarInt(g_cvarVIPCredits);
	int vipFlag = GetConVarInt(g_cvarVIPFlag);
	// Giving attacker credits
	new creds = credits[attacker];
	if (CheckCommandAccess(attacker, "admin_check", vipFlag))
	{
		new addVIPCredits = creds + vipCreds;
		credits[attacker] = addVIPCredits;
		PrintToChat(attacker, "%s\x04 You were given \x0B%d\x04 credit(s) for killing \x0B%s\x04.", PREFIX, vipCreds, victimname);
	}
	else
	{
		new addCredits = creds + killCreds;
		credits[attacker] = addCredits;
		PrintToChat(attacker, "%s\x04 You were given \x0B%d\x04 credit(s) for killing \x0B%s\x04.", PREFIX, killCreds, victimname);
	}
}

// When the game ends, reset credits to 0 again
public void Event_MatchEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
    {
        credits[i] = 0;
    }
}

// When someone uses the command to get an AWP, take x credits from them and spawn in awp.
public Action Command_BuyAWP(int client, int args)
{
	int awpCost = GetConVarInt(g_cvarAWPCost);
	int halfTime = GetConVarInt(g_cvarHalfTime);
	new creds = credits[client];
	if (CheckCommandAccess(client, "admin_check", ADMFLAG_ROOT))
	{
		GivePlayerItem(client, "weapon_awp");
		PrintToChat(client, "%s\x04 Here's your free AWP.", PREFIX);
	}
	else if (creds >= 5)
	{
		// Checks to make sure the round isn't a pistol only round, where an AWP would be unfair.
		if (GameRules_GetProp("m_totalRoundsPlayed") == 0 || GameRules_GetProp("m_totalRoundsPlayed") == halfTime)
		{
			PrintToChat(client, "%s\x04 You cannot buy an awp during pistol rounds.", PREFIX);
		}
		else
		{
			new addCredits = creds - awpCost;
			credits[client] = addCredits;
			GivePlayerItem(client, "weapon_awp");
			PrintToChat(client, "%s\x04 You have been given an AWP in exchange for \x0B%d\x04 credits.", PREFIX, awpCost);
		}
	}
	else
	{
		new neededCredits = awpCost - creds;
		if (neededCredits == 1)
		{
			PrintToChat(client, "%s\x04 You need another \x0B%d\x04 credit to buy an AWP!", PREFIX, neededCredits);
		}
		else
		{
			PrintToChat(client, "%s\x04 You need another \x0B%d\x04 credits to buy an AWP!", PREFIX, neededCredits);
		}
	}
}

// Command to check how many credits you have.
public Action Command_Credits(int client, int args)
{
	new addCredits = credits[client];
	if (addCredits == 1)
	{
		PrintToChat(client, "%s\x04 You have \x0B%d\x04 credit.", PREFIX, addCredits);
	}
	else
	{
		PrintToChat(client, "%s\x04 You have \x0B%d\x04 credits.", PREFIX, addCredits);
	}
}

// Command for an admin to give credits to another player
public Action Command_GiveCredits(int client, int args)
{
	char arg1[32], arg2[32];

	// Set default credit amount to 0
	int creditAmount = 0;

	GetCmdArg(1, arg1, sizeof(arg1));

	if(args < 2)
	{
		ReplyToCommand(client, "%s\x04 Usage: sm_givecredits <name | #userid> <credits>", PREFIX);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		creditAmount = StringToInt(arg2);
	}

	char targetName[64];
	int target = FindTarget(client, arg1);
	GetClientName(target, targetName, sizeof(targetName));
	char adminName[64];
	GetClientName(client, adminName, sizeof(adminName));

	if (target == -1)
	{
		/*
		FindTarget() automatically replies with the
		failure reason and returns -1 so we know not to continue
		*/
		PrintToChat(client, "%s\x04 Invalid target", PREFIX);
		return Plugin_Handled;
	}

	new creds = credits[target];
	new giveCredits = creds + creditAmount;
	credits[target] = giveCredits;

	// Tell player they have received credits from an admin
	PrintToChat(target, "%s\x04 You have been given \x0B%d\x04 credit(s) by \x0B%s\x04.", PREFIX, creditAmount, adminName);

	// Tell admin the player has received the credits
	PrintToChat(client, "%s\x04 You have given \x0B%d\x04 credit(s) to \x0B%s\x04.", PREFIX, creditAmount, targetName);

	return Plugin_Handled;
}

// If debug is enabled, command to print the different colours to chat. 
#if defined DEBUG
public Action Command_Colours(int client, int args)
{
	PrintToChat(client, " \x01\x0B\x011	\x022	\x033	\x044	\x055	\x066	\x077	\x088	\x099	\x1010	\x0AA	\x0BB	\x0CC	\x0EE	\x0FF ");
}
#endif
