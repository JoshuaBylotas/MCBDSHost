# Command Sending Error Fix

## Problem
When sending the command "hi" (or any command) from the Public UI to the API, an error occurs. The command fails to get a proper response from the Minecraft Bedrock server.

## Root Cause
The issue was in the `SendLineAndReadResponseAsync` method in `RunnerHostedService.cs`. The original implementation had several problems:

1. **Race Condition**: The method tried to attach a new `OutputDataReceived` event handler dynamically, but this conflicted with the existing handler already attached in `StartAsync()`
2. **Event Handler Conflict**: Multiple handlers were competing to consume the same output stream, causing responses to be missed
3. **Unreliable Response Capture**: The temporary event handler approach was fundamentally flawed

## Solution

Replaced the event-handler-based approach with a **log monitoring approach**:

### Key Changes

1. **Log Monitoring Instead of Event Handlers**: Monitor the `_logBuilder` which is already being populated
2. **Baseline Capture**: Store the current log length before sending the command
3. **Polling Approach**: Poll every 100ms to check for new output
4. **Increased Timeout**: Changed from 3000ms to 5000ms
5. **Better Error Handling**: Added proper logging and helpful timeout messages
6. **Thread Safety**: Uses the existing `_lock`

## Benefits

- No conflicts with existing event handlers
- More reliable output capture
- Better debugging with logging
- Graceful timeout handling

## Files Modified

- `MCBDS.API/Background/RunnerHostedService.cs` - Fixed `SendLineAndReadResponseAsync` method

## Build Status

? Build successful - Ready to test
