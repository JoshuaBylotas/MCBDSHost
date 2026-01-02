# Android Connectivity Fix

## Changes Made

### 1. Network Security Config
Created `Platforms\Android\Resources\xml\network_security_config.xml` to allow HTTP traffic

### 2. HttpClient Configuration  
Updated `MauiProgram.cs` with Android-specific message handler

### 3. AndroidManifest - MANUAL UPDATE REQUIRED

Open `Platforms\Android\AndroidManifest.xml` and update it to:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.mcbds.publicui.android">
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application android:networkSecurityConfig="@xml/network_security_config" android:usesCleartextTraffic="true">
    </application>
</manifest>
```

## Server URL Configuration

### Android Emulator
Use: `http://10.0.2.2:8080`
(10.0.2.2 is the emulator's alias for host machine localhost)

### Physical Device (Same Network)
Use: `http://YOUR-PC-IP:8080`
(Find IP with: `ipconfig` in Windows)

### Remote Server
Use: `http://WINSERVER03.bylotas.net:8081`
