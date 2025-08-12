# Firewall Status Check Active Response Script

This repository contains a script to check the status of UFW (Uncomplicated Firewall) on Linux systems as part of security automation and active response workflows.

## Overview

The `Ensure-ufw-isEnabled.sh` script checks the current status of UFW firewall including whether it's enabled and if logging is active. The script provides standardized logging and JSON output suitable for integration with security orchestration platforms, SIEM systems, and incident response workflows.

## Script Structure

### Core Components

1. **Logging Framework** - Comprehensive logging with rotation
2. **Error Handling** - Basic exception management
3. **JSON Output** - Standardized response format
4. **Execution Timing** - Performance monitoring

## How Script Is Invoked

### Command Line Execution

./Ensure-ufw-isEnabled.sh

### Environment Variables

| Variable | Description |
|----------|-------------|
| VERBOSE | Set to 1 to enable debug logging |
| LogPath | Override default log path (/tmp/CheckFirewallStatus-script.log) |
| ARLog | Override default active response log path (/var/ossec/active-response/active-responses.log) |

## Script Functions

### Write-Log
**Purpose**: Provides standardized logging with multiple severity levels and console output.

**Parameters**:
- Message (string): The log message to write
- Level (string): Log level - 'INFO', 'WARN', 'ERROR', 'DEBUG'

**Features**:
- Timestamp formatting
- Color-coded console output based on severity
- File logging with structured format
- Verbose debugging support

**Usage**:

```bash
WriteLog "Process started successfully" "INFO"
WriteLog "Configuration file not found" "WARN"
WriteLog "Critical error occurred" "ERROR"
WriteLog "Debug information" "DEBUG"
```

### Rotate-Log
**Purpose**: Manages log file size and implements automatic log rotation.

**Features**:
- Monitors log file size (default: 100KB threshold)
- Maintains configurable number of historical log files (default: 5)
- Automatic rotation when size limit exceeded

**Configuration Variables**:
- LogMaxKB: Maximum log file size in KB before rotation (default: 100)
- LogKeep: Number of rotated log files to retain (default: 5)

## Script Execution Flow

### 1. Initialization Phase
- Log rotation check and execution
- Active response log clearing
- Script start logging with timestamp

### 2. Execution Phase
- UFW status check
- Feature detection (checks if UFW is installed)
- Status parsing (enabled/disabled, logging on/off)

### 3. Completion Phase
- JSON result formatting and output
- Active response log writing
- Execution duration calculation

## JSON Output Format

The script outputs standardized JSON responses to the active response log:

### Success Response

```json
{
  "timestamp": "2025-07-18T10:30:45.123Z",
  "host": "HOSTNAME",
  "action": "check_firewall_status",
  "enforced": [
    {
      "profile": "ufw",
      "enabled": true,
      "logging": false
    }
  ],
  "copilot_soar": true
}
```

### Error Response (UFW not installed)

```json
{
  "timestamp": "2025-07-18T10:30:45.123Z",
  "host": "HOSTNAME",
  "action": "check_firewall_status",
  "enforced": [
    {
      "profile": "ufw",
      "enabled": false,
      "logging": false,
      "error": "ufw not installed"
    }
  ],
  "copilot_soar": true
}
```

## Implementation Guidelines

### 1. Customizing the Script
1. Modify the `CheckFirewallStatus` function to add additional checks
2. Update the JSON output structure as needed
3. Add any additional logging as required

### 2. Best Practices
- Always use the provided logging functions
- Implement proper error handling for all operations
- Include meaningful progress messages
- Test in target environments
- Validate JSON output format compatibility

### 3. Integration Considerations
- Ensure proper file permissions for log paths
- Test script execution in target environments
- Validate JSON output format compatibility with your SIEM

## Security Considerations

- Script should run with minimal required privileges
- Validate all input if parameters are added
- Implement proper access controls for log files
- Log all security-relevant actions and decisions

## Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure script has write access to log paths
2. **UFW Detection**: Verify UFW is installed if getting "not installed" errors
3. **Log Rotation**: Check disk space and file permissions for log directory
4. **JSON Format**: Validate output against expected schema

### Debug Mode
Enable verbose logging by setting VERBOSE=1:

```bash
VERBOSE=1 ./Ensure-ufw-isEnabled.sh
```

## License

This script is provided as-is for security automation and incident response purposes.
```
