# Installing and setting Windows Languages and Features

- Install Languages (system and default user profile)
- Set Language (user context)

## Install Languages
New PowerShell module - https://docs.microsoft.com/en-gb/powershell/module/languagepackmanagement/?view=windowsserver2022-ps.

Option to deploy as Proactive Remeidation or Win32 app (if you want it to be completed before the user is allowed to use the computer).

 - Requirement script (only required for Win32 app)
 - Detect script
 - Install script

## Set Language (only required in some regions)

In some regions, even after selecting the correct language and keyboard during the out of box experience, Windows will display the language bar (sometimes refered to as ghost keyboards).

To ensure the language bar is not displayed for installations where only 1 language and keyboard is required, you can use the [Set-WinUserLanguageList](https://docs.microsoft.com/en-us/powershell/module/international/set-winuserlanguagelist?view=windowsserver2022-ps) PowerShell commands. This command needs to be run in the user context. This can be done various ways, however using a script to create an Active Setup will ensure the command is only run once per subsequent user logon. This allows the user to change their language settings if necessary from here on. Proactive Remediations or scripts could run more than once and revert the users intentional change to a new language or keyboard.
