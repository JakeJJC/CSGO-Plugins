#pragma semicolon 1

#define PLUGIN_AUTHOR "Jake"
#define PLUGIN_VERSION "1.0"
#define MessagePrefix " \x0C[Ping Blocker]\x01"
#define MaxPrintTimes 3
#define DisabledMessage "\x04Pinging has been disabled on this server."

timesPrinted[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "Ping Blocker",
	author = PLUGIN_AUTHOR,
	description = "Blocks player pings",
	version = PLUGIN_VERSION
};

// OnPluginStart, listen for ping commands to prevent them
public void OnPluginStart() {
	AddCommandListener(Command_Ping, "player_ping");
	AddCommandListener(Command_Ping, "playerradio");
	AddCommandListener(Command_Ping, "chatwheel_ping");
	AddCommandListener(Command_Ping, "playerchatwheel");
}

// When the player connects set their timesPrinted to 0
public OnClientConnected(int client) {
	timesPrinted[client] = 0;
}

// What to do when any of the ping commands are sent
public Action Command_Ping(int client, const char[] command, int args) {
	// Checks if timesPrinted is more than or equal to the max set (3) and if so prevents the message from being sent.
    if (timesPrinted[client] >= MaxPrintTimes) {
        return Plugin_Handled;
    }
	// Prints a message to the players chat letting them know that pinging has been disabled. 
    PrintToChat(client, "%s %s", MessagePrefix, DisabledMessage);
	// Adds 1 to timesPrinted variable
    timesPrinted[client]++;
    return Plugin_Handled;
}
