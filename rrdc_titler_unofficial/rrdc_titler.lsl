// [SGD] Custom RRDC Titler v1.01 - Copyright 2019 Alex Pascal (Alex Carpenter) @ Second Life.
// -------------------------------------------------------------------------------------------
// This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. 
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
// ===========================================================================================

// General Settings and Defaults. 
// -------------------------------------------------------------------------------------------
integer g_channel       = 2; // Channel to recieve commands on.
integer g_chatChan      = 4; // Channel to recieve chat on.
integer g_status        = 0; // 0 = IC, 1 = OOC, 2 = AFK.
integer g_suffix        = 0; // Trailing newlines to position text, if any.

// Toggle Switch Bitfield.
// -------------------------------------------------------------------------------------------
// OR Mask       AND Mask      Variable
// -------------------------------------------------------------------------------------------
// 0x00000001    0xFFFFFFFE    Available for RP.
// 0x00000002    0xFFFFFFFD    Show Titler Hovertext.
// 0x00000004    0xFFFFFFFB    Use Whispers for Chat.
// 0x00000008    0xFFFFFFF7    Force Showing Blanks.
// 0x00000010    0xFFFFFFEF    RLV Auto-Redirect Chat.
// 0x00000020    0xFFFFFFDF    <unassigned>
// 0x00000040    0xFFFFFFBF    <unassigned>
// 0x00000080    0xFFFFFF7F    Flag to reshow menu after text field. DO NOT SET BY DEFAULT.
// -------------------------------------------------------------------------------------------
integer g_settings      = 0x3; // Available, Visible.

// ============================================================================================
// CAUTION: Editing below this line may cause unexpected script behavior. Enter at own risk.
// ============================================================================================

// Strided list of character settings. Stride: 11.
// -------------------------------------------------------------------------------------------
// 0     1       2       3        4      5      6      7      8      9         10
// Name, Prefix, Gender, Species, Misc1, Misc2, Misc3, Misc4, Depth, Intimacy, Role.
// -------------------------------------------------------------------------------------------
// Roles: 0 = General Inmate, 1 = Violent Inmate, 2 = Deviant Inmate, 3 = Guard, 4 = Biotech,
//        5 = Engineer,       6 = General Staff
// -------------------------------------------------------------------------------------------
list    g_characters    = [];
integer g_handle;                   // Stores listen handle for cmd channel.
integer g_chatHandle;               // Stores listen handle for chat channel.
string  g_curMenu       = "main";   // Stores the current menu level.
integer g_textField     = -1;       // Number of text field we're writing to. -1 is null.
integer g_curCharacter  = 0;        // Stride offset for the currently selected character.
// ============================================================================================

// cmdMatch - Returns TRUE if 'cmd' is the prefix of 'str'.
// -------------------------------------------------------------------------------------------
integer cmdMatch(string cmd, string str)
{
    return (llSubStringIndex(llToLower(str), llToLower(cmd)) == 0);
}

// createSuffix - Generates a string of newlines to adjust the height of the hovertext.
// -------------------------------------------------------------------------------------------
string createSuffix()
{
    string suffix = "\n";

    integer i;
    for (i = 0; i < g_suffix; i++)
    {
        suffix += " \n";
    }

    return suffix;
}

// getRoleColor - Given a role enum (0-6), returns the corresponding LSL color vector.
// -------------------------------------------------------------------------------------------
vector getRoleColor(integer role)
{
    if (role == 0) // General Inmate.
    {
        return <1.000, 0.502, 0.000>;
    }
    else if (role == 1) // Violent Inmate.
    {
        return <1.000, 0.118, 0.118>;
    }
    else if (role == 2) // Deviant Inmate.
    {
        return <1.000, 0.000, 0.802>;
    }
    else if (role == 3) // Guard.
    {
        return <0.502, 0.502, 1.000>;
    }
    else if (role == 4) // Biotech.
    {
        return <0.000, 1.000, 0.502>;
    }
    else if (role == 5) // Engineer.
    {
        return <0.831, 0.686, 0.216>;
    }
    else // General Staff.
    {
        return <0.749, 0.749, 0.749>;
    }
}

