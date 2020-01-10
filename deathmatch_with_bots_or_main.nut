Convars.SetValue("asw_horde_override", 1);
Convars.SetValue("asw_wanderer_override", 1);
const gs_DataName = "gs_dm_data";
const strDelimiter = ":";
bAI <- 1;
bOnslaught <- 1;
if (FileToString(gs_DataName) == "")
	StringToFile(gs_DataName, "1" + strDelimiter + "1"); // AI, Onslaught
else
{
	local strArrayContent = split(FileToString(gs_DataName), strDelimiter);
	bAI = strArrayContent[0].tointeger();
	bOnslaught = strArrayContent[1].tointeger();
}

function SetBotEmote(hBot, strEmote)
{
	local hTimer = Entities.CreateByClassname("logic_timer");
	hTimer.__KeyValueFromFloat("RefireTime", 0.2 + 0.01 * RandomInt(0, 5));
	DoEntFire("!self", "Disable", "", 0, null, hTimer);
	hTimer.ValidateScriptScope();
	local hTimerScope = hTimer.GetScriptScope();
	
	hTimerScope.hBot <- hBot;
	hTimerScope.strEmote <- strEmote;
	hTimerScope.TimerFunc <- function()
	{
		NetProps.SetPropInt(hBot, strEmote, 1);
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	hTimer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, hTimer);
}

function OnGameplayStart()
{
	LoopFunc();
}

function OnTakeDamage_Alive_Any(hVictim, hInflictor, hAttacker, hWeapon, iDamage, damageType, ammoName) 
{
	if (hAttacker != null && hVictim != null)
	{
		if (hAttacker.GetClassname() == "asw_shieldbug" && hVictim.GetClassname() == "asw_marine" && !hVictim.IsInhabited())
		{
			if (RandomInt(0, 1))
				SetBotEmote(hVictim, "bEmoteQuestion");
		}
	}
	return iDamage;
}

function OnGameEvent_entity_killed(params)
{
	local hVictim = null;
	local hAttacker = null;
	
	if ("entindex_killed" in params)
		hVictim = EntIndexToHScript(params["entindex_killed"]);
	if ("entindex_attacker" in params)
		hAttacker = EntIndexToHScript(params["entindex_attacker"]);
	
	if (!hVictim || !hAttacker)
		return;
	
	if (hVictim.GetClassname() == "asw_marine" && hAttacker.GetClassname() == "asw_marine" && !hAttacker.IsInhabited())
	{
		local iTemp = RandomInt(0, 4);
		if (iTemp < 2)
		{
			if (iTemp)
			SetBotEmote(hAttacker, "bEmoteSmile");
			else
				SetBotEmote(hAttacker, "bEmoteAnimeSmile");
		}
	}
}

function OnGameEvent_marine_spawn(params)
{
	local hBot = null;
	
	if ("entindex" in params)
		hBot = EntIndexToHScript(params["entindex"]);
	
	if (hBot.IsInhabited())
		return;
	
	hBot.RemoveWeapon(0);
	hBot.GiveWeapon(WeaponSpawner(hBot.GetMarineName()), 0);
	
	local hTimer = Entities.CreateByClassname("logic_timer");
	hTimer.__KeyValueFromFloat("RefireTime", 0.1);
	DoEntFire("!self", "Disable", "", 0, null, hTimer);
	hTimer.ValidateScriptScope();
	local hTimerScope = hTimer.GetScriptScope();
	
	hTimerScope.hBot <- hBot;
	hTimerScope.TimerFunc <- function()
	{
		hBot.RemoveWeapon(1);
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	hTimer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, hTimer);
}

function OnGameEvent_player_fullyjoined(params)
{
	if (!bAI)
		return;
	
	local bShouldAddBots = true;
	local userid = null;
	
	if ("userid" in params)
		userid = params["userid"];
	
	local hMarine = null;
	while ((hMarine = Entities.FindByClassname(hMarine, "asw_marine")) != null)
		bShouldAddBots = false;
	
	if (bShouldAddBots)
	{
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 1\"");
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 2\"");
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 3\""); // medic
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 4\"");
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 5\"");
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 6\"");
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 7\""); // medic
		SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 8\"");
	}
}

