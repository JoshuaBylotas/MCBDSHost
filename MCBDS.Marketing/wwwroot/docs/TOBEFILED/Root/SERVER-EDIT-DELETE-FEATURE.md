# Server Dropdown Edit and Delete Feature

This document describes the implementation of edit and delete functionality for servers in the ServerSwitcher dropdown across all PublicUI applications.

---

## Overview

Added the ability to edit and delete saved servers from the dropdown menu in:
- **MCBDS.PublicUI** (MAUI app)
- **MCBDS.PublicUI.Web** (Blazor WebAssembly)
- **MCBDS.PublicUI.Android** (uses shared MAUI components)

---

## Features Added

### 1. Edit Server
- **Edit button** (pencil icon) appears next to the dropdown when a server is selected
- Click edit to modify server name and URL
- Changes are saved and the dropdown updates immediately
- Seamlessly switches to the updated server configuration

### 2. Delete Server
- **Delete button** (trash icon) appears next to the edit button
- Click delete to show a confirmation dialog
- Prevents deleting the last remaining server
- Automatically switches to another server if the current one is deleted
- Confirmation dialog prevents accidental deletions

### 3. UI/UX Improvements
- Buttons only appear when more than one server exists
- Clean, minimal design with Bootstrap icons
- Smooth animations for confirmation dialog
- Responsive layout for mobile devices
- Status messages for all operations

---

## User Interface

### Normal View
```
[Server Dropdown ?] [??] [???]
```

### Edit Mode
```
[Server Name Input] [URL Input] [?] [?]
```

### Delete Confirmation
```
Delete server "My Server"?
[? Yes, Delete] [? Cancel]
```

---

## Files Modified

### 1. MCBDS.PublicUI/Components/ServerSwitcher.razor
**Changes:**
- Added `editingServer` state for edit mode
- Added `showDeleteConfirm` state for delete confirmation
- Added `StartEditServer()` method
- Added `SaveEditedServer()` method
- Added `CancelEdit()` method
- Added `ConfirmDeleteServer()` method
- Added `DeleteCurrentServer()` method
- Added `CancelDelete()` method
- Added `GetCurrentServerName()` helper method
- Updated UI to show edit/delete buttons
- Added delete confirmation dialog
- Added edit form

### 2. MCBDS.PublicUI.Web/Components/ServerSwitcher.razor
**Changes:** Same as above

### 3. MCBDS.PublicUI/Components/ServerSwitcher.razor.css
**Changes:**
- Added `.edit-server-form` styles
- Added `.delete-confirm` styles with slide-down animation
- Added button hover effects
- Added mobile responsive styles
- Added `@keyframes slideDown` animation

### 4. MCBDS.PublicUI.Web/Components/ServerSwitcher.razor.css
**Changes:** Same styling updates for Web version

---

## Backend Support

The following services already had the necessary methods:

### IServerConfigService Interface
```csharp
Task<bool> RemoveServerAsync(string url);
Task<bool> AddServerAsync(string name, string url);
```

### ServerConfigService (MAUI)
- `RemoveServerAsync()` - Removes server from saved list
- Automatically switches to another server if current one is deleted
- Persists changes to file system

### WebServerConfigService (Blazor Web)
- `RemoveServerAsync()` - Removes server from saved list
- Automatically switches to another server if current one is deleted
- Persists changes to localStorage

---

## Usage Instructions

### Edit a Server

1. Select the server you want to edit from the dropdown
2. Click the **pencil icon** (??) button
3. Update the server name and/or URL
4. Click the **checkmark** (?) to save
5. Click the **X** to cancel

### Delete a Server

1. Select the server you want to delete from the dropdown
2. Click the **trash icon** (???) button
3. A confirmation dialog appears
4. Click **"Yes, Delete"** to confirm
5. Click **"Cancel"** to abort

---

## Safety Features

