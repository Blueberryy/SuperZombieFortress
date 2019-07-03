typedef eWeapon_OnPickup = function bool (int client); // Return false to prevent client from picking up the item.

static ArrayList g_Weapons;
static ArrayList g_WepIndexesByRarity[eWeaponsRarity]; // Array indexes of g_Weapons array
static StringMap g_WeaponsReskin;

enum struct eWeapon
{
	int iIndex;
	eWeaponsRarity Rarity;
	char sModel[PLATFORM_MAX_PATH];
	char sText[256];
	char sAttribs[256];
	int iColor[3];
	float flOffsetOrigin[3];
	float flOffsetAngles[3];
	eWeapon_OnPickup on_pickup;
}

void Weapons_Init()
{
	g_Weapons = Config_LoadWeaponData();
	g_WeaponsReskin = Config_LoadWeaponReskinData();
	
	int iLength = g_Weapons.Length;
	for (int i = 0; i < INT(eWeaponsRarity); i++)
	{
		g_WepIndexesByRarity[i] = new ArrayList();
		
		for (int j = 0; j < iLength; j++)
		{
			eWeapon wep;
			g_Weapons.GetArray(j, wep);
			
			if (wep.Rarity == view_as<eWeaponsRarity>(i))
				g_WepIndexesByRarity[i].Push(j);
		}
	}
}

void Weapons_Precache()
{
	SoundPrecache();
	
	int iLength = g_Weapons.Length;
	for (int i = 0; i < iLength; i++)
	{
		eWeapon wep;
		g_Weapons.GetArray(i, wep);
		
		PrecacheModel(wep.sModel);
	}
	
	PrecacheSound("ui/item_heavy_gun_pickup.wav");
	PrecacheSound("ui/item_heavy_gun_drop.wav");
	
	PrecacheSound("items/smallmedkit1.wav");			// Medkit pickup
	PrecacheSound("items/powerup_pickup_base.wav");		// Defense pickup
	PrecacheSound("items/powerup_pickup_haste.wav");	// Minicrits pickup
}

void GetWeaponFromModel(eWeapon buffer, char[] model)
{
	int iLength = g_Weapons.Length;
	for (int i = 0; i < iLength; i++) 
	{
		eWeapon wep;
		g_Weapons.GetArray(i, wep);
		
		if (StrEqual(model, wep.sModel))
		{
			buffer = wep;
			return;
		}
	}
}

void GetWeaponFromIndex(eWeapon buffer, int index)
{
	int iLength = g_Weapons.Length;
	for (int i = 0; i < iLength; i++) 
	{
		eWeapon wep;
		g_Weapons.GetArray(i, wep);
		
		if (index == wep.iIndex)
		{
			buffer = wep;
			return;
		}
	}
}

ArrayList GetAllWeaponsWithRarity(eWeaponsRarity rarity)
{
	ArrayList array = new ArrayList(sizeof(eWeapon));
	
	int iLength = GetRarityWeaponCount(rarity);
	for (int i = 0; i < iLength; i++)
	{
		eWeapon wep;
		g_Weapons.GetArray(g_WepIndexesByRarity[rarity].Get(i), wep);
		
		array.PushArray(wep);
	}
	
	return array;
}

int GetRarityWeaponCount(eWeaponsRarity rarity)
{
	return g_WepIndexesByRarity[rarity].Length;
}

int GetReskinIndex(char[] sModel)
{
	int iIndex = -1;
	if (g_WeaponsReskin.GetValue(sModel, iIndex))
		return iIndex;
	
	return -1;
}

void Weapons_ReplaceEntityModel(int ent, int index)
{
	int iLength = g_Weapons.Length;
	for (int i = 0; i < iLength; i++) 
	{
		eWeapon wep;
		g_Weapons.GetArray(i, wep);
		
		if (index == wep.iIndex)
		{
			SetWeaponModel(ent, wep);
			return;
		}
	}
}

// enum structs are truly epic
void Weapons_GetOffsets(eWeapon wep, float origin[3], float angles[3])
{
	origin[0] = wep.flOffsetOrigin[0];
	origin[1] = wep.flOffsetOrigin[1];
	origin[2] = wep.flOffsetOrigin[2];
	
	angles[0] = wep.flOffsetAngles[0];
	angles[1] = wep.flOffsetAngles[1];
	angles[2] = wep.flOffsetAngles[2];
}

// -----------------------------------------------------------
public bool Weapons_OnPickup_Health(int client)
{
	if (GetClientHealth(client) < SDK_GetMaxHealth(client))
	{
		SpawnPickup(client, "item_healthkit_full");
		EmitSoundToClient(client, "items/smallmedkit1.wav");
		
		return true;
	}
	
	return false;
}

public bool Weapons_OnPickup_Ammo(int client)
{
	SpawnPickup(client, "item_ammopack_full");
	EmitSoundToClient(client, "ui/item_heavy_gun_pickup.wav");
	
	return true;
}

public bool Weapons_OnPickup_Minicrits(int client)
{
	TF2_AddCondition(client,TFCond_Buffed,30.0);
	EmitSoundToClient(client, "items/powerup_pickup_haste.wav");
	
	return true;
}

public bool Weapons_OnPickup_Defense(int client)
{
	TF2_AddCondition(client,TFCond_DefenseBuffed,30.0);
	EmitSoundToClient(client, "items/powerup_pickup_base.wav");
	
	return true;
}