// updateText - Updates or clears the titler's hovertext.
// -------------------------------------------------------------------------------------------
updateText()
{
    if (!(g_settings & 0x00000002)) // Clear text if hidden.
    {
        llSetText("", ZERO_VECTOR, 0);
        return;
    }

    // Display starts with the character's name.
    string text = llList2String(g_characters, (g_curCharacter * 11));

    if (g_status == 0) // IC display.
    {
        integer i;
        integer z = FALSE; // Tracks whether the depth field is set.
        for (i = 1; i < 10; i++)
        {
            string data = llList2String(g_characters, ((g_curCharacter * 11) + i));

            if (i != 1 && i != 8 && data == "" && (g_settings & 0x00000008)) // Force blanks.
            {
                data = " ";
            }

            if (i == 1) // Prefix is prepended.
            {
                text = (data + " " + text);
            }
            else if (i == 9) // Intimacy and Depth are on same line.
            {
                if (!z) // Depth field was not set, add newline.
                {
                    text = (text + "\n" + data);
                }
                else
                {
                    text = (text + " " + data);
                }
            }
            else // Everything else is on a new line.
            {
                text += "\n" + data;

                if (i == 8) // Track whether depth field is set.
                {
                    z = TRUE;
                }
            }
        }
    }
    else if (g_status == 1) // OOC display.
    {
        if ((g_settings & 0x00000001))
        {
            text += "\nAvailable for RP";
        }

        text += "\n[OOC]";
    }
    else // AFK display.
    {
        text += "\n[AFK]";
    }

    llSetText((text + createSuffix()), // Set the text.
        getRoleColor((integer)llList2String(g_characters, ((g_curCharacter * 11) + 10))), 
    1.0);
}

// charSelect - Builds character selection menu.
// -------------------------------------------------------------------------------------------
list charSelect()
{
    list l = [];
    integer i;
    for (i = 0; i < llGetListLength(g_characters); i+=11)
    {
        l = [llGetSubString(llList2String(g_characters, i), 0, 24)] + l;
    }
    return l;
}

// showMenu - Given a valid menu name, displays the menu to the user.
//            Note: use special char " " at end of leaf options and empty buttons.
// -------------------------------------------------------------------------------------------
showMenu(string menu) // Display menus.
{
    g_curMenu = menu; // Save this menu so we can reopen it.

    string text = "\n\nChoose an option:"; // Initialize menu params.
    list buttons;

    if (menu == "main") // Main menu.
    {
        text = "Main Menu" + text;
        buttons = ["Options", "Help ", "Close", "Role", "Details", "Characters",
                   "Depth", "Intimacy", "Availability", "Status", "Prefix ", "Name "];
    }
    else if (menu == "status") // Status Submenu.
    {
        text = "Status Menu" + text;
        buttons = [" ", " ", "↺ Main", "IC ", "OOC ", "AFK "];
    }
    else if (menu == "details") // Details Submenu.
    {
        text = "Details Menu" + text;
        buttons = [" ", " ", "↺ Main", "Misc2 ", "Misc3 ", "Misc4 ", "Sex ", "Species ", "Misc1 "];
    }
    else if (menu == "depth") // Depth Submenu.
    {
        text = "RP Depth Preference Menu" + text;
        buttons = [" ", " ", "↺ Main", "Casual ", "Story-driven ", "Either "];
    }
    else if (menu == "availability") // Availability submenu.
    {
        text = "RP Availability Menu" + text;
        buttons = ["Available ", "Busy ", "↺ Main"];
    }
    else if (menu == "intimacy") // Intimacy submenu.
    {
        text = "Intimacy Preference Menu" + text;
        buttons = ["Nonsexual ", "NoPreference ", "↺ Main", "Dominant ", "Versatile ", "Submissive "];
    }
    else if (menu == "role") // Role submenu.
    {
        text = "RP Role Selection" + text;
        buttons = ["Inmate", "Staff", "↺ Main"];
    }
    else if (menu == "inmate") // Inmate L2 submenu.
    {
        text = "Inmate Type Selection" + text;
        buttons = [" ", " ", "↺ Role", "GenPop ", "Violent ", "Deviant "];
    }
    else if (menu == "staff") // Staff L2 submenu.
    {
        text = "Staff Type Selection" + text;
        buttons = ["GenStaff ", " ", "↺ Role", "Guard ", "Biotech ", "Engineer "];
    }
    else if (menu == "characters") // Characters Submenu.
    {
        text = "Character Management Menu" + text;
        buttons = [" ", " ", "↺ Main", "New ", "Select ", "Erase "];
    }
    else if (menu == "options") // Options submenu.
    {
        text = "Options and Settings Menu" + text;
        buttons = [" ", " ", "↺ Main", "ChatVolume", "ChatRedirect", "Channels",
                   "Visibility", "BlankLines", "Height"];
    }
    else if (menu == "visibility") // Visibility L2 Submenu.
    {
        text = "Titler Text Visibility" + text + "\n\nCurrent setting: ";

        if ((g_settings & 0x00000002))
        {
            text += "Visible";
        }
        else
        {
            text += "Hidden";
        }

        buttons = ["Show ", "Hide ", "↺ Options"];
    }
    else if (menu == "blanklines") // Blank Lines L2 Submenu.
    {
        text = "Force Blank Lines" + text + "\n\nCurrent setting: ";

        if ((g_settings & 0x00000008))
        {
            text += "Force Blanks";
        }
        else
        {
            text += "Remove Blanks";
        }

        buttons = ["Blanks ", "NoBlanks ", "↺ Options"];
    }
    else if (menu == "chatvolume") // Chat volume L2 Submenu.
    {
        text = "Titler Chat Volume" + text + "\n\nCurrent setting: ";

        if ((g_settings & 0x00000004))
        {
            text += "Whisper";
        }
        else
        {
            text += "Speak";
        }

        buttons = ["Speak ", "Whisper ", "↺ Options"];
    }
    else if (menu == "chatredirect") // Chat redirect L2 Submenu.
    {
        text = "Chat Auto-Redirect (RLV)" + text + "\n\nCurrent setting: ";

        if ((g_settings & 0x00000010))
        {
            text += "Redirect On";
        }
        else
        {
            text += "Redirect Off";
        }

        buttons = ["RedirectOn ", "RedirectOff ", "↺ Options"];
    }
    else if (menu == "height") // Height L2 Submenu.
    {
        text = "Titler Text Height" + text + "\n\nCurrent setting: " + 
               (string)g_suffix + " lines";
        buttons = ["HeightUp ", "HeightDn ", "↺ Options"];
    }
    else if (menu == "channels") // Channels L2 Submenu.
    {
        text = "Command and RP Channels" + text + "\n\nCommand channel: " +
               (string)g_channel + "\nRP Chat Channel: " + (string)g_chatChan;
        buttons += ["CmdChan ", "RPChan ", "↺ Options"];
    }

    llDialog(llGetOwner(), text, buttons, g_channel); // Display the menu.
}

