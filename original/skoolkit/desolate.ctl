i $9340 Screen 1st color, 12*8*8 = 768 bytes
i $9872 Screen 2nd color, 12*8*8 = 768 bytes
@ $9DBE start
@ $9DBE org
c $9DBE Start point
C $9DCB,3 DataFile 'DESDATA' Not Found
C $9DCE,3 Clear screen 9340/9872
C $9DD1,3 Initialization
C $9DD4,3 Select interrupt frequency
C $9DD7,3 Clear screen 9340/9872
c $9DDD Game main loop
C $9DDD,3 Get Health
C $9DE1,3 Player is dead
C $9DE4,3 Decode current room
C $9DE7,3 Display 96 tiles on the screen
C $9DEA,3 Display Health
C $9DED,3 Show look/shoot selection indicator
C $9DF6,3 Scan keyboard
C $9DF9,2 CLEAR
C $9DFE,2 Up
C $9E03,2 Down
C $9E08,2 Left
C $9E0D,2 Right
C $9E12,1 Not a valid key
C $9E1C,3 Scan keyboard
C $9E1F,2 Yellow "2nd" key
C $9E21,3 Look / Shoot
C $9E24,2 "XT0n" key
C $9E26,3 Look / Shoot Mode
C $9E29,2 "ALPHA" key
C $9E2B,3 Open the Inventory
C $9E2E,3 Copy screen 9340/9872 to A28F/A58F
c $9E34 DataFile 'DESDATA' Not Found
C $9E37,3 Set penRow/penCol
C $9E3A,3 "DataFile 'DESDATA' Not Found!"
C $9E3D,1 rBR_CALL
W $9E3E,2,2 _VPutS - Displays a zero (0) terminated string
C $9E40,3 Copy screen 9340/9872 to A28F/A58F
C $9E48,3 Delay
c $9E51 Quit menu item selected
C $9E51,3 Clear screen 9340/9872
C $9E54,3 Copy screen 9340/9872 to A28F/A58F
C $9E57,3 Delay
B $9E5E,1,1 Frequency selected: 1/2/4/6
c $9E5F Draw tile with offset
R $9E5F L Row
R $9E5F A X coord
R $9E5F IX Tile address
C $9E76,8 HL <- L * 12
C $9E88,1 now HL = offset on the screen
C $9E89,3 (Argument is changing here)
C $9E8C,1 Add screen address
c $9EAD Put tile on the screen
R $9EAD L Row
R $9EAD E Column
R $9EAD IX Tile address
C $9EAD,8 HL <- L * 12
C $9EB6,1 now HL = offset on the screen
C $9EB8,3 Screen plane 1
C $9EBC,3 offset between lines
C $9EBF,2 Counter = 8
C $9EC4,1 Put on the screen
C $9EC5,3 next line
C $9ECB,3 Screen plane 2
C $9ECF,3 offset between lines
C $9ED2,2 Counter = 8
C $9ED7,1 Put on the screen
C $9ED8,3 next line
c $9EDE Draw tile DE at column H row L
R $9EDE DE Tile address
R $9EDE A ??
R $9EDE H Column
R $9EDE L Row
B $9FAF,16,8 data
B $9FBF,16,8 data
c $9FCF Clear screen 9340/9872
C $9FCF,12 Clear $9340-963F, 768 bytes
C $9FDC,12 Clear $9872-9B71, 768 bytes
c $9FEA Copy screen 9340/9872 to A28F/A58F
c $A001 Initialization??
c $A02E Routine??
B $A0EB,6,6
c $A0F1 Scan keyboard; returns key in A
B $A15E,7,7
B $A165,56,8 Key scan codes: Down=$01, Left=$02, Right=$03, Up=$04, Enter=$09, Alpha=$36, Mode=$37
B $A19D,1,1 Last key pressed
c $A19E Select interrupt frequency
C $A1CF,3 Set penRow/penCol
C $A1D2,3 "Set interrupt frequency:" string
C $A1D5,1 rBR_CALL
W $A1D6,2,2 _VPutS - Displays a zero (0) terminated string
C $A1DB,3 Set penRow/penCol
C $A1E1,1 rBR_CALL
W $A1E2,2,2 _VPutS - Displays a zero (0) terminated string
C $A1E7,3 Set penRow/penCol
C $A1EA,3 "2"
C $A1ED,1 rBR_CALL
W $A1EE,2,2 _VPutS - Displays a zero (0) terminated string
C $A1F3,3 Set penRow/penCol
C $A1F9,1 rBR_CALL
W $A1FA,2,2 _VPutS - Displays a zero (0) terminated string
C $A1FF,3 Set penRow/penCol
C $A202,3 "6"
C $A205,1 rBR_CALL
W $A206,2,2 _VPutS - Displays a zero (0) terminated string
C $A224,3 Copy screen 9340/9872 to A28F/A58F
C $A227,3 Scan keyboard
T $A262,25 "Set interrupt frequency:"
T $A27B,2
T $A27D,2
T $A27F,2
T $A281,2
c $A283 Copy screen 1st color onto Screen 2nd color
i $A28F Screen 1st color, 12*8*8 = 768 bytes
i $A58F Screen 2nd color, 12*8*8 = 768 bytes
c $A88F Display 96 tiles on the screen
R $A88F HL Address where the 96 tiles are placed
C $A8A0,4 HL <- HL * 16
C $A8A4,3 Tileset 1
C $A8AD,3 Put tile on the screen
C $A92F,3 Get X coord in tiles
c $A966 Movement
N $A966 Move Down
C $A96D,3 Get look/shoot switch value
C $A9E3,3 Decrease Health by 4, restore Y coord
N $A99B Move Up
C $A9A3,3 Get look/shoot switch value
N $A9EB Move Left
C $A9F3,3 Get look/shoot switch value
C $AA10,3 Get X coord in tiles
C $AA14,1 X = X - 1
N $AA1A Move Right
C $AA22,3 Get look/shoot switch value
C $AA3F,3 Get X coord in tiles
C $AA43,1 X = X + 1
C $AA59,3 Decrease Health by 4, restore X coord
c $AA60 Routine??
C $AA60,3 Decode current room
C $AA63,3 Get X coord in tiles
c $AA78 Routine??
c $AA7D Routine??
c $AA8D Routine??
C $AAA5,3 Get X coord in tiles
c $AAAF Look / Shoot
C $AAAF,3 Get look/shoot switch value
c $AB28 Show small message popup
C $AB2D,3 Decode from: Small message popup
C $AB30,3 Decode to
C $AB33,3 Decode the room
C $AB39,3 Display screen from tiles with Tileset #2
C $AB4B,3 Get room number
C $AB53,3 Weapon slot
C $AB64,3 Show small message popup
C $AB67,3 Set penRow/penCol for small message popup
C $AB6A,3 -> "It is not wise to proceed| without a weapon."
C $AB6D,3 Load archived string and show message char-by-char
N $AB73 Set penRow/penCol for small message popup
C $AB76,3 Set penRow/penCol
C $AB87,3 Set Access code level
C $AB9A,3 Get Access code level
C $ABE5,3 Show small message popup
C $ABEB,3 Set penRow/penCol
C $ABEE,3 -> "You cant enter that sector| Life-Support is offline."
C $ABF1,3 Load archived string and show message char-by-char
C $AC2C,3 Show small message popup
C $AC32,3 Set penRow/penCol
C $AC35,3 -> "You cant enter until the|AirLock is re-pressurised"
C $AC38,3 Load archived string and show message char-by-char
c $AC54 Routine??
C $AC7C,3 Show small message popup
C $AC7F,3 Set penRow/penCol for small message popup
C $AC82,3 " Another Dead Person"
C $AC85,3 Load archived string and show message char-by-char
C $AC8B,3 Set penRow/penCol
C $AC8E,3 " Search Reveals Nothing"
C $AC91,3 Load archived string and show message char-by-char
C $ACA6,3 Show small message popup
C $ACA9,3 Set penRow/penCol for small message popup
C $ACAC,3 " This Person is Dead . . ."
C $ACAF,3 Load archived string and show message char-by-char
C $ACBB,3 Set penRow/penCol
C $ACBE,3 String with arrow down sign
C $ACC1,3 Load archived string and show message char-by-char
C $ACC5,3 Show small message popup
C $ACC8,3 Set penRow/penCol for small message popup
C $ACCB,3 "OMG! This Person Is DEAD!"
C $ACCE,3 Load archived string and show message char-by-char
C $ACD4,3 Set penRow/penCol
C $ACD7,3 "What Happened Here!?!"
C $ACDA,3 Load archived string and show message char-by-char
c $ACE3 Routine??
C $ACF6,3 Copy screen 9340/9872 to A28F/A58F
C $ACF9,3 Wait for Down key
C $ACFC,3 Show small message popup
c $AD00 Routine??
C $AD06,3 Set penRow/penCol
C $AD09,3 "They Seem To Be Holding"
C $AD0C,3 Load archived string and show message char-by-char
C $AD12,3 Set penRow/penCol
C $AD15,3 "Something"
C $AD18,3 Load archived string and show message char-by-char
C $AD2B,3 Set penRow/penCol
C $AD2E,3 "You Picked Up A"
C $AD31,3 Load archived string and show message char-by-char
C $AD37,3 Set penRow/penCol
C $AD3D,3 Load archived string and show message char-by-char
c $AD4F Routine??
C $AD73,3 Show small message popup
C $AD79,3 Set penRow/penCol
C $AD7C,3 " Hey Whats This . . . ?"
C $AD7F,3 Load archived string and show message char-by-char
C $AD8C,3 Copy screen 9340/9872 to A28F/A58F
C $AD8F,3 Scan keyboard
C $AD92,2 Mode key?
c $AD99 Wait for Down key
C $AD99,3 Scan keyboard
C $AD9C,2 Down key?
c $ADA1 Wait for MODE key
C $ADA1,3 Scan keyboard
c $ADA9 We've got weapon
C $ADA9,3 Weapon slot
C $ADB0,3 Show small message popup
C $ADB5,3 We've got the weapon
C $ADBB,3 Set penRow/penCol
C $ADBE,3 -> "     Hey Whats This  .  .  . ?"
C $ADC1,3 Load archived string and show message char-by-char
C $ADCD,3 Set penRow/penCol
C $ADD0,3 "You Picked Up A"
C $ADD3,3 Load archived string and show message char-by-char
C $ADD9,3 Set penRow/penCol
C $ADDC,3 " Ion Phaser"
C $ADDF,3 Load archived string and show message char-by-char
c $ADE5 Decode current room
C $ADE5,3 Get the room number
C $ADE8,3 List of encoded room addresses
C $ADEB,3 now HL = encoded room
C $ADF1,3 Decode the room to DBF5
c $ADF5 Decode the room to DBF5
R $ADF5 HL Decode from
R $ADF5 BC Tile count to decode
C $ADF5,3 Decode to
C $ADF8,3 Decode the room
c $ADFF Get address from table
R $ADFF A Element number
R $ADFF HL Table address
c $AE09 Routine??
C $AE09,3 Get room number
C $AE0C,3 Table of adresses for room descriptions
C $AE45,3 Encoded screen: Door access panel popup
C $AE48,3 Decode the room to DBF5
C $AE4B,3 Display screen from tiles with Tileset #2
C $AE5A,3 ": Door Locked :"
C $AE5D,3 Load archived string and show message char-by-char
C $AE63,3 Set penRow/penCol
C $AE66,3 Get "Access code level N required" string by access level in DC8C
C $AE69,3 Load archived string and show message char-by-char
C $AE83,3 Tileset 2
C $AE96,3 Copy screen 9340/9872 to A28F/A58F
C $AE9B,3 Delay
C $AEA0,3 Scan keyboard
C $AEF7,3 Tileset 2
C $AF0E,3 Copy screen 9340/9872 to A28F/A58F
C $AF20,3 " INVALID CODE"
C $AF23,3 Load archived string and show message char-by-char
C $AF26,3 Copy screen 9340/9872 to A28F/A58F
C $AF42,3 " Accepted! "
C $AF45,3 Load archived string and show message char-by-char
C $AFD5,3 Tileset 2
C $AFE8,3 Copy screen 9340/9872 to A28F/A58F
C $AFED,3 Get Access code level
C $AFFE,3 Get Access code level
C $B005,3 Access code messages table
c $B00E Routine??
C $B030,3 Delay
C $B063,3 Set X coord = 10
C $B070,3 Set X coord = 1
N $B07B Decrease Health by 4, restore Y coord
C $B07D,3 Decrease Health
N $B08D Decrease Health by 4, restore X coord
C $B08F,3 Decrease Health
C $B094,1 Restore old X coord
C $B095,3 Set X coord
C $B09E,3 Set penRow/penCol
c $B0A2 Open Inventory
C $B0A2,3 Titles count to decode
C $B0A5,3 Encoded screen for Inventory popup
C $B0A8,3 Decode the room to DBF5
C $B0AB,3 Display screen from tiles with Tileset #2
C $B0B9,3 Data cartridge reader slot
C $B0D5,3 " - INVENTORY - "
C $B0D8,3 Load archived string and show message char-by-char
c $B177 Display screen from tiles with Tileset #2
R $B177 HL Screen in tiles, usually $DBF5
C $B188,3 Tileset 2
C $B1BB,3 Load archived string and show message char-by-char
C $B1C1,3 Scan keyboard
C $B298,3 Tileset 2
C $B2AB,3 Copy screen 9340/9872 to A28F/A58F
C $B2B2,3 Set penRow/penCol
c $B2D0 Delay by DC59
c $B2DE Routine??
C $B2F7,3 Set penRow/penCol
C $B2FD,1 rBR_CALL
W $B2FE,2,2 _VPutS - Displays a zero (0) terminated string
N $B301 We've got Data cartridge reader
C $B303,3,1 Data cartridge reader slot
C $B31A,1,1 $00 - Data cartridge reader
C $B31E,2,2 Power Drill?
C $B323,2,2 Life Support Data Disk?
C $B328,2,2 Air-Lock Tool?
C $B32D,2,2 Box of Power Cells
C $B332,2,2 Rubik's Cube
C $B337,2 Data cartridge?
c $B33F Data cartridge reader selected in the Inventory
C $B34A,3 Data cartridge reader screen
C $B350,3 Display screen from tiles with Tileset #2
C $B363,3 Set penRow/penCol
C $B366,3 "         No Data Cartridge| Selected"
C $B36F,3 Set penRow/penCol
C $B373,3 Load archived string and show message char-by-char
C $B388,3 Copy screen 9340/9872 to A28F/A58F
C $B38B,3 Scan keyboard
c $B3AF Data cartridge selected in the Inventory
C $B3AF,3 Data cartridge reader
C $B3BC,3 Get address from table
C $B3CE,3 Set penRow/penCol
C $B3D1,3 " You Need A|Data Cartridge Reader"
C $B3D4,3 Show message
C $B3EB,3 "You dont seem to be able| to use this item here"
C $B3EE,3 Show message
c $B3F4 Power drill selected in the Inventory
C $B41F,3 " You use the Power Drill|to Repair the Generator"
C $B422,3 Show message
C $B43E,3 Set penRow/penCol
C $B441,3 " It doesnt look like you| can do anything else here"
C $B444,3 Show message
c $B44A Life Support Data Disk selected in the Inventory
C $B475,3 " Life-Support System|has been fully restored"
C $B478,3 Show message
c $B487 Air-Lock Tool selected in the Inventory
C $B4B2,3 "The Evacuation Deck has| been re-pressurised"
C $B4B5,3 Show message
c $B4C4 Box of Power Cells selected in the Inventory
C $B4EF,3 "You Insert a Power Cell.|Guidance System Online"
C $B4F2,3 Show message
c $B501 Rubik's Cube selected in the Inventory
C $B50A,3 "You dont have any time| to play with this now"
C $B50D,3 Show message
c $B513 Show message HL
C $B513,3 Load archived string and show message char-by-char
C $B516,3 Copy screen 9340/9872 to A28F/A58F
c $B551 Routine??
c $B653 Routine??
C $B6B0,3 Decode current room
C $B73B,3 Decrease Health
C $B746,3 Decrease Health
c $B758 Shoot with the Weapon
c $B76B Routine??
C $B87C,3 Decode current room
c $B8EA Show look/shoot selection indicator
C $B8EA,3 Get look/shoot switch value
c $B925 Routine??
c $B930 Switch Look / Shoot mode
C $B930,3 Weapon slot
C $B93A,3 Show small message popup
C $B940,3 Set penRow/penCol
C $B943,3 "You dont have a| Weapon to equip!"
C $B946,3 Load archived string and show message char-by-char
C $B94C,3 Get look/shoot switch value
C $B965,3 Delay
c $B96B Display Health
C $B96E,3 Set penRow/penCol
C $B971,3 Get Health
C $B979,1 rBR_CALL
W $B97A,2,2 _DispOP1A - Rounds a floating-point number to the current fix setting and display it at the current pen location
c $B97D Routine??
C $B97D,3 Set penRow/penCol
C $B986,1 rBR_CALL
W $B987,2,2 _DispOP1A - Rounds a floating-point number to the current fix setting and display it at the current pen location
C $B989,3 Copy screen 9340/9872 to A28F/A58F
C $B98D,1 rBR_CALL
W $B98E,2,2 _SetXXXXOP2 - Load a floating-point value into an OP register
C $B990,1 rBR_CALL
W $B991,2,2 _OP2ToOP1 - Transfer one OP register to another
c $B994 Decrease Health
C $B997,2 Health = Health minus 2
c $B9A2 Player is dead, Health 0
C $B9A2,3 Clear screen 9340/9872
C $B9AF,3 Show small message popup
C $B9B5,3 Set penRow/penCol
C $B9B8,3 "The Desolate has claimed|your life too . . ."
C $B9BB,3 Load archived string and show message char-by-char
C $B9C9,3 Copy screen 9340/9872 to A28F/A58F
C $B9CC,3 Scan keyboard
C $B9CF,2 "MODE" key
C $B9DE,3 Set X coord = 6
C $B9EB,2 Health = 100
c $B9F1 Decode the room
R $B9F1 HL Decode from
R $B9F1 BC Decode to
c $BA07 Show titles and show Menu
C $BA12,3 Set penRow/penCol
C $BA15,3 "MaxCoderz Presents"
C $BA18,3 Load archived string and show message char-by-char
C $BA1E,3 Clear screen 9340/9872 and copy to A28F/A58F
C $BA27,3 Set penRow/penCol
C $BA2A,3 "a tr1p1ea game"
C $BA2D,3 Load archived string and show message char-by-char
C $BA33,3 Clear screen 9340/9872 and copy to A28F/A58F
c $BA3D Return to Menu
C $BA4D,3 Display 96 tiles on the screen
C $BA50,3 Main menu screen
C $BA54,3 Display screen from tiles with Tileset #2
C $BA59,3 Tile arrow right
C $BA62,3 Tile arrow left
C $BA69,3 Copy screen 9340/9872 to A28F/A58F
C $BA6C,3 Scan keyboard
C $BA74,2 Up key
C $BA79,2 Down key
c $BA81 Routine??
c $BA88 Draw menu item selection triangles
c $BA93 Menu item selected
C $BA98,3 New menu item
C $BA9D,3 Continue menu item
C $BAA2,3 Info menu item
C $BAA7,3 Credits menu item
C $BAAC,3 Quit menu item
N $BAB2 New menu item selected
C $BABC,3 Show small message popup
C $BAC2,3 Set penRow/penCol
C $BAC5,3 "OverWrite Current Game?|Alpha = Yes :: Clear = No"
C $BAC8,3 Load archived string and show message char-by-char
C $BACB,3 Copy screen 9340/9872 to A28F/A58F
C $BACE,3 Scan keyboard
c $BADE New Game
C $BADF,3 Weapon slot
C $BAE2,3 Set look/shoot switch value = look
C $BB2E,3 Clear screen 9340/9872 and copy to A28F/A58F
C $BB48,3 "In the Distant Future . . ."
C $BB4B,3 Load archived string and show message char-by-char
C $BB51,3 Clear screen 9340/9872 and copy to A28F/A58F
C $BB57,3 Set zero penRow/penCol
C $BB5A,3 "'The Desolate' Space Cruiser|leaves orbit. ..."
C $BB5D,3 Load archived string and show message char-by-char
C $BB66,3 String with arrow down sign
C $BB69,3 Load archived string and show message char-by-char
C $BB6C,3 Wait for Down key
C $BB6F,3 Clear screen 9340/9872
C $BB72,3 Set zero penRow/penCol
C $BB75,3 "The ship sustains heavy|damage. ..."
C $BB78,3 Load archived string and show message char-by-char
C $BB7B,3 Wait for MODE key
c $BB7E Game start
N $BB82 Continue menu item selected
C $BB8C,3 Delay
N $BBA4 Menu up step
N $BBC1 Menu down step
N $BBCC Menu up key pressed
N $BBDC Menu down key pressed
N $BBEC Info menu item, show Controls
C $BBEC,3 Counter = 96 bytes or tiles
C $BBEF,3 Decode from - Encoded screen for Inventory popup
C $BBF2,3 Where to decode
C $BBF5,3 Decode the room
C $BBFB,3 Display screen from tiles with Tileset #2
C $BC0B,3 Set penRow/penCol
C $BC0E,3 "- Controls -"
C $BC11,3 Load archived string and show message char-by-char
C $BC17,3 Set penRow/penCol
C $BC1A,3 "2nd = Look / Shoot|Alpha = Inventory ..."
C $BC1D,3 Load archived string and show message char-by-char
C $BC20,3 Copy screen 9340/9872 to A28F/A58F
C $BC23,3 Wait for MODE key
C $BC26,3 Return to Menu
C $BC36,3 Delay
c $BC3C Routine??
R $BC3C HL ??
C $BC4E,1 rBR_CALL
W $BC4F,2,2
C $BC53,1 rBR_CALL
W $BC54,2,2 _DispOP1A - Rounds a floating-point number to the current fix setting and display it at the current pen location
C $BC66,1 rBR_CALL
W $BC67,2,2 _VPutMap - Displays either a small variable width or large 5x7 character at the current pen location and updates penCol.
c $BC6B Routine??
c $BC7D Clear screen 9340/9872 and copy to A28F/A58F
C $BC7D,3 Clear screen 9340/9872
C $BC80,3 Copy screen 9340/9872 to A28F/A58F
c $BC84 Set zero penRow/penCol
C $BC87,3 Set penRow/penCol
c $BC8B ??
C $BC9B,3 Show small message popup
C $BCC2,3 " It doesnt look like you| can do anything else here"
C $BCC5,3 Load archived string and show message char-by-char
C $BCC8,3 Copy screen 9340/9872 to A28F/A58F
C $BCCB,3 Scan keyboard
C $BD22,3 Load archived string and show message char-by-char
C $BD25,3 Copy screen 9340/9872 to A28F/A58F
C $BD28,3 Show small message popup
C $BD2B,3 Scan keyboard
C $BD6C,3 Set penRow/penCol
C $BD99,3 Clear screen 9340/9872
C $BD9F,3 Set penRow/penCol
C $BDA5,3 Load archived string and show message char-by-char
C $BDB0,3 Clear screen 9340/9872
C $BDB6,3 Set penRow/penCol
C $BDBC,3 Load archived string and show message char-by-char
C $BDF4,3 Set penRow/penCol
C $BDFA,3 Load archived string and show message char-by-char
C $BE09,3 Set penRow/penCol
C $BE0F,3 Load archived string and show message char-by-char
C $BF11,3 Delay
C $BE18,1 rBR_CALL
W $BE19,2,2
C $BE20,3 Set penRow/penCol
C $BE26,3 Load archived string and show message char-by-char
C $BE35,3 Set penRow/penCol
C $BE3B,3 Load archived string and show message char-by-char
C $BE44,1 rBR_CALL
W $BE45,2,2
C $BE4C,3 Set penRow/penCol
C $BE52,3 Load archived string and show message char-by-char
C $BE61,3 Set penRow/penCol
C $BE64,3 "Over & Over Again" (achievement)
C $BE67,3 Load archived string and show message char-by-char
C $BE6D,3 Clear screen 9340/9872
C $BE7E,3 Set penRow/penCol
C $BE81,3 "System Alert triggered: ..."
C $BE84,3 Load archived string and show message char-by-char
C $BE92,3 Set penRow/penCol
C $BE95,3 "Earn 3 Good Awards for|an Extended Ending!"
C $BE98,3 Load archived string and show message char-by-char
C $BE9E,3 Clear screen 9340/9872
C $BEA4,3 Set penRow/penCol
C $BEA7,3 "The End"
C $BEAA,3 Load archived string and show message char-by-char
C $BEB0,3 The End
C $BEBC,1 rBR_CALL
W $BEBD,2,2
C $BEBF,1 rBR_CALL
W $BEC0,2,2
C $BEC2,3 DataFile 'DESDATA' Not Found
C $BEC7,3 DataFile 'DESDATA' Not Found
c $BEDE Load archived string and show message char-by-char
R $BEDE HL Address of archived string offset
C $BF05,1 rBR_CALL
W $BF06,2,2 _VPutMap - Displays either a small variable width or large 5x7 character at the current pen location and updates penCol.
C $BF14,3 Copy screen 9340/9872 to A28F/A58F
c $BF31 Routine??
c $BF47 Routine?? Load from Archive
C $BF47,1 rBR_CALL
W $BF48,2,2 _LoadCIndPaged - Copies a byte from the archive to C
c $BF54 Set variables for Credits
c $BF64 Credits menu item selected
C $BF64,3 Clear screen 9340/9872
C $BF67,3 Copy screen 9340/9872 to A28F/A58F
c $BF6F The End
C $BF6F,3 Clear screen 9340/9872
C $BF78,3 Set penRow/penCol
C $BF7B,3 "The End"
C $BF7E,3 Load archived string and show message char-by-char
C $BF89,3 Delay
N $BF81 Credits screen text scrolls up
C $BF8C,3 Scan keyboard
C $BF91,3 Return to main Menu
C $BFC3,3 Load archived string and show message char-by-char
C $BFD2,3 Return to main Menu
b $BFF8 Encoded rooms
B $BFF8,85,16 Room #0
B $C04D,80,16 Room #1
B $C09D,87,16 Room #2
B $C0F4,77,16 Room #3
B $C141,76,16 Room #4
B $C18D,81,16 Room #5
B $C1DE,80,16 Room #6
B $C1DE,80,16 Room #7
B $C22E,72,16 Room #8
B $C276,70,16 Room #9
B $C2BC,56,16 Room #10
B $C2F4,75,16 Room #11
B $C33F,78,16 Room #12
B $C38D,70,16 Room #13
B $C3D3,75,16 Room #14
B $C41E,73,16 Room #15
B $C467,67,16 Room #16
B $C4AA,77,16 Room #17
B $C4F7,65,16 Room #18
B $C538,76,16 Room #19
B $C584,66,16 Room #20
B $C5C6,67,16 Room #21
B $C609,60,16 Room #22
B $C645,77,16 Room #23
B $C645,77,16 Room #24
B $C692,74,16 Room #25
B $C692,74,16 Room #26
B $C6DC,68,16 Room #27
B $C720,70,16 Room #28
B $C766,77,16 Room #29
B $C7B3,66,16 Room #30
B $C7F5,66,16 Room #31
B $C837,67,16 Room #32
B $C87A,73,16 Room #33
B $C8C3,64,16 Room #34
B $C8C3,64,16 Room #35
B $C903,56,16 Room #37
B $C93B,62,16 Room #38
B $C979,72,16 Room #39
B $C9C1,70,16 Room #40
B $CA07,71,16 Room #41
B $CA4E,68,16 Room #42
B $CA92,66,16 Room #43
B $CAD4,69,16 Room #44
B $CB19,66,16 Room #45
B $CB5B,71,16 Room #46
B $CBA2,72,16 Room #47
B $CBEA,62,16 Room #48
B $CC28,64,16 Room #49
B $CC68,65,16 Room #50
B $CCA9,70,16 Room #51
B $CCEF,71,16 Room #52
B $CD36,69,16 Room #53
B $CD7B,65,16 Room #54
B $CDBC,77,16 Room #55
B $CE09,68,16 Room #56
B $CE4D,70,16 Room #57
B $CE93,70,16 Room #58
B $CE93,70,16 Room #59
B $CED9,71,16 Room #60
B $CF20,57,16 Room #61
B $CF59,71,16 Room #62
B $CFA0,62,16 Room #63
B $CFDE,96,16 Room #64
B $D03E,68,16 Room #65
B $D082,81,16 Room #66
B $D0D3,76,16 Room #67
B $D11F,96,16 Room #68
B $D17F,60,16 Room #69
B $D1BB,73,16 Room #70
B $D204,63,16 Room #71
B $D243,41,16 Room #0 desc
B $D26C,31,16 Room #1 desc
B $D28B,39,16 Room #2 desc
B $D2B2,34,16 Room #3 desc
B $D2D4,37,16 Room #4 desc
B $D2F9,39,16 Room #5 desc
B $D320,0,16 Room #6 desc
B $D320,38,16 Room #7 desc
B $D346,32,16 Room #8 desc
B $D366,37,16 Room #9 desc
B $D38B,30,16 Room #10 desc
B $D3A9,40,16 Room #11 desc
B $D3D1,39,16 Room #12 desc
B $D3F8,31,16 Room #13 desc
B $D417,33,16 Room #14 desc
B $D438,36,16 Room #15 desc
B $D45C,39,16 Room #16 desc
B $D483,31,16 Room #17 desc
B $D4A2,34,16 Room #18 desc
B $D4C4,35,16 Room #19 desc
B $D4E7,33,16 Room #20 desc
B $D508,33,16 Room #21 desc
B $D529,44,16 Room #22 desc
B $D555,0,16 Room #23 desc
B $D555,36,16 Room #24 desc
B $D579,0,16 Room #25 desc
B $D579,36,16 Room #26 desc
B $D59D,40,16 Room #27 desc
B $D5C5,33,16 Room #28 desc
B $D5E6,39,16 Room #29 desc
B $D60D,35,16 Room #30 desc
B $D630,39,16 Room #31 desc
B $D657,44,16 Room #32 desc
B $D683,37,16 Room #33 desc
B $D6A8,0,16 Room #34 desc
B $D6A8,38,16 Room #35 desc
B $D6CE,31,16 Room #37 desc
B $D6ED,30,16 Room #38 desc
B $D70B,35,16 Room #39 desc
B $D72E,33,16 Room #40 desc
B $D74F,41,16 Room #41 desc
B $D778,37,16 Room #42 desc
B $D79D,39,16 Room #43 desc
B $D7C4,35,16 Room #44 desc
B $D7E7,34,16 Room #45 desc
B $D809,34,16 Room #46 desc
B $D82B,39,16 Room #47 desc
B $D852,33,16 Room #48 desc
B $D873,33,16 Room #49 desc
B $D894,36,16 Room #50 desc
B $D8B8,35,16 Room #51 desc
B $D8DB,36,16 Room #52 desc
B $D8FF,31,16 Room #53 desc
B $D91E,38,16 Room #54 desc
B $D944,37,16 Room #55 desc
B $D969,36,16 Room #56 desc
B $D98D,33,16 Room #57 desc
B $D9AE,0,16 Room #58 desc
B $D9AE,33,16 Room #59 desc
B $D9CF,33,16 Room #60 desc
B $D9F0,31,16 Room #61 desc
B $DA0F,34,16 Room #62 desc
B $DA31,29,16 Room #63 desc
B $DA4E,38,16 Room #64 desc
B $DA74,28,16 Room #65 desc
B $DA90,39,16 Room #66 desc
B $DAB7,35,16 Room #67 desc
B $DADA,41,16 Room #68 desc
B $DB03,34,16 Room #69 desc
B $DB25,39,16 Room #70 desc
B $DB4C,96,16 Room #71 desc
b $DB73 Variables??
B $DB73,1,1 ?? $00 $01
B $DB74,1,1 ??
B $DB75,1,1 Direction/orientation?? $00 $01 $02 $03
B $DB76,1,1 X coord in tiles?? $01 $06 $0A INC/DEC
B $DB77,1,1 Y coord on the screen?? $18 $30
B $DB78,1,1 Y coord in tiles?? $03 $06 INC/DEC
B $DB79,1,1 Room number
B $DB7A,1,1 Health; initially $64
B $DB7D,1,1 Look/shoot switch: $00 look, $01 shoot
B $DB80,1,1 ??
B $DB88,1,1 ?? copy of DB76
B $DB89,1,1 ?? copy of DB77
B $DB8A,1,1 ?? copy of DB78
B $DB8B,1,1 ?? copy of DB75
B $DB8D,1,1 ?? $01
B $DB8F,1,1 Menu Y pos: $1D $23 $29 $2F $35
B $DB90,9,9 ??
B $DB9C,34,10 Inventory items??
W $DBC3,2,2 ??
W $DBC5,2,2 ??
B $DBC7,1,1 Counter?? $00 INC
B $DBC8,1,1 ??
W $DBC9,2,2 ??
W $DBD4,2,2 ??
T $DBD6
B $DBF4,1,1 ??
b $DBF5 Room in titles
B $DBF5,96,12 Place for room or screen in titles, 12 * 8 = 96 bytes
B $DC55,1,1 ??
B $DC59,1,1 Delay factor; $64 $28 $00 $44 $96 $FF
B $DC5B,34,10 ??
B $DC85,1,1 ??
B $DC87,1,1 ??
B $DC88,1,1 ?? counter
B $DC89,1,1 ?? smth about Inventory?
B $DC8C,1,1 Access code level (0..4)
B $DC92,16,4 ?? smth about access code
B $DCF3,1,1 Left margin size for text, usually $00
B $DCF4,1,1 Line interval for text
B $DCF5,1,1 Data cartridge reader ??
B $DCF6,1,1 ??
B $DCF7,1,1 Weapon ??
B $DCF8,1,1 ??
B $DD54,1,1 ??
B $DD55,1,1 ??
B $DD56,1,1 ??
B $DD57,1,1 ??
b $DD58 List of string addresses for Credits
W $DD58,2 -> "Code, GFX, Story etc"
W $DD5A,2 -> "Patrick Prendergast"
W $DD5C,2 -> "                     "
W $DD5E,2 -> "Acknowledgements"
W $DD60,2 -> "Durk Kingma - Grayscale"
W $DD62,2 -> "Kerey Roper - Huffman"
W $DD64,2 -> "Joe Pemberton - RLE"
W $DD66,2 -> "Joe Wingbermuehle - Ion"
W $DD68,2 -> "Tijl Coosemans - Venus"
W $DD6A,2 -> "DetachedS - MirageOS"
W $DD6C,2 -> "                     "
W $DD6E,2 -> "Testers"
W $DD70,2 -> "David Sleight"
W $DD72,2 -> "John Sleight"
W $DD74,2 -> "Durk Kingma"
W $DD76,2 -> "Joe Pemberton"
W $DD78,2 -> "Shawn McAndrews"
W $DD7A,2 -> "Tom King"
W $DD7C,2 -> "Domi Alex"
W $DD7E,2 -> "Sammy Griff"
W $DD80,2 -> "Dennis Tseng"
W $DD82,2 -> "AndySoft"
W $DD84,2 -> "jedbouy"
W $DD86,2 -> "Bram Tant"
W $DD88,2 -> "Martin Warmer"
W $DD8A,2 -> "Vincent Junemann"
W $DD8C,2 -> "Michael Angel"
W $DD8E,2 -> "ABlakRain"
W $DD90,2 -> "Travis Supalla"
W $DD92,2 -> "Jim Dieckmann"
W $DD94,2 -> "                     "
W $DD96,2 -> "Special Thanks & Greetz"
W $DD98,2 -> "Everyone @ MaxCoderz"
W $DD9A,2 -> "Everyone on TCPA (EFNet)"
W $DD9C,2 -> "ticalc.org"
W $DD9E,2 -> "                     "
W $DDA0,2 -> "                     "
W $DDA2,2 -> "No animals were hurt more"
W $DDA4,2 -> "than once during the"
W $DDA6,2 -> "making of this game."
W $DDA8,2 -> "                     "
W $DDAA,2 -> "Just Kidding ;P"
W $DDAC,2 -> "                     "
W $DDAE,2 -> "                     "
W $DDB0,2 -> "Thanks for Playing!"
W $DDB2,2 -> "tr1p1ea@yahoo.com.au"
W $DDB4,2 -> "                     "
W $DDB6,2 -> "                     "
W $DDB8,2 -> "                     "
W $DDBA,2 -> "                     "
W $DDBC,2 -> "                     "
W $DDBE,2 -> "                     "
W $DDC0,2 -> "                     "
W $DDC2,2 -> "                     "
W $DDC4,2 -> "                     "
W $DDC6,2 -> "                     "
W $DDC8,2 -> "                     "
W $DDCA,2 -> "                     "
W $DDCC,2 -> "visit www.MaxCoderz.com"
W $DDCE,2 -> "                     "
W $DDD0,2 -> "                     "
W $DDD2,2 -> "                     "
W $DDD4,2 -> "                     "
W $DDD6,2 -> "                     "
W $DDD8,2 -> "                     "
W $DDDA,2 -> "                     "
W $DDDC,2 -> "                     "
W $DDDE,2 -> "                     "
W $DDE0,2 -> "                     "
W $DDE2,2 -> "                     "
W $DDE4,2 -> "                     "
W $DDE6,2 -> "                     "
W $DDE8,2 -> "                     "
W $DDEA,2 -> "                     "
W $DDEC,2 -> "                     "
W $DDEE,2 -> "                     "
W $DDF0,2 -> "                     "
b $DDF2 Data??
B $DDF2,,10
w $DE97 List of encoded room addresses
W $DE97,144,10
W $DF27,258,10
W $DFB7,2,2 Data cartridge reader
W $DFB9,10,10 Data Cartridge 1 / 2 / 3 / 4 / 5
W $DFC3,10,10 Data Cartridge 6 / 7 / 8 / 9 / 10
W $DFCD,10,10 Data Cartridge 11 / 12 / 13 / 14 / 15
W $DFD7,10,10 Data Cartridge 16 /  /  / Power Drill / Life Support Data Disk
W $DFE1,10,10 Air-Lock Tool / Box of Power Cells / Pile of Parts / Duck Idol ;) / Rubik's Cube
W $DFEB,8,8
W $DFF3,54,10 Table of strings: data cartridge messages
W $E015,10,10 Table ?? access code
W $E01F,10,10 Table of strings: access code messages
W $E029,114,8
w $E029 Archived strings offsets
W $E029,2 -> "                     "
W $E02B,2 -> "Code, GFX, Story etc"
W $E02D,2 -> "Patrick Prendergast"
W $E02F,2 -> "Acknowledgements"
W $E031,2 -> "Durk Kingma - Grayscale"
W $E033,2 -> "Kerey Roper - Huffman"
W $E035,2 -> "Joe Pemberton - RLE"
W $E037,2 -> "Joe Wingbermuehle - Ion"
W $E039,2 -> "Tijl Coosemans - Venus"
W $E03B,2 -> "DetachedS - MirageOS"
W $E03D,2 -> "Testers"
W $E03F,2 -> "David Sleight"
W $E041,2 -> "John Sleight"
W $E043,2 -> "Durk Kingma"
W $E045,2 -> "Joe Pemberton"
W $E047,2 -> "Shawn McAndrews"
W $E049,2 -> "Tom King"
W $E04B,2 -> "Domi Alex"
W $E04D,2 -> "Sammy Griff"
W $E04F,2 -> "Dennis Tseng"
W $E051,2 -> "AndySoft"
W $E053,2 -> "jedbouy"
W $E055,2 -> "Bram Tant"
W $E057,2 -> "Martin Warmer"
W $E059,2 -> "Vincent Junemann"
W $E05B,2 -> "Michael Angel"
W $E05D,2 -> "Special Thanks & Greetz"
W $E05F,2 -> "Everyone @ MaxCoderz"
W $E061,2 -> "Everyone on TCPA (EFNet)"
W $E063,2 -> "ticalc.org"
W $E065,2 -> "No animals were hurt more"
W $E067,2 -> "than once during the"
W $E069,2 -> "making of this game."
W $E06B,2 -> "Just Kidding ;P"
W $E06D,2 -> "Thanks for Playing!"
W $E06F,2 -> "visit www.MaxCoderz.com"
W $E071,2 -> "ABlakRain"
W $E073,2 -> "Travis Supalla"
W $E075,2 -> "Jim Dieckmann"
W $E077,2 -> "tr1p1ea@yahoo.com.au"
W $E079,2 -> "Im hurt bad . . . I dont|think im gonna make it.|I changed the Level 1|Access Code to: 4057|Maybe that will hold|them off for a while . . ."
W $E07B,2 -> "For security reasons I|had to change the|Level 2 Access Code.|Maybe now the crew|will stop stealing stuff!|It is:"
W $E07D,2 -> "The system is going|haywire. The Level 3|Access Code was over-|written. I only just|recovered it. Turns out|It is:"
W $E07F,2 -> "Crew I am honoured to|have served as your|captain. The Level 4|Access Code will get|to the evacuation deck|It is:"
W $E081,2 -> "Willis and I are stuck.|Needless to say we are|both done for. We might|have had a chance, but|some idiot changed the|Level 1 Access Code!"
W $E083,2 -> "I dont see why I should|be the one who has to|fix the generator.|There is no way im|going with those things|all over the place . . ."
W $E085,2 -> "DrMorgan: Meteorite|shower claimed a lot|of the crew, however|some feature strange|abrations. Almost like|bite marks . . ?"
W $E087,2 -> "DrMorgan: I found a|strange creature. At|first i thought it was|deceased. But it sprang|up and attacked my|associate! . . ."
W $E089,2 -> "DrMorgan: To make|matters worse the|creatures are|evolving rapidly. My|associate claims he|saw one over 7 feet!"
W $E08B,2 -> "It truly baffles me|considering our cargo|why they insist on|equipping the ship with|ONLY Ion-Phasers.|They are useless!!!"
W $E08D,2 -> "Capt Millin: We are|losing crew fast. I sent|Willis to re-animate|the clones. Right now|they are the only|chance we have . . ."
W $E08F,2 -> "Capt Millin: I am very|anxious to see the|clones in action. I|hear that they are the|most advanced clone|soldiers ever created."
W $E091,2 -> "Capt Millin: We are|transporting a cargo|of genetically|modified clones to a|IH-2 Military Facility|for field testing . . ."
W $E093,2 -> "Capt Millin: I have|just recieved word|that the facility on|earth was destroyed.|We now carry the only|clone prototypes."
W $E095,2 -> "Willis: We are in BIG|trouble. Only 1 clone|survived the meteorite|shower. And the system|says Re-animation will|take over 6 hours!!!"
W $E097,2 -> "This is ludicrous!|65 credits for a proton|bar? How are we|meant to snack while|we work? The agency|is getting on my nerves."
W $E09B,2 -> "         No Data Cartridge| Selected"
W $E09D,2 -> "MaxCoderz Presents"
W $E09F,2 -> "a tr1p1ea game"
W $E0A1,2 -> "Items Found (/24):|            Enemies Killed:|               PlayerDeaths:||Awards:"
W $E0A3,2 -> "OverWrite Current Game?|Alpha = Yes :: Clear = No"
W $E0A5,2 -> "- Controls -"
W $E0A7,2 -> "2nd = Look / Shoot|Alpha = Inventory|XT0n = Look / Shoot Mode|Mode = Close all Pop-Ups|Clear = Quit to TitleScreen"
W $E0A9,2 -> "Earn 3 Good Awards for|an Extended Ending!"
W $E0AB,2 -> "Sir Miss-A-Lot"
W $E0AD,2 -> "Sherlock Holmes"
W $E0AF,2 -> "Running Scared"
W $E0B1,2 -> "Terminator"
W $E0B3,2 -> "Over & Over Again"
W $E0B5,2 -> "Survivor"
W $E0B7,2 -> "        Ion Phaser"
W $E0B9,2 -> ??
W $E0BB,2 -> " - INVENTORY - "
W $E0BD,2 -> "The Desolate has claimed|your life too . . ."
W $E0BF,2 -> "OMG! This Person Is DEAD!"
W $E0C1,2 -> "What Happened Here!?!"
W $E0C3,2 -> "     Another Dead Person"
W $E0C5,2 -> " Search Reveals Nothing"
W $E0C7,2 -> "     This Person is Dead . . ."
W $E0C9,2 -> "They Seem To Be Holding"
W $E0CB,2 -> "Something"
W $E0CD,2 -> "     Hey Whats This  .  .  . ?"
W $E0CF,2 -> "You Picked Up A"
W $E0D1,2 -> "You Already Have The"
W $E0D3,2 -> "You dont have a|          Weapon to equip!"
W $E0D5,2 -> "It is not wise to proceed|       without a weapon."
W $E0D7,2 -> "You cant enter that sector|   Life-Support is offline."
W $E0D9,2 -> "You cant enter until the|AirLock is re-pressurised"
W $E0DB,2 -> "       ---- N o  I t e m ----"
W $E0DD,2 -> ": Door Locked :"
W $E0DF,2 -> " INVALID CODE"
W $E0E1,2 -> "       Accepted!      "
W $E0E3,2 -> "                    You Need A|Data Cartridge Reader"
W $E0E5,2 -> "    Data Cartridge Reader"
W $E0E7,2 -> "             Data Cartridge 1"
W $E0E9,2 -> "             Data Cartridge 2"
W $E0EB,2 -> "             Data Cartridge 3"
W $E0ED,2 -> "             Data Cartridge 4"
W $E0EF,2 -> "             Data Cartridge 5"
W $E0F1,2 -> "             Data Cartridge 6"
W $E0F3,2 -> "             Data Cartridge 7"
W $E0F5,2 -> "             Data Cartridge 8"
W $E0F7,2 -> "             Data Cartridge 9"
W $E0F9,2 -> "          Data Cartridge 10"
W $E0FB,2 -> "          Data Cartridge 11"
W $E0FD,2 -> "          Data Cartridge 12"
W $E0FF,2 -> "          Data Cartridge 13"
W $E101,2 -> "          Data Cartridge 14"
W $E103,2 -> "          Data Cartridge 15"
W $E105,2 -> "          Data Cartridge 16"
W $E107,2 -> "                    Power Drill"
W $E109,2 -> "    Life Support Data Disk"
W $E10B,2 -> "                 Air-Lock Tool"
W $E10D,2 -> "         Box of Power Cells"
W $E10F,2 -> "                   Pile of Parts"
W $E111,2 -> "                    Duck Idol ;)"
W $E113,2 -> "                   Rubik's Cube"
W $E115,2 -> "In the Distant Future . . ."
W $E117,2 -> "'The Desolate' Space Cruiser|leaves orbit. Its mission is|secret, its cargo classified.|6014 Cycles into the journey|the ship encounters a savage|meteorite shower.||Contact with Desolate is lost."
W $E119,2 -> "The ship sustains heavy|damage. Onboard a cryo-|genic incubation cell|finishes re-animation. Its|occupant steps out of the|chamber not knowing who he|is, or what he is going to do.||But at least he is alive."
W $E11B,2 -> "The onboard guidance|system picks up a mining|facility close by. The course|is set and you sit back, finally|free of 'The Desolate' & its|murderous hord of Aliens.|You were a clone, an|experiment. Now, 'you' are|the sole survivor ."
W $E11D,2 -> "System Alert triggered: |'Foreign Objects Detected|OnBoard'. The Aliens have|attached to the hull!|'Main Drive System Offline'|The ship was on a crash|course for the Mining Facility||It wasnt over yet  .  .  ."
W $E11F,2 -> "The End"
W $E121,2 -> "            Level 1|    Access Code|         Required"
W $E123,2 -> "            Level 2|    Access Code|         Required"
W $E125,2 -> "            Level 3|    Access Code|         Required"
W $E127,2 -> "            Level 4|    Access Code|         Required"
W $E129,2 -> "You dont seem to be able|     to use this item here"
W $E12B,2 -> "You dont have any time|    to play with this now"
W $E12D,2 -> "       It doesnt look like you|  can do anything else here"
W $E12F,2 -> "This Generator is damaged| All of the panels are loose"
W $E131,2 -> "     This Workstation doesnt|seem to have any power...?"
W $E133,2 -> "    The Workstation has now|   successfully booted up    "
W $E135,2 -> " The Workstation Ejected A|                Data Cartridge 2"
W $E137,2 -> " You use the Power Drill|to Repair the Generator"
W $E139,2 -> "      Life-Support System|has been fully restored"
W $E13B,2 -> "The Evacuation Deck has|   been re-pressurised"
W $E13D,2 -> "You Insert a Power Cell.|Guidance System Online"
W $E13F,2 -> "    The Life Support System|       needs Re-Configuring"
W $E141,2 -> "              AirLock Control &| Re-Pressurisation Station"
W $E143,2 -> "   This MainFrame is missing|                        a Power Cell"
W $E145,2 -> "   This Pod cant naviagate.|Guidance System is offline"
b $E147 Tileset 1, ~158 tiles 8x8x4 - main one
B $E147,2528,16
b $EB27
B $EB27,18,16 Encoded screen: Small message popup, in Tileset #2
b $EB39 Tileset 2, 127 tiles 8x8x4 - menu, popups, title
B $EB39,2032,16
b $F329 Encoded Inventory/Info popup, in Tileset #2
B $F329,38,16
b $F34F Tiles inventory items, 14 tiles 8x8 4-color
B $F34F,224,16
b $F42F
B $F42F,57,16 Encoded screen: Data cartridge reader screen, in Tileset #2
B $F468,77,16 Encoded screen: Door access panel popup, in Tileset #2
B $F4B5,96,16 Main menu screen, 96 tiles in Tileset #2
B $F515,96,16 Main menu screen moving background, 96 tiles

