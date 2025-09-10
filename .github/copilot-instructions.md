# Copilot Instructions for FixNetPublicAdr

## Repository Overview

This repository contains a SourcePawn plugin for SourceMod that automatically sets the `net_public_adr` ConVar for game servers behind NAT/DHCP. The plugin provides three methods to obtain the server's public IP address: HTTP endpoint query, hostip conversion, or custom manual setting.

**Primary Purpose**: Automatically configure the public IP address for Source engine game servers that are behind NAT/DHCP to ensure proper connectivity for players.

## Project Structure

```
addons/sourcemod/scripting/
├── FixNetPublicAdr.sp          # Main plugin source code
sourceknight.yaml               # Build configuration
.github/workflows/ci.yml        # CI/CD pipeline
```

## Technical Environment

- **Language**: SourcePawn (SourceMod scripting language)
- **Platform**: SourceMod 1.11.0-git6917+ (minimum requirement)
- **Build Tool**: SourceKnight (configured in `sourceknight.yaml`)
- **Dependencies**: 
  - SourceMod core
  - RiPExt extension (for HTTP requests)
- **Target**: Source engine game servers (CS:GO, CS2, TF2, etc.)

## Code Architecture

### Main Components

1. **ConVar Management**: Creates and manages configuration variables
   - `sm_fixnetpublicaddr_method`: Selection of IP detection method (0-2)
   - `sm_fixnetpublicaddr_custom_ip`: Custom IP address setting
   - `sm_fixnetpublicaddr_public_ip_endpoint`: HTTP endpoint for IP detection
   - `net_public_adr`: Target ConVar that gets set with the detected IP

2. **IP Detection Methods**:
   - **Method 0 (Endpoint)**: HTTP request to external service (default: api.ipify.org)
   - **Method 1 (HostIP)**: Convert server's hostip ConVar to public format
   - **Method 2 (Custom)**: Use manually specified IP address

3. **Event Handling**: Responds to config changes and ConVar modifications

## Build & Development Process

### Building the Plugin

The project uses SourceKnight as the build system:

```bash
# Build is handled automatically by CI/CD, but locally would be:
sourceknight build
```

**Build Configuration**: See `sourceknight.yaml` for:
- Dependencies (SourceMod, RiPExt extension)
- Build targets
- Output directory configuration

### CI/CD Pipeline

- **Trigger**: Push, PR, or manual dispatch
- **Process**: 
  1. Build plugin using SourceKnight action
  2. Package build artifacts
  3. Create releases for main branch and tags
  4. Upload release packages

### Testing

- **Manual Testing**: Deploy to a test server and verify:
  - ConVar `net_public_adr` is set correctly
  - All three methods work as expected
  - ConVar changes trigger updates
  - HTTP endpoint failures are handled gracefully

## Code Style & Standards

### SourcePawn Conventions
- Use tabs for indentation (4 spaces equivalent)
- camelCase for local variables and parameters
- PascalCase for functions and globals
- Prefix globals with `g_` (e.g., `g_cvNetPublicAddr`)
- Include `#pragma semicolon 1` and `#pragma newdecls required`

### This Project's Patterns
- ConVar naming: `g_cv[ConVarName]` pattern
- String buffers: Use appropriate sizes (32 for IPs, 256 for URLs)
- Error handling: Use `LogError()` for user-visible issues
- Memory management: Use `delete` for HTTPRequest cleanup (handled by RiPExt)

## Key Implementation Details

### HTTP Requests (Method 0)
- Uses RiPExt extension's HTTPRequest class
- Expects JSON response with "ip" field
- Asynchronous operation with callback handling
- Default endpoint: https://api.ipify.org?format=json

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

### Modifying HTTP Endpoint Behavior
- Modify `OnPublicIPReceived()` for different response formats
- Update default endpoint in ConVar creation
- Ensure error handling for network failures

### Configuration Changes
- New ConVars should follow the `sm_fixnetpublicaddr_*` naming pattern
- Use appropriate FCVAR flags (FCVAR_PROTECTED for sensitive settings)
- Hook new ConVars in `OnPluginStart()` if they should trigger updates

## Error Handling Guidelines

- Use `LogError()` for configuration issues that affect functionality
- Check ConVar validity before use
- Handle HTTP response status codes appropriately
- Provide meaningful error messages that help server administrators

## Performance Considerations

- HTTP requests are asynchronous and don't block server tick
- ConVar changes trigger immediate updates (acceptable for infrequent changes)
- String operations are minimal and use stack-allocated buffers
- No timers or frequent polling - event-driven architecture

## Version Management

- Version defined in plugin info block
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Update version when making functional changes
- Coordinate version with Git tags for releases

## Security Notes

- HTTP endpoint is configurable (potential for abuse if misconfigured)
- Custom IP input should be validated if expanded
- ConVars are marked FCVAR_PROTECTED where appropriate
- No user input validation beyond SourceMod's built-in ConVar handling

## Dependencies & Compatibility

- **Minimum SourceMod**: 1.11.0-git6917 (for modern SourcePawn syntax)
- **Required Extensions**: RiPExt (for HTTP functionality)
- **Game Compatibility**: All Source engine games supported by SourceMod
- **Operating Systems**: Linux, Windows (wherever SourceMod runs)

## Debugging Tips

- Use `sm_cvar net_public_adr` to check current setting
- Monitor server console for LogError messages
- Test HTTP endpoint manually: `curl https://api.ipify.org?format=json`
- Use `sm_cvar sm_fixnetpublicaddr_method` to switch between methods
- Check `hostip` ConVar value when using method 1

## Future Enhancement Ideas

- Add IPv6 support
- Implement retry logic for failed HTTP requests
- Add validation for custom IP addresses
- Support for multiple fallback endpoints
- Integration with server monitoring systems