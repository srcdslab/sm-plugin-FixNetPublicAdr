# Copilot Instructions for FixNetPublicAdr

## Repository Overview

This repository contains a SourcePawn plugin for SourceMod that automatically sets the `net_public_adr` ConVar for game servers behind NAT/DHCP. The plugin provides three methods to obtain the server's public IP address: Steam (SteamWorks) lookup, hostip conversion, or custom manual setting.

**Primary Purpose**: Automatically configure the public IP address for Source engine game servers that are behind NAT/DHCP to ensure proper connectivity for players.

## Project Structure

```
addons/sourcemod/scripting/
├── FixNetPublicAdr.sp          # Main plugin source code
.github/workflows/ci.yml        # CI/CD pipeline (native GitHub Actions)
```

## Technical Environment

- **Language**: SourcePawn (SourceMod scripting language)
- **Platform**: SourceMod 1.12.x (CI compiler baseline)
- **Build Tool**: Native GitHub Actions workflow using `rumblefrog/setup-sp` (spcomp)
- **Dependencies**: 
  - SourceMod core
  - SteamWorks extension ([alliedmodders/SM-SteamWorks](https://github.com/alliedmodders/SM-SteamWorks), for the Steam public IP)
- **Target**: Source engine game servers (CS:GO, CS2, TF2, etc.)

## Code Architecture

### Main Components

1. **ConVar Management**: Creates and manages configuration variables
   - `sm_fixnetpublicaddr_method`: Selection of IP detection method (0-2)
   - `sm_fixnetpublicaddr_custom_ip`: Custom IP address setting
   - `net_public_adr`: Target ConVar that gets set with the detected IP

2. **IP Detection Methods**:
   - **Method 0 (Steam)**: Public IP as seen by Steam (`SteamWorks_GetPublicIP`), hostip until the server is logged on to Steam
   - **Method 1 (HostIP)**: Convert server's hostip ConVar to public format
   - **Method 2 (Custom)**: Use manually specified IP address

3. **Event Handling**: Responds to config changes and ConVar modifications

## Build & Development Process

### Building the Plugin

The project uses a native GitHub Actions workflow with `rumblefrog/setup-sp` (spcomp) as the build system. Locally, this equates to cloning the SteamWorks include (alliedmodders/SM-SteamWorks) and running `spcomp` directly against `FixNetPublicAdr.sp`.

**Build Configuration**: See `.github/workflows/ci.yml` for:
- Dependencies (SourceMod via `rumblefrog/setup-sp`, SteamWorks include via `git clone`)
- Build targets
- Output directory configuration

### CI/CD Pipeline

- **Trigger**: Push, PR, or manual dispatch
- **Process**: 
  1. Install SourcePawn compiler via `rumblefrog/setup-sp`
  2. Clone dependencies and compile plugin with `spcomp`
  3. Package build artifacts
  4. Create releases for main branch and tags
  5. Upload release packages

### Testing

- **Manual Testing**: Deploy to a test server and verify:
  - ConVar `net_public_adr` is set correctly
  - All three methods work as expected
  - ConVar changes trigger updates
  - Method 0 uses hostip until the server is logged on to Steam, then switches to the Steam public IP

## Code Style & Standards

### SourcePawn Conventions
- Use tabs for indentation (4 spaces equivalent)
- camelCase for local variables and parameters
- PascalCase for functions and globals
- Prefix globals with `g_` (e.g., `g_cvNetPublicAddr`)
- Include `#pragma semicolon 1` and `#pragma newdecls required`

### This Project's Patterns
- ConVar naming: `g_cv[ConVarName]` pattern
- String buffers: Use appropriate sizes (32 for IPs)
- Error handling: Use `LogError()` for user-visible issues

## Key Implementation Details

### Steam Public IP (Method 0)
- Uses `SteamWorks_GetPublicIP()`: no external service, no HTTP request
- Only available once the server is logged on to Steam: until then hostip is used
- `SteamWorks_SteamServersConnected()` sets the Steam IP as soon as the server logs on

### HostIP Conversion (Method 1)
- Reads `hostip` ConVar (32-bit integer)
- Converts to dotted decimal notation
- Useful for servers with static public IPs

### ConVar Hooks
- All relevant ConVars are hooked for changes
- Triggers immediate IP refresh when configuration changes
- Uses `SetString(value, false, true)` to avoid infinite recursion

## Common Modification Patterns

### Adding New IP Detection Methods
1. Add new method case in `GetServerPublicIP()` switch statement
2. Implement corresponding function following `GetPublicIPFrom*()` pattern
3. Update method ConVar bounds and description
4. Test all code paths

### Configuration Changes
- New ConVars should follow the `sm_fixnetpublicaddr_*` naming pattern
- Use appropriate FCVAR flags (FCVAR_PROTECTED for sensitive settings)
- Hook new ConVars in `OnPluginStart()` if they should trigger updates

## Error Handling Guidelines

- Use `LogError()` for configuration issues that affect functionality
- Check ConVar validity before use
- Provide meaningful error messages that help server administrators

## Performance Considerations

- No network request: the Steam public IP is read from SteamWorks
- ConVar changes trigger immediate updates (acceptable for infrequent changes)
- String operations are minimal and use stack-allocated buffers
- No timers or frequent polling - event-driven architecture

## Version Management

- Version defined in plugin info block
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Update version when making functional changes
- Coordinate version with Git tags for releases

## Security Notes

- Custom IP input should be validated if expanded
- ConVars are marked FCVAR_PROTECTED where appropriate
- No user input validation beyond SourceMod's built-in ConVar handling

## Dependencies & Compatibility

- **Minimum SourceMod**: 1.12.x (CI compiler baseline; for modern SourcePawn syntax)
- **Required Extensions**: SteamWorks (for the Steam public IP)
- **Game Compatibility**: All Source engine games supported by SourceMod
- **Operating Systems**: Linux, Windows (wherever SourceMod runs)

## Debugging Tips

- Use `sm_cvar net_public_adr` to check current setting
- Monitor server console for LogError messages
- Check that SteamWorks is loaded: `sm exts list`
- Use `sm_cvar sm_fixnetpublicaddr_method` to switch between methods
- Check `hostip` ConVar value when using method 1

## Future Enhancement Ideas

- Add IPv6 support
- Add validation for custom IP addresses
- Integration with server monitoring systems