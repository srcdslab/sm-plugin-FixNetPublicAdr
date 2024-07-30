#include <ripext>

ConVar g_cvNetPublicAddr   = null;
ConVar g_cvPublicIPEndpout = null;
ConVar g_cvMethod          = null;
ConVar g_cvCustomIP        = null;

char g_sPublicIPAddress[32];

public Plugin myinfo =
{
	name        = "FixNetPublicAddr",
	author      = "maxime1907, .Rushaway",
	description = "Add/Edit convar net_public_adr for servers behind NAT/DHCP",
	version     = "1.1.1",
	url         = ""
};

public void OnPluginStart()
{
	g_cvMethod = CreateConVar("sm_fixnetpublicaddr_method", "0", "[0 = Endpoint | 1 = Hostip | 2 = Custom]", FCVAR_PROTECTED, true, 0.0, true, 2.0);
	g_cvCustomIP = CreateConVar("sm_fixnetpublicaddr_custom_ip", "", "Custom IP to set as net_public_adr");
	g_cvPublicIPEndpout = CreateConVar("sm_fixnetpublicaddr_public_ip_endpoint", "https://api.ipify.org?format=json", "Endpoint to query the server public ip");

	g_cvNetPublicAddr = FindConVar("net_public_adr");
	if (g_cvNetPublicAddr == null)
		g_cvNetPublicAddr = CreateConVar("net_public_adr", "", "For servers behind NAT/DHCP meant to be exposed to the public internet, this is the public facing ip address string: (\"x.x.x.x\" )", FCVAR_NOTIFY);

	AutoExecConfig(true);

	HookConVarChange(g_cvMethod, OnConVarChanged);
	HookConVarChange(g_cvCustomIP, OnConVarChanged);
	HookConVarChange(g_cvPublicIPEndpout, OnConVarChanged);
}

public void OnConfigsExecuted()
{
	GetServerPublicIP();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetServerPublicIP();
}

stock void GetServerPublicIP()
{
	switch (g_cvMethod.IntValue)
	{
		case 0:
			GetPublicIPFromEndpoint();
		case 1:
			GetPublicIPFromHostIP();
		case 2:
		{
			g_cvCustomIP.GetString(g_sPublicIPAddress, sizeof(g_sPublicIPAddress));

			if (g_sPublicIPAddress[0] == '\0')
			{
				LogError("Custom IP is empty, please set a valid IP address, fallback to hostip");
				return;
			}

			g_cvNetPublicAddr.SetString(g_sPublicIPAddress, false, true);
		}
	}
}

stock void GetPublicIPFromEndpoint()
{
	char sEndpoint[256];
	g_cvPublicIPEndpout.GetString(sEndpoint, sizeof(sEndpoint));
	HTTPRequest request = new HTTPRequest(sEndpoint);

	request.Get(OnPublicIPReceived);
}

void OnPublicIPReceived(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK)
		return;

	JSONObject jsonIP = view_as<JSONObject>(response.Data);
	jsonIP.GetString("ip", g_sPublicIPAddress, sizeof(g_sPublicIPAddress));

	g_cvNetPublicAddr.SetString(g_sPublicIPAddress, false, true);
}

stock void GetPublicIPFromHostIP()
{
	ConVar sHostIP = FindConVar("hostip");
	int iServerIP = GetConVarInt(sHostIP);
	delete sHostIP;

	int ipUnsigned = iServerIP & 0xFFFFFFFF;
	Format(g_sPublicIPAddress, sizeof(g_sPublicIPAddress), "%d.%d.%d.%d", (ipUnsigned >> 24) & 0xFF, (ipUnsigned >> 16) & 0xFF, (ipUnsigned >> 8) & 0xFF, ipUnsigned & 0xFF);

	g_cvNetPublicAddr.SetString(g_sPublicIPAddress, false, true);
}
