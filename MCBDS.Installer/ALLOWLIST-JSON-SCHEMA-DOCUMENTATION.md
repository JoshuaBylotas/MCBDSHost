# Allowlist Management - Complete Documentation

## ?? allowlist.json Schema

### File Location
```
<bedrock-server-directory>/allowlist.json
```

### JSON Schema
```json
[
  {
    "name": "string",
    "xuid": "string",
    "ignoresPlayerLimit": boolean
  }
]
```

### Example File
```json
[
  {
    "name": "Player1",
    "xuid": "2535405130520144",
    "ignoresPlayerLimit": false
  },
  {
    "name": "AdminPlayer",
    "xuid": "2535405130520145",
    "ignoresPlayerLimit": true
  },
  {
    "name": "VIPPlayer",
    "xuid": "2535405130520146",
    "ignoresPlayerLimit": false
  }
]
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | The player's gamertag (Xbox Live username) |
| `xuid` | string | Yes | The player's Xbox User ID (15-16 digit number) |
| `ignoresPlayerLimit` | boolean | Yes | If true, player can join even when server is at max capacity |

---

## ?? server.properties Configuration

### Allowlist Setting
The `allow-list` property in `server.properties` controls whether the allowlist feature is active.

```properties
# Enable/disable allowlist
allow-list=true
```

### Values
- `true` - Only players in allowlist.json can join
- `false` - Anyone can join (allowlist is ignored)

### Auto-Toggle Behavior
The MCBDS API automatically manages this setting:
- **Adding first user** ? Sets `allow-list=true`
- **Removing last user** ? Sets `allow-list=false`
- **Manual toggle** ? Can be controlled via API

---

## ?? API Endpoints

### 1. Get API Version/Capabilities
**Endpoint:** `GET /api/version`

**Response:**
```json
{
  "version": "1.1",
  "supportsAllowlist": true,
  "supportsServerProperties": true,
  "supportsXboxLookup": false,
  "supportedFeatures": [
    "allowlist-management",
    "server-properties-toggle",
    "backup-management",
    "command-execution"
  ]
}
```

### 2. Get Allowlist
**Endpoint:** `GET /api/allowlist`

**Response:**
```json
{
  "users": [
    {
      "name": "Player1",
      "xuid": "2535405130520144",
      "ignoresPlayerLimit": false
    }
  ],
  "isEnabled": true
}
```

### 3. Update Allowlist
**Endpoint:** `POST /api/allowlist`

**Request Body:**
```json
{
  "users": [
    {
      "name": "Player1",
      "xuid": "2535405130520144",
      "ignoresPlayerLimit": false
    }
  ]
}
```

**Response:**
```json
{
  "message": "Allowlist updated successfully with 1 users. Allowlist enabled."
}
```

### 4. Add Single User
**Endpoint:** `POST /api/allowlist/user`

**Request Body:**
```json
{
  "gamertag": "NewPlayer",
  "xuid": "2535405130520147",
  "ignoresPlayerLimit": false
}
```

**Response:**
```json
{
  "message": "User NewPlayer added to allowlist successfully"
}
```

### 5. Remove User
**Endpoint:** `DELETE /api/allowlist/user/{xuid}`

**Response:**
```json
{
  "message": "User Player1 removed from allowlist successfully"
}
```

### 6. Toggle Allowlist
**Endpoint:** `POST /api/allowlist/toggle`

**Request Body:**
```json
{
  "enabled": true
}
```

**Response:**
```json
{
  "message": "Allowlist enabled successfully"
}
```

---

## ?? Xbox Live XUID Information

### What is an XUID?
- **XUID** = Xbox User ID
- Unique 15-16 digit identifier for every Xbox Live account
- Required for Minecraft Bedrock allowlist

### How to Get XUID

#### Option 1: MCBDS Manager (Built-in)
1. Open Server Properties
2. Click "Manage Allowlist"
3. Enter gamertag and click "Lookup"
4. XUID is automatically retrieved

#### Option 2: Online Tools
- **xboxgamertag.com** - Free XUID lookup
- **cxkes.me/xbox/xuid** - Xbox API XUID checker
- **xbl.io** - Xbox API (requires API key)

#### Option 3: In-Game
Players can find their own XUID by:
1. Opening Xbox app
2. Going to Profile
3. Checking "More info"

### XUID Format
- **Length:** 15-16 digits
- **Type:** Numeric only
- **Example:** `2535405130520144`

### Validation Rules
- Must be all numbers
- Must be at least 15 digits
- No letters or special characters

---

## ?? Gamertag Rules

### Valid Gamertag Format
- **Length:** 3-15 characters
- **Characters:** Letters, numbers, and spaces only
- **Must start with:** Letter or number
- **Case:** Stored as entered, but comparison is case-insensitive

### Examples
? Valid:
- `Player123`
- `Cool Gamer`
- `xXProGamerXx`
- `Alice99`

? Invalid:
- `P1` (too short)
- `ThisIsAVeryLongGamertagThatExceeds15Chars` (too long)
- `Player_123` (underscore not allowed)
- `@Player` (special character not allowed)

---

## ?? Permission Levels

### ignoresPlayerLimit Flag
Controls whether a user can bypass the max-players limit.

**When `true`:**
- User can join even if server is at max capacity
- Useful for admins and VIP players
- Does not affect others' ability to join

**When `false`:**
- User must wait for open slot like everyone else
- Normal player behavior

**Example Use Cases:**
- Set `true` for server admins
- Set `true` for trusted moderators
- Set `false` for regular players

---

## ?? Backward Compatibility

### API Version Detection
The MCBDS Manager automatically detects API capabilities:

**Old Server (v1.0):**
- Allowlist button hidden
- Shows upgrade message
- All other features work normally

**New Server (v1.1+):**
- Allowlist button visible
- Full functionality available
- Auto-enable/disable support

### Migration Path
1. **Update API server** to v1.1+
2. **Restart API service**
3. **Refresh MAUI app**
4. **Allowlist button appears** automatically

No app update needed - feature detection is automatic!

---

## ?? Usage Examples

### Example 1: Add Server Admin
```json
{
  "name": "ServerAdmin",
  "xuid": "2535405130520144",
  "ignoresPlayerLimit": true
}
```

### Example 2: Add Regular Player
```json
{
  "name": "CasualPlayer",
  "xuid": "2535405130520145",
  "ignoresPlayerLimit": false
}
```

### Example 3: VIP List
```json
[
  {
    "name": "Owner",
    "xuid": "2535405130520144",
    "ignoresPlayerLimit": true
  },
  {
    "name": "Moderator1",
    "xuid": "2535405130520145",
    "ignoresPlayerLimit": true
  },
  {
    "name": "VIPPlayer1",
    "xuid": "2535405130520146",
    "ignoresPlayerLimit": false
  },
  {
    "name": "VIPPlayer2",
    "xuid": "2535405130520147",
    "ignoresPlayerLimit": false
  }
]
```

---

## ?? Troubleshooting

### Allowlist Not Working
1. **Check server.properties:** Ensure `allow-list=true`
2. **Verify allowlist.json:** File must be valid JSON
3. **Check XUIDs:** Must be correct for each player
4. **Restart server:** Changes require server restart

### Player Can't Join
1. **Check if in allowlist:** Verify user exists in allowlist.json
2. **Check XUID:** Must match exactly (case-sensitive)
3. **Check gamertag:** Must match current Xbox Live name
4. **Check allowlist enabled:** `allow-list=true` in server.properties

### Gamertag Lookup Fails
1. **Check internet connection**
2. **Verify gamertag format** (3-15 chars, alphanumeric)
3. **Use fallback method** (app generates pseudo-XUID)
4. **Manually enter XUID** if known

### Changes Not Saving
1. **Check file permissions** on bedrock directory
2. **Check disk space**
3. **Verify API server is running**
4. **Check server logs** for errors

---

## ?? Security Notes

### XUID Privacy
- XUIDs are public information
- Safe to share (like usernames)
- Cannot be used to compromise accounts

### File Security
- `allowlist.json` is plain text
- Protect server files from unauthorized access
- Regular backups recommended

### Best Practices
1. **Limit admin access:** Only trusted players with `ignoresPlayerLimit=true`
2. **Regular audits:** Review allowlist periodically
3. **Remove inactive users:** Keep list current
4. **Backup allowlist:** Before making changes

---

## ?? Additional Resources

### Official Minecraft Documentation
- [Bedrock Server Documentation](https://www.minecraft.net/en-us/download/server/bedrock)
- [Server Properties Reference](https://minecraft.fandom.com/wiki/Server.properties)

### Community Resources
- [Minecraft Bedrock Wiki](https://minecraft.fandom.com/wiki/Bedrock_Edition)
- [XUID Lookup Tools](https://xboxgamertag.com)

### MCBDS Manager
- [GitHub Repository](https://github.com/JoshuaBylotas/MCBDSHost)
- [API Documentation](https://github.com/JoshuaBylotas/MCBDSHost/wiki)

---

**Last Updated:** January 2025  
**API Version:** 1.1  
**Feature:** Allowlist Management