### Cannot Delete Last Server
- If only one server exists, delete button is hidden
- Prevents user from having zero servers configured

### Automatic Server Switching
- When current server is deleted, automatically switches to the first available server
- Ensures app remains functional after deletion

### Confirmation Dialog
- Prevents accidental deletions
- Shows server name in confirmation message
- Clear "Yes/No" options

---

## Responsive Design

### Desktop (>768px)
- Buttons display inline next to dropdown
- Full-width inputs in edit mode
- Horizontal button layout in confirmation dialog

### Mobile (<768px)
- All elements stack vertically
- Full-width dropdown, inputs, and buttons
- Vertical button layout in confirmation dialog
- Touch-friendly button sizes

---

## Keyboard Support

All interactive elements are keyboard accessible:
- **Tab** - Navigate between elements
- **Enter** - Activate buttons
- **Escape** - Cancel operations (future enhancement)

---

## Animations

### Slide Down (Delete Confirmation)
```css
@keyframes slideDown {
    from {
        opacity: 0;
        transform: translateY(-10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}
```

### Fade In (Status Messages)
```css
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}
```

### Hover Effects
- Pencil icon scales up on hover
- Trash icon scales up on hover
- Smooth transitions for better UX

---

## Testing Checklist

### Edit Functionality
- [ ] Edit button appears when server is selected
- [ ] Edit form shows current server details
- [ ] Can update server name
- [ ] Can update server URL
- [ ] Save button updates the server
- [ ] Cancel button discards changes
- [ ] Dropdown reflects updated server name
- [ ] App switches to edited server after save

### Delete Functionality
- [ ] Delete button appears when more than 1 server exists
- [ ] Delete button hidden when only 1 server exists
- [ ] Confirmation dialog appears on delete click
- [ ] Server name shown in confirmation dialog
- [ ] "Yes, Delete" removes the server
- [ ] "Cancel" closes dialog without deleting
- [ ] App switches to another server after delete
- [ ] Page reloads to reflect new server

### Edge Cases
- [ ] Cannot delete last remaining server
- [ ] Edit with empty name/URL prevents save
- [ ] Delete confirmation closes on cancel
- [ ] Status messages appear and disappear correctly
- [ ] Mobile responsive layout works correctly

---

## Future Enhancements

### Potential Improvements
1. **Drag-and-drop reordering** of servers
2. **Bulk operations** (delete multiple servers)
3. **Server health indicators** (online/offline status)
4. **Quick switch dropdown** in nav bar
5. **Import/export** server configurations
6. **Server groups/folders** for organization
7. **Keyboard shortcuts** (Ctrl+E to edit, Del to delete)
8. **Undo delete** with temporary restore option

---

## Related Files

### Services
- `MCBDS.ClientUI.Shared/Services/IServerConfigService.cs`
- `MCBDS.ClientUI.Shared/Services/ServerConfigService.cs`
- `MCBDS.PublicUI.Web/Services/WebServerConfigService.cs`

### Components
- `MCBDS.PublicUI/Components/ServerSwitcher.razor`
- `MCBDS.PublicUI/Components/ServerSwitcher.razor.css`
- `MCBDS.PublicUI.Web/Components/ServerSwitcher.razor`
- `MCBDS.PublicUI.Web/Components/ServerSwitcher.razor.css`

---

## Troubleshooting

### Edit button not showing
- Check if more than one server exists
- Verify `savedServers.Count > 1`

### Delete confirmation not appearing
- Check if `showDeleteConfirm` state is being set
- Verify button click event is wired correctly

### Changes not persisting
- Check browser console for localStorage errors (Web)
- Check file permissions for config file (MAUI)
- Verify `SaveConfigAsync()` is being called

### Server not switching after delete
- Check if `RemoveServerAsync()` returns true
- Verify service switches to another server automatically
- Check if page reload is triggered

---

*Last Updated: January 2026*
*Feature Version: 1.0.0*
