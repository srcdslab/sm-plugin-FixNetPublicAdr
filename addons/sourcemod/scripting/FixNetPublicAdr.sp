#include <ripext>

ConVar g_cvNetPublicAddr   = null;
ConVar g_cvPublicIPEndpout = null;

public Plugin myinfo =
{
	name        = "FixNetPublicAddr",
	author      = "maxime1907",
	description = "Add/Edit convar net_public_adr for servers behind NAT/DHCP",
	version     = "1.0.1",
	url         = ""
};

public void OnPluginStart()
{
	g_cvPublicIPEndpout = CreateConVar("sm_fixnetpublicaddr_public_ip_endpoint", "https://api.ipify.org?format=json", "Endpoint to query the server public ip");

	g_cvNetPublicAddr = FindConVar("net_public_adr");
	if (g_cvNetPublicAddr == null)
		g_cvNetPublicAddr = CreateConVar("net_public_adr", "", "For servers behind NAT/DHCP meant to be exposed to the public internet, this is the public facing ip address string: (\"x.x.x.x\" )", FCVAR_NOTIFY);

	AutoExecConfig(true);
}

public void OnConfigsExecuted()
{
	GetServerPublicIP();
}

stock void GetServerPublicIP()
{
	char sEndpoint[256];
	g_cvPublicIPEndpout.GetString(sEndpoint, sizeof(sEndpoint));
	HTTPRequest request = new HTTPRequest(sEndpoint);

	request.Get(OnPublicIPReceived);
}

void OnPublicIPReceived(HTTPResponse response, any value)
{
	if (response.Status != HTTPStatus_OK)
	{
		return;
	}

	JSONObject jsonIP = view_as<JSONObject>(response.Data);

	char sPublicIPAddress[32];
	jsonIP.GetString("ip", sPublicIPAddress, sizeof(sPublicIPAddress));

	g_cvNetPublicAddr.SetString(sPublicIPAddress, false, true);
}
