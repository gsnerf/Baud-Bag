Coding Guidelines:

Currently there are a number of different styles mixed together in this addon.
To make the code better readable and more coherent we want to achieve a consistent style that fits in better with what the WoW API uses itself.
To achieve this try to follow these guides:
- local variables are lowerCamelCase: totallyImportantValue
- functions are upper CamelCase: GetSomeValue()
- members are upperCamelCase: someObject.SomeMember
- all members that are supposed to be accessible should have a getter: someObject.GetSomeMember()
- boolean variables should indicate that they hold booleans: isOfType, hasSomeProperty etc.
- the same goes for methods that return booleans
- if you create a new file ALWAYS place 'local _' at the top! (prevents unwanted tainting of official UI code)
- no ; for line endings!

Config structure:

Config
	|-1 (Bagset)
	| |-Enabled
	| |-Joined
	| |-ShowBags
	| |-0  (Container with joined bags)
	| |... (Container with joined bags)
	| \-X  (Container with joined bags)
	|   |-BlankTop
	|   |-Columns
	|   |-Scale
	|   |-Coords
	|   |  |-0 (X)
	|   |  \-1 (Y)
	|   |-AutoOpen
	|   |-Name
	|   |-Locked
	|   \-Background
	|
	|-2 (BagSet)
	| |-...
	| \-...
	|
	| [Global options from here on]
	|-RarityColor (true/false)
	|-SellJunk (true/false)
	|-ShowNewItems (true/false)
	\-UseMasque (true/false)

How do WoW Container-IDs (http://wowprogramming.com/docs/api_types#containerID) work:
The containers are differentiated into sets by type. The base types are Bags, Bank, Keyring (REMOVED FROM GAME) and Reagent Bank.
Each container set has a container element, that always exist. Each of those containers has a predefined ID:
- Backpack: 0 (constant BACKPACK_CONTAINER)
- Bank: -1 (constant BANK_CONTAINER)
- Keyring: -2 (KEYRING_CONTAINER)
- Reagent Bank: -3 (REAGENTBANK_CONTAINER)

Some container sets have additional bags that the player can buy and use. Each used bag has a separate ID that indicates in which bag slot the bag is used.  
 - Bags: 4 additional bags, IDs 1 to 4 (NUM_BAG_SLOTS = 4)
 - Bank: 7 additional bags, IDs 5 to 11 (NUM_BANKBAGSLOTS = 7)

Registered to Events:
global:
- ADDON_LOADED
- PLAYER_LOGIN
- PLAYER_MONEY
- ITEM_LOCK_CHANGED
- ITEM_PUSH
- BAG_UPDATE_COOLDOWN
- QUEST_ACCEPTED
- QUEST_REMOVED
- BANKFRAME_OPENED
- PLAYERBANKBAGSLOTS_CHANGED
- MERCHANT_SHOW
- MAIL_SHOW
- AUCTION_HOUSE_SHOW
- MERCHANT_CLOSED
- MAIL_CLOSED
- AUCTION_HOUSE_CLOSED
- BAG_OPEN
- BAG_UPDATE
- BAG_CLOSED
- PLAYERBANKSLOTS_CHANGED
- PLAYERREAGENTBANKSLOTS_CHANGED
- REAGENTBANK_PURCHASED

bank related:
- BANKFRAME_CLOSED


on subbags:
- BAG_UPDATE
- BAG_CLOSED
- ITEM_LOCK_CHANGED
- BAG_UPDATE_COOLDOWN
- UPDATE_INVENTORY_ALERTS



Bag creation:
- the frames for all existing (bought/equipped) bags (or what wow calls "container"s) are created on addon loading or uppon equipping/unlocking ("SubContainer")
- to be able to join multiple bags a wrapper container needs to be created ("Container")
- the first container for each bag set (Bank/Backpack/etc.) is created on startup, the rest uppon configuration
- as the connection Container <-> SubContainer is not fixed on startup SubContainers are initially created without a parent frame
- the parent needs to be set as soon as the appropriate containers are generated (either immediately after startup or after reconfiguring the system)