default
{
    // Initialize the script.
    // ---------------------------------------------------------------------------------------
    state_entry()
    {
        // We need a first/default character. Create one.
        g_characters = ["Unnamed Character", "", "Sex/Gender", "Species", "Crimes/Specialization",
                        "Misc2", "Misc3", "Misc4", "", "", "0"];

        // Initialize listen handlers.
        g_handle = llListen(g_channel, "", "", "");
        g_chatHandle = llListen(g_chatChan, "", llGetOwner(), "");

        updateText(); // Initialize hovertext.
    }

    // Toggle RLV chat redirect on attach/detach if applicable.
    // ---------------------------------------------------------------------------------------
    attach(key id)
    {
        if (id != NULL_KEY) // Item was attached.
        {
            llSetAlpha(0.0, ALL_SIDES); // Make the object transparent.
            if ((g_settings & 0x00000010)) // Start redirecting on attach if enabled.
            {
                llOwnerSay("@redirchat:" + (string)g_chatChan + "=add");
                llOwnerSay("@rediremote:" + (string)g_chatChan + "=add");
            }
        }
        else // Item was detached.
        {
            llSetAlpha(1.0, ALL_SIDES); // Make the object opaque to see more easily when rezzed.
            if ((g_settings & 0x00000010)) // Stop redirecting on detach, if redirects are enabled.
            {
                llOwnerSay("@redirchat:" + (string)g_chatChan + "=rem");
                llOwnerSay("@rediremote:" + (string)g_chatChan + "=rem");
            }
        }
    }

    // Allow owner to access menu on touch.
    // ---------------------------------------------------------------------------------------
    touch_start(integer num)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            showMenu("main");
        }
    }

    // Process chat and menu commands.
    // ---------------------------------------------------------------------------------------
    listen(integer chan, string name, key id, string mesg)
    {
        if (llGetOwnerKey(id) != llGetOwner())
        {
            return; // Ignore commands not from owner or their objects.
        }

        mesg = llStringTrim(mesg, STRING_TRIM); // Trim before passing on.

        if (chan == g_channel) // Process as a command or menu option.
        {
            // Remove all standard whitespace characters.
            mesg = llDumpList2String(llParseString2List(mesg, ["\n", "\t"], []), "");
            
            // Command parser loop. Will process command text from left to right until
            //  the context of the parsed command prevents further processing.
            while (llStringLength(mesg) > 0 || g_textField != -1)
            {
                mesg += " "; // Trailing space required by parser.

                // ----------------------------------------------
                // Text fields setter.
                // ----------------------------------------------
                if (g_textField != -1)
                {
                    // Text argument t runs to the end of the string or the first semicolon found.
                    //  Remaining mesg sent on for further parsing.
                    integer endArg = llSubStringIndex(mesg, ";");
                    string t = llStringTrim(llGetSubString(mesg, 0, (endArg - (endArg != -1 && endArg != 0))), STRING_TRIM);
                    mesg = llGetSubString(mesg, endArg, -1);

                    if (t == ";") // Remove the semi-colon that happens if the field is empty.
                    {
                        t = "";
                    }

                    if ((g_textField == 0 || g_textField == -4) && t == "") // No blank names.
                    {
                        llOwnerSay("Character name cannot be blank.");
                    }
                    else if (g_textField >= 0) // Text fields.
                    {
                        integer idx = (g_curCharacter * 11) + g_textField; // Set the field.
                        g_characters = llListReplaceList(g_characters, [t], idx, idx);
                        updateText(); // Update the hovertext to reflect the change.
                    }
                    else if (g_textField == -2) // Command channel field.
                    {
                        integer chan = (integer)t;
                        if (chan <= 0)
                        {
                            llOwnerSay("Command channel must be a number greater than zero.");
                        }
                        else if (chan == g_chatChan)
                        {
                            llOwnerSay("Specified channel is already in use as the RP chat channel.");
                        }
                        else
                        {
                            llListenRemove(g_handle); // Remove old listener and add new one.
                            g_handle = llListen(chan, "", "", "");
                            g_channel = chan;
                        }
                    }
                    else if (g_textField == -3) // RP channel field.
                    {
                        integer chan = (integer)t;
                        if (chan <= 0)
                        {
                            llOwnerSay("RP chat channel must be a number greater than zero.");
                        }
                        else if (chan == g_channel)
                        {
                            llOwnerSay("Specified channel is already in use as the Command channel.");
                        }
                        else
                        {
                            llListenRemove(g_chatHandle); // Remove old listener and add new one.
                            g_chatHandle = llListen(chan, "", llGetOwner(), "");

                            if ((g_settings & 0x00000010)) // Change RLV redirects to match.
                            {
                                llOwnerSay("@redirchat:" + (string)g_chatChan + "=rem");
                                llOwnerSay("@rediremote:" + (string)g_chatChan + "=rem");
                                llOwnerSay("@redirchat:" + (string)chan + "=add");
                                llOwnerSay("@rediremote:" + (string)chan + "=add");
                            }
                            g_chatChan = chan;
                        }
                    }
                    else if (g_textField == -4) // New character field.
                    {
                        if (llListFindList(g_characters, [t]) != -1)
                        {
                            llOwnerSay("That character already exists!");
                        }
                        else
                        {
                            g_curCharacter = llGetListLength(g_characters) / 11; // Set new to current.
                            g_characters += [t, "", "Sex/Gender", "Species", "Crimes/Specialization",
                                            "Misc2", "Misc3", "Misc4", "", "", "0"]; // Add new data.
                            updateText(); // Update the text to point to the new character.
                        }
                    }
                    else if (g_textField == -5) // Select character field.
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(g_characters); i+=11) // Find character.
                        {
                            if (cmdMatch(t, llList2String(g_characters, i)))
                            {
                                g_curCharacter = i / 11; // Select.
                                updateText();
                                jump charSearchDone;
                            }
                        }
                        llOwnerSay("Could not find a character with a name starting with: " + t);
                    }
                    else // Erase character field. (-6)
                    {
                        integer i;
                        for (i = 0; i < llGetListLength(g_characters); i+=11) // Find character.
                        {
                            if (cmdMatch(t, llList2String(g_characters, i)))
                            {
                                g_characters = llListReplaceList(g_characters, [], i, i+10); // Remove.

                                if (llGetListLength(g_characters) < 11) // If that was the last one, create new default.
                                {
                                    g_characters = ["Unnamed Character", "", "Sex/Gender", "Species", "Crimes/Specialization",
                                                    "Misc2", "Misc3", "Misc4", "", "", "0"];
                                }

                                if (g_curCharacter == (i / 11)) // If we deleted current, switch to previous in list.
                                {
                                    g_curCharacter--;
                                    if (g_curCharacter < 0)
                                    {
                                        g_curCharacter = 0;
                                    }
                                    updateText();
                                }
                                jump charSearchDone;
                            }
                        }
                        llOwnerSay("Could not find a character with a name starting with: " + t);
                    }
                    @charSearchDone; // Character searches jump here.

                    g_textField = -1; // Reset the textField flag.

                    if ((g_settings & 0x00000080)) // If we got here from a menu, return to that menu now.
                    {
                        showMenu(g_curMenu);
                        g_settings = (g_settings & 0xFFFFFF7F);
                        return;
                    }
                }
                // ----------------------------------------------
                // Misc/Utility commands.
                // ----------------------------------------------
                else if (cmdMatch(";", mesg)) // Consume extra semi-colons.
                {
                    mesg = llGetSubString(mesg, 1, -1);
                }
                else if (cmdMatch("help", mesg)) // Help menu/command.
                {
                    mesg = llGetSubString(mesg, 4, -1);

                    if (llGetInventoryNumber(INVENTORY_NOTECARD)) // Notecard is present.
                    {
                        llGiveInventory(llGetOwner(), // Offer notecard.
                            llGetInventoryName(INVENTORY_NOTECARD, 0)
                        );
                    }
                    else
                    {
                        llOwnerSay("Hmm.. The help notecard appears to be missing!");
                    }
                }
                else if (cmdMatch(" ", mesg)) // Access the last menu used.
                {
                    showMenu(g_curMenu);
                    return;
                }
                else if (cmdMatch("close", mesg))
                {
                    return; // Do nothing for close command.
                }
                else if (cmdMatch("menu", mesg) || cmdMatch("↺ Main", mesg)) // Main menu.
                {
                    showMenu("main");
                    return;
                }
                // ----------------------------------------------
                // Status commands.
                // ----------------------------------------------
                else if (cmdMatch("status", mesg)) // Status command/menu.
                {
                    mesg = llGetSubString(mesg, 6, -1); // Consume command text.
                    if (mesg == " ") // Nothing more to parse, show menu.
                    {
                        showMenu("status");
                        return;
                    }
                }
                else if (cmdMatch("ic", mesg)) // IC option/command.
                {
                    mesg = llGetSubString(mesg, 2, -1);
                    g_status = 0;
                }
                else if (cmdMatch("ooc", mesg)) // OOC option/command.
                {
                    mesg = llGetSubString(mesg, 3, -1);
                    g_status = 1;
                }
                else if (cmdMatch("afk", mesg)) // AFK option/command.
                {
                    mesg = llGetSubString(mesg, 3, -1);
                    g_status = 2;
                }
                // ----------------------------------------------
                // RP Role commands.
                // ----------------------------------------------
                else if (cmdMatch("role", mesg) || cmdMatch("↺ Role", mesg)) // Role menu.
                {
                    if (cmdMatch("↺ Role", mesg) || llGetSubString(mesg, 4, -1) == " ")
                    {
                        showMenu("role");
                        return;
                    }

                    mesg = llGetSubString(mesg, 4, -1);
                }
                else if (cmdMatch("inmate", mesg)) // Inmate sub-menu.
                {
                    showMenu("inmate");
                    return;
                }
                else if (cmdMatch("staff", mesg)) // Staff sub-menu.
                {
                    showMenu("staff");
                    return;
                }
                else if (cmdMatch("genpop", mesg)) // General inmate population.
                {
                    mesg = llGetSubString(mesg, 6, -1);
                    integer idx = (g_curCharacter * 11) + 10;
                    g_characters = llListReplaceList(g_characters, ["0"], idx, idx);
                }
                else if (cmdMatch("violent", mesg)) // Violent inmate.
                {
                    mesg = llGetSubString(mesg, 7, -1);
                    integer idx = (g_curCharacter * 11) + 10;
                    g_characters = llListReplaceList(g_characters, ["1"], idx, idx);
                }
                else if (cmdMatch("deviant", mesg)) // Deviant inmate.
                {
                    mesg = llGetSubString(mesg, 7, -1);
                    integer idx = (g_curCharacter * 11) + 10;
                    g_characters = llListReplaceList(g_characters, ["2"], idx, idx);
                }
                else if (cmdMatch("guard", mesg)) // Guard.
                {
                    mesg = llGetSubString(mesg, 5, -1);
                    integer idx = (g_curCharacter * 11) + 10;
                    g_characters = llListReplaceList(g_characters, ["3"], idx, idx);
                }
                else if (cmdMatch("biotech", mesg)) // Biotech.
                {
                    mesg = llGetSubString(mesg, 7, -1);
                    integer idx = (g_curCharacter * 11) + 10;
                    g_characters = llListReplaceList(g_characters, ["4"], idx, idx);
                }
                else if (cmdMatch("engineer", mesg)) // Engineer.
                {
                    mesg = llGetSubString(mesg, 8, -1);
                    integer idx = (g_curCharacter * 11) + 10;
                    g_characters = llListReplaceList(g_characters, ["5"], idx, idx);
                }
                else if (cmdMatch("genstaff", mesg)) // General Staff.
                {
                    mesg = llGetSubString(mesg, 8, -1);
                    integer idx = (g_curCharacter * 11) + 10;
                    g_characters = llListReplaceList(g_characters, ["6"], idx, idx);
                }
                // ----------------------------------------------
                // RP Depth Preference commands.
                // ----------------------------------------------
                else if (cmdMatch("depth", mesg)) // Status command/menu.
                {
                    mesg = llGetSubString(mesg, 5, -1);
                    if (mesg == " ")
                    {
                        showMenu("depth");
                        return;
                    }
                }
                else if (cmdMatch("casual", mesg)) // Casual RP.
                {
                    mesg = llGetSubString(mesg, 6, -1);
                    integer idx = (g_curCharacter * 11) + 8;
                    g_characters = llListReplaceList(g_characters, ["Casual"], idx, idx);
                }
                else if (cmdMatch("story", mesg)) // Story-driven RP.
                {
                    if (cmdMatch("story-driven", mesg)) // Consume full/abbrev command.
                    {
                        mesg = llGetSubString(mesg, 12, -1);
                    }
                    else
                    {
                        mesg = llGetSubString(mesg, 5, -1);
                    }

                    integer idx = (g_curCharacter * 11) + 8;
                    g_characters = llListReplaceList(g_characters, ["Story-driven"], idx, idx);
                }
                else if (cmdMatch("either", mesg)) // Any kind of RP.
                {
                    mesg = llGetSubString(mesg, 6, -1);
                    integer idx = (g_curCharacter * 11) + 8;
                    g_characters = llListReplaceList(g_characters, [""], idx, idx);
                }
                // ----------------------------------------------
                // Intimacy Preference commands.
                // ----------------------------------------------
                else if (cmdMatch("intimacy", mesg)) // Status command/menu.
                {
                    mesg = llGetSubString(mesg, 8, -1);
                    if (mesg == " ")
                    {
                        showMenu("intimacy");
                        return;
                    }
                }
                else if (cmdMatch("dom", mesg)) // Dominant.
                {
                    if (cmdMatch("dominant", mesg))
                    {
                        mesg = llGetSubString(mesg, 8, -1);
                    }
                    else
                    {
                        mesg = llGetSubString(mesg, 3, -1);
                    }

                    integer idx = (g_curCharacter * 11) + 9;
                    g_characters = llListReplaceList(g_characters, ["Dominant"], idx, idx);
                }
                else if (cmdMatch("versatile", mesg) || cmdMatch("switch", mesg)) // Versatile.
                {
                    if (cmdMatch("versatile", mesg))
                    {
                        mesg = llGetSubString(mesg, 9, -1);
                    }
                    else
                    {
                        mesg = llGetSubString(mesg, 6, -1);
                    }

                    integer idx = (g_curCharacter * 11) + 9;
                    g_characters = llListReplaceList(g_characters, ["Switch"], idx, idx);
                }
                else if (cmdMatch("sub", mesg)) // Submissive.
                {
                    if (cmdMatch("submissive", mesg))
                    {
                        mesg = llGetSubString(mesg, 10, -1);
                    }
                    else
                    {
                        mesg = llGetSubString(mesg, 3, -1);
                    }

                    integer idx = (g_curCharacter * 11) + 9;
                    g_characters = llListReplaceList(g_characters, ["Submissive"], idx, idx);
                }
                else if (cmdMatch("nonsex", mesg)) // Nonsexual.
                {
                    if (cmdMatch("nonsexual", mesg))
                    {
                        mesg = llGetSubString(mesg, 9, -1);
                    }
                    else
                    {
                        mesg = llGetSubString(mesg, 6, -1);
                    }

                    integer idx = (g_curCharacter * 11) + 9;
                    g_characters = llListReplaceList(g_characters, ["Non-Sexual"], idx, idx);
                }
                else if (cmdMatch("nopref", mesg)) // Dominant.
                {
                    if (cmdMatch("nopreference", mesg))
                    {
                        mesg = llGetSubString(mesg, 12, -1);
                    }
                    else
                    {
                        mesg = llGetSubString(mesg, 6, -1);
                    }

                    integer idx = (g_curCharacter * 11) + 9;
                    g_characters = llListReplaceList(g_characters, [""], idx, idx);
                }
                // ----------------------------------------------
                // Availability commands.
                // ----------------------------------------------
                else if (cmdMatch("availability", mesg)) // Status command/menu.
                {
                    showMenu("availability");
                    return;
                }
                else if (cmdMatch("available", mesg)) // Available command.
                {
                    mesg = llGetSubString(mesg, 9, -1);
                    g_settings = (g_settings | 0x00000001);
                }
                else if (cmdMatch("busy", mesg)) // Unavailable/busy command.
                {
                    mesg = llGetSubString(mesg, 4, -1);
                    g_settings = (g_settings & 0xFFFFFFFE);
                }
                // ----------------------------------------------
                // Settings commands.
                // ----------------------------------------------
                else if (cmdMatch("show", mesg)) // Show command.
                {
                    mesg = llGetSubString(mesg, 4, -1);
                    g_settings = (g_settings | 0x00000002);
                }
                else if (cmdMatch("hide", mesg)) // Hide command.
                {
                    mesg = llGetSubString(mesg, 4, -1);
                    g_settings = (g_settings & 0xFFFFFFFD);
                }
                else if (cmdMatch("blanks", mesg)) // Blanks command.
                {
                    mesg = llGetSubString(mesg, 6, -1);
                    g_settings = (g_settings | 0x00000008);
                }
                else if (cmdMatch("noblanks", mesg)) // Noblanks command.
                {
                    mesg = llGetSubString(mesg, 8, -1);
                    g_settings = (g_settings & 0xFFFFFFF7);
                }
                else if (cmdMatch("speak", mesg)) // Speak command.
                {
                    mesg = llGetSubString(mesg, 5, -1);
                    g_settings = (g_settings & 0xFFFFFFFB);
                }
                else if (cmdMatch("whisper", mesg)) // Whisper command.
                {
                    mesg = llGetSubString(mesg, 7, -1);
                    g_settings = (g_settings | 0x00000004);
                }
                else if (cmdMatch("redirecton", mesg)) // Redirect on command.
                {
                    mesg = llGetSubString(mesg, 10, -1);

                    if (!(g_settings & 0x00000010))
                    {
                        llOwnerSay("@redirchat:" + (string)g_chatChan + "=add");
                        llOwnerSay("@rediremote:" + (string)g_chatChan + "=add");
                    }
                    g_settings = (g_settings | 0x00000010);
                }
                else if (cmdMatch("redirectoff", mesg)) // Redirect off command.
                {
                    mesg = llGetSubString(mesg, 11, -1);

                    if ((g_settings & 0x00000010))
                    {
                        llOwnerSay("@redirchat:" + (string)g_chatChan + "=rem");
                        llOwnerSay("@rediremote:" + (string)g_chatChan + "=rem");
                    }
                    g_settings = (g_settings & 0xFFFFFFEF);
                }
                else if (cmdMatch("heightup", mesg)) // Height up command.
                {
                    mesg = llGetSubString(mesg, 8, -1);
                    g_suffix++;
                    if (g_suffix > 8)
                    {
                        g_suffix = 8;
                    }
                }
                else if (cmdMatch("heightdn", mesg)) // Height down command.
                {
                    mesg = llGetSubString(mesg, 8, -1);
                    g_suffix--;
                    if (g_suffix < 0)
                    {
                        g_suffix = 0;
                    }
                }
                else if (cmdMatch("cmdchan", mesg)) // Cmd Chan command.
                {
                    mesg = llGetSubString(mesg, 7, -1);
                    g_textField = -2; // Selects command channel.
                    if (mesg == " " || mesg == "  ") // No parameter text. Offer textbox.
                    {
                        llTextBox(llGetOwner(), 
                            "Type in the blank to set a new command channel.\n\nCurrent: \"" + 
                            (string)g_channel + "\"", g_channel);
                        
                        if (mesg == "  ") // If we had a menu flag, set reshow bit.
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else if (cmdMatch("rpchan", mesg)) // RP Chan command.
                {
                    mesg = llGetSubString(mesg, 6, -1);
                    g_textField = -3; // Selects RP channel.
                    if (mesg == " " || mesg == "  ") // No parameter text. Offer textbox.
                    {
                        llTextBox(llGetOwner(), 
                            "Type in the blank to set a new command channel.\n\nCurrent: \"" + 
                            (string)g_chatChan + "\"", g_channel);
                        
                        if (mesg == "  ") // If we had a menu flag, set reshow bit.
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                // ----------------------------------------------
                // Settings menu commands.
                // ----------------------------------------------
                else if (cmdMatch("options", mesg) || cmdMatch("↺ Options", mesg)) // Options menu.
                {
                    showMenu("options");
                    return;
                }
                else if (cmdMatch("visibility", mesg)) // Visibility menu.
                {
                    showMenu("visibility");
                    return;
                }
                else if (cmdMatch("blanklines", mesg)) // Blanklines menu.
                {
                    showMenu("blanklines");
                    return;
                }
                else if (cmdMatch("chatvolume", mesg)) // Chat volume menu.
                {
                    showMenu("chatvolume");
                    return;
                }
                else if (cmdMatch("chatredirect", mesg)) // Chat redirect menu.
                {
                    showMenu("chatredirect");
                    return;
                }
                else if (cmdMatch("height", mesg)) // Height command/menu.
                {
                    showMenu("height");
                    return;
                }
                else if (cmdMatch("channels", mesg)) //Channels command/menu.
                {
                    showMenu("channels");
                    return;
                }
                // ----------------------------------------------
                // Character management commands.
                // ----------------------------------------------
                else if (cmdMatch("characters", mesg)) // Character management menu.
                {
                    showMenu("characters");
                    return;
                }
                else if (cmdMatch("new", mesg)) // New character command.
                {
                    mesg = llGetSubString(mesg, 3, -1);
                    if ((llGetListLength(g_characters) / 11) == 12 || llGetUsedMemory() > 60000)
                    {
                        llOwnerSay("Sorry, there isn't enough space for another character.");
                        return;
                    }

                    g_textField = -4; // Selects new character command.
                    if (mesg == " " || mesg == "  ") // No parameter text. Offer textbox.
                    {
                        llTextBox(llGetOwner(), "Type the name of the new character below.", g_channel);
                        
                        if (mesg == "  ") // If we had a menu flag, set reshow bit.
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else if (cmdMatch("select", mesg)) // Select character menu/command.
                {
                    mesg = llGetSubString(mesg, 6, -1);
                    g_textField = -5; // Selects character selection command.
                    if (mesg == " " || mesg == "  ")
                    {
                        llDialog(llGetOwner(), "Select a character:", charSelect(), g_channel);

                        if (mesg == "  ") // If we had a menu flag, set reshow bit.
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else if (cmdMatch("erase", mesg)) // Erase character menu/command.
                {
                    mesg = llGetSubString(mesg, 5, -1);
                    g_textField = -6; // Selects character erase command.
                    if (mesg == " " || mesg == "  ")
                    {
                        llDialog(llGetOwner(), "Select a character to erase:", charSelect(), g_channel);

                        if (mesg == "  ") // If we had a menu flag, set reshow bit.
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                // ----------------------------------------------
                // Details commands.
                // ----------------------------------------------
                else if (cmdMatch("details", mesg)) // Status command/menu.
                {
                    showMenu("details");
                    return;
                }
                else if (cmdMatch("name", mesg)) // Character name.
                {
                    mesg = llGetSubString(mesg, 4, -1);
                    g_textField = 0;
                    if (mesg == " " || mesg == "  ") // No parameter text. Offer textbox.
                    {
                        llTextBox(llGetOwner(), 
                            "Type in the blank to set a new character name.\n\nCurrent: \"" + 
                            llList2String(g_characters, (g_curCharacter * 11)) + "\"",
                        g_channel);
                        
                        if (mesg == "  ") // If we had a menu flag, set reshow bit.
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else if (cmdMatch("prefix", mesg)) // Prefix.
                {
                    mesg = llGetSubString(mesg, 6, -1);
                    g_textField = 1;
                    if (mesg == " " || mesg == "  ")
                    {
                        llTextBox(llGetOwner(), 
                            "Type in the blank to set a new prefix.\n\nCurrent: \"" + 
                            llList2String(g_characters, (g_curCharacter * 11) + 1) + "\"",
                        g_channel);
                        
                        if (mesg == "  ")
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else if (cmdMatch("sex", mesg)) // Sex/Gender.
                {
                    mesg = llGetSubString(mesg, 3, -1);
                    g_textField = 2;
                    if (mesg == " " || mesg == "  ")
                    {
                        llTextBox(llGetOwner(), 
                            "Type in the blank to set a new gender/sex.\n\nCurrent: \"" + 
                            llList2String(g_characters, (g_curCharacter * 11) + 2) + "\"",
                        g_channel);
                        
                        if (mesg == "  ")
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else if (cmdMatch("species", mesg)) // Species.
                {
                    mesg = llGetSubString(mesg, 7, -1);
                    g_textField = 3;
                    if (mesg == " " || mesg == "  ")
                    {
                        llTextBox(llGetOwner(), 
                            "Type in the blank to set a new species.\n\nCurrent: \"" + 
                            llList2String(g_characters, (g_curCharacter * 11) + 3) + "\"",
                        g_channel);
                        
                        if (mesg == "  ")
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else if (cmdMatch("misc1", mesg) || cmdMatch("misc2", mesg) || // Misc.
                         cmdMatch("misc3", mesg) || cmdMatch("misc4", mesg)) 
                {
                    g_textField = 3 + ((integer)llGetSubString(mesg, 4, 4));
                    mesg = llGetSubString(mesg, 5, -1);
                    if (mesg == " " || mesg == "  ")
                    {
                        llTextBox(llGetOwner(), 
                            "Type in the blank to set a new value.\n\nCurrent: \"" + 
                            llList2String(g_characters, (g_curCharacter * 11) + g_textField) + "\"",
                        g_channel);
                        
                        if (mesg == "  ")
                        {
                            g_settings = (g_settings | 0x00000080);
                        }
                        return;
                    }
                }
                else // Garbage command/we don't know what to do with this.
                {
                    return;
                }

                updateText(); // Update text. Leaf commands will always get here.
                mesg = llStringTrim(mesg, STRING_TRIM); // Trim whitespace for next iteration.
            }
        }
        else // Process this as character text.
        {
            string t = llGetObjectName(); // Temp store original object name.
            name = "";

            integer postType = 0; // Default is say.
            if (cmdMatch("/me", mesg)) // Remove /me and set emote flag.
            {
                mesg = llStringTrim(llGetSubString(mesg, 3, -1), STRING_TRIM);
                postType = 1;
            }
            else if (cmdMatch(":", mesg)) // Treat MU* style pose ':' same as /me.
            {
                mesg = llStringTrim(llGetSubString(mesg, 1, -1), STRING_TRIM);
                postType = 1;
            }
            else if (cmdMatch("`", mesg)) // Backtick is a 'spoof'/narrator command.
            {
                mesg  = llStringTrim(llGetSubString(mesg, 1, -1), STRING_TRIM);
                postType = 2;
            }

            if (cmdMatch("((", mesg) || g_status > 0) // OOC command triggered. Set prefix.
            {
                name = "[OOC] ";

                if (!cmdMatch("((", mesg)) // Add OOC parens if we're OOC/AFK and didn't add them.
                {
                    mesg = "((" + mesg;
                }

                if (llGetSubString(mesg, -2, -1) != "))") // Auto-complete OOC parenthesis.
                {
                    mesg += "))";
                }
            }

            if (postType > 1) // Spoof/narrator?
            {
                name += "-";
            }
            else // Add character name.
            {
                name += llList2String(g_characters, (g_curCharacter * 11));

                if (postType) // Prepend the emote command if emote flag was set.
                {
                    mesg = "/me " + mesg;
                }
            }

            llSetObjectName(name);
            
            if ((g_settings & 0x00000004)) // Send text at desired chat volume.
            {
                llWhisper(0, mesg);
            }
            else
            {
                llSay(0, mesg);
            }

            llSetObjectName(t); // Restore original object name.
        }
    }
}