function OnGameEvent_player_say(params)
{
	if (!("text" in params) || !("userid" in params))
		return;
	else if (params["text"] == null)
		return;
	
	local userid = params["userid"];
	local strText = params["text"].tolower();
	
	switch (strText)
	{
		case "&help":
			DisplayMsg("==== List of Chat Commands ====\n&ai  -  Enable / Disable AI Players.\n&alien  -  Enable / Disable Onslaught.");
			return;
		case "&ai":
			if (bAI)
			{
				bAI = 0;
				KickBotsFunc();
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Disabled AI Players.");
			}
			else
			{
				bAI = 1;
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 1\"");
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 2\"");
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 3\""); // medic
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 4\"");
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 5\"");
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 6\"");
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 7\""); // medic
				SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd 8\"");
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Enabled AI Players.");
			}
			return;
		case "&alien":
			if (Convars.GetFloat("asw_horde_override"))
			{
				bOnslaught = 0;
				Convars.SetValue("asw_horde_override", 0);
				Convars.SetValue("asw_wanderer_override", 0);
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Disabled Onslaught.");
			}
			else
			{
				bOnslaught = 1;
				Convars.SetValue("asw_horde_override", 1);
				Convars.SetValue("asw_wanderer_override", 1);
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Enabled Onslaught.");
			}
			return;
	}
}

function KickBotsFunc()
{
	local player = null;
	while ((player = Entities.FindByClassname(player, "player")) != null)
		SendToServerConsole("sm_cexec #" + player.GetPlayerUserID() + " rd_bots_kick");
}

function DisplayMsg(message, delay = 0.01)
{
	if (!delay)
	{
		local player = null;
		while ((player = Entities.FindByClassname(player, "player")) != null)
			ClientPrint(player, 3, message);
		return;
	}
	local timer = Entities.CreateByClassname("logic_timer");
	timer.__KeyValueFromFloat("RefireTime", delay);
	DoEntFire("!self", "Disable", "", 0, null, timer);
	timer.ValidateScriptScope();
	local timerScope = timer.GetScriptScope();
	
	timerScope.message <- message;
	timerScope.TimerFunc <- function()
	{
		local player = null;
		while ((player = Entities.FindByClassname(player, "player")) != null)
			ClientPrint(player, 3, message);
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	timer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, timer);
}

function WeaponSpawner(marineName)
{
	local weaponNamesArray = ["asw_weapon_rifle", "asw_weapon_railgun", "asw_weapon_pdw", "asw_weapon_sniper_rifle", "asw_weapon_grenade_launcher", "asw_weapon_combat_rifle", "asw_weapon_heavy_rifle"];
	if (marineName == "Sarge" || marineName == "Jaeger")
	{
		return weaponNamesArray[RandomInt(0, 6)];
	}
	else if (marineName == "Wildcat" || marineName == "Wolfe")
	{
		weaponNamesArray.push("asw_weapon_autogun");
		weaponNamesArray.push("asw_weapon_minigun");
		return weaponNamesArray[RandomInt(0, 8)];
	}
	else if (marineName == "Faith" || marineName == "Bastille")
	{
		weaponNamesArray.push("asw_weapon_healamp_gun");
		return weaponNamesArray[RandomInt(0, 7)];
	}
	else if (marineName == "Crash" || marineName == "Vegas")
	{
		weaponNamesArray.push("asw_weapon_prifle");
		return weaponNamesArray[RandomInt(0, 7)];
	}
	return "asw_weapon_rifle";
}

function LoopFunc()
{
	local hTimer = Entities.CreateByClassname("logic_timer");
	hTimer.__KeyValueFromFloat("RefireTime", 1);
	DoEntFire("!self", "Disable", "", 0, null, hTimer);
	hTimer.ValidateScriptScope();
	local hTimerScope = hTimer.GetScriptScope();
	
	hTimerScope.LoopFunc <- LoopFunc;
	hTimerScope.TimerFunc <- function()
	{
		local hParas = null;
		while ((hParas = Entities.FindByClassname(hParas, "asw_parasite")) != null)
			hParas.Destroy();
		local hBot = null;
		while ((hBot = Entities.FindByClassname(hBot, "asw_marine")) != null)
		{
			if (!hBot.IsInhabited())
				NetProps.SetPropInt(hBot, "m_ASWOrders", 3);
		}
		LoopFunc();
		
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	hTimer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, hTimer);
}
