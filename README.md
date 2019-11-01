# -TES3MP-Inspect
Enables players to inspect each other's equipments by either command or OnObjectActivate.

## Requires

[DataManager (by urm)](https://github.com/tes3mp-scripts/DataManager)

[ContainerFramework (by urm)](https://github.com/tes3mp-scripts/ContainerFramework)

## Installation

1. Install *DataManager* (has to be installed and put into customScripts first)
2. Install *ContainerFramework* (has to be installed and put into customScripts after DataManager)
2. Download the ```main.lua``` and put it in */server/scripts/custom/Inspect*
3. Open ```customScripts.lua``` and add this code on separate line: ```require("custom.Inspect.main")```

## Description

[CLICK THE PICTURE FOR REFERENCE - YT VIDEO] (TO BE ADDED)


## Configurables (variables that can be changed inside *main.lua* to better suite your needs)

- **scriptConfig.inspectCommand = "gear"** *Command usable in chat (usage: ```/gear <pid>``` or ```/gear <name>```)*
- **scriptConfig.playerCooldown = 10** *(default: 10) Time in seconds between inspect attempts (prevents spamming server with creation of new container)*
- **scriptConfig.warningMessageColor = color.Yellow** *See colors.lua in *server/scripts/* for reference*
- **scriptConfig.useOnObjectActivate = false** *(default: false) Use false if you're using scripts like kanaRevive or those that customize OnObjectActivate behaviour
as you don't want to accidentaly inspect player when you pick him up from the downed state*




Thanks to urm for discussing this topic and ContainerFramework.
