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
	|   |-Background
	|   \-RarityColor
	|
	\-2 (BagSet)

How do WoW Container-IDs work:
The containers are differentiated into sets by type. The base types are Bags, Bank, Keyring (REMOVED FROM GAME) and Reagent Bank.
Each container set has a container element, that always exist. Each of those containers has a predefined ID:
- Backpack: 0 (constant BACKPACK_CONTAINER)
- Bank: -1 (constant BANK_CONTAINER)
- Keyring: -2 (KEYRING_CONTAINER)
- Reagent Bank: -3 (REAGENTBANK_CONTAINER)

Some container sets have additional bags that the player can buy and use. Each used bag has a separate ID that indicates in which bag slot the bag is used.  
 - Bags: 4 additional bags, IDs 1 to 4 (NUM_BAG_SLOTS = 4)
 - Bank: 7 additional bags, IDs 5 to 11 (NUM_BANKBAGSLOTS = 7)

