// [SGD] RRDC Collar Script v0.25 - Copyright 2019 Alex Pascal (Alex Carpenter) @ Second Life.
// ---------------------------------------------------------------------------------------------------------
// This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. 
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
// =========================================================================================================

// Modifiable Variables.
// ---------------------------------------------------------------------------------------------------------
integer g_appChan           = -89039937;        // The channel for this application set.
integer g_useChainSteps     = TRUE;             // If FALSE, random chain steps are not played.

// Assets.
// ---------------------------------------------------------------------------------------------------------
string  g_whiteTex          =   "aaff45c0-a0ef-c00d-58cb-bff31860d7be"; // RRDC_Collar_Metals_Diffuse_Wte.
string  g_orangeTex         =   "658f1177-cede-3ea2-57f9-d50e2b1402e4"; // RRDC_Collar_Metals_Diffuse_Orange.
string  g_lilacTex          =   "25be29e2-cc69-1559-4ad9-511d130554b9"; // RRDC_Collar_Metals_Diffuse_Lilac.
string  g_blueTex           =   "7add76cf-24f4-a2d3-6102-c6338db891fc"; // RRDC_Collar_Metals_Diffuse_Blue.
string  g_blackTex          =   "8c61b3ad-2723-cc83-c454-e602a8258ed7"; // RRDC_Collar_Metals_Diffuse_Blk.
string  g_whiteCuffTex      =   "700b9155-5138-e4c7-d194-1db9a6c09861"; // RRDC_Cuff_Diffuse_Basic.
string  g_orangeCuffTex     =   "ec94158c-2455-be49-a07d-7604be76c933"; // RRDC_Cuff_Diffuse_Orange.
string  g_lilacCuffTex      =   "93628600-5364-0a17-fcd8-e617ddd731e5"; // RRDC_Cuff_Diffuse_Lilac.
string  g_blueCuffTex       =   "e84a056b-f95f-a0db-acf0-7354749bbc03"; // RRDC_Cuff_Diffuse_Blue.
string  g_blackCuffTex      =   "04c857b4-78d1-8add-3d45-c134e70afa8f"; // RRDC_Cuff_Diffuse_Black.
string  g_partTex           =   "dbeee6e7-4a63-9efe-125f-ceff36ceeed2"; // thinchain.
 
string  g_zapLoopSound      =   "27a18333-a425-30b1-1ab6-c9a3a3554903"; // soundZapLoop.
string  g_zapStopSound      =   "a4602ead-96f3-ee86-5e0f-63faeb1ed7cf"; // soundZapStop.
list    g_chainSteps        = [ "f729d711-085e-f899-a723-a4afefd6a7d0", // ChainStep001.
                                "1f08a669-11ac-96e0-0435-419d2ae01254", // ChainStep002.
                                "9da21f36-14b1-9e79-3363-fc9d241628ba", // ChainStep003.
                                "35154062-4f0d-a489-35d3-696d8004b0cc", // ChainStep004.
                                "93ce44ed-014d-6e58-9d7b-1c9c5242ac6c"  // ChainStep005.
                              ];
 
string  g_zapAnim           =   "animCollarZap";                        // Played during shock effect.
string  g_poseBackU         =   "cuffedArmsBackU_001";                  // Arms behind back U pose.
string  g_poseBackV         =   "cuffedArmsBackV_001";                  // Arms behind back V pose.
string  g_poseFrontX        =   "cuffedArmsFrontX_001";                 // Arms in front X pose.
string  g_poseFrontV        =   "cuffedArmsFrontV_002";                 // Arms in front V pose.
list    g_poseComboSet      = [ "cuffedArmsCollar001",                  // Arms in front V pose higher.
                                "cuffedNeckForward001"                  // Neck forward pose.
                              ];

// Particle System Defaults. It is best not to mess with these.
// ---------------------------------------------------------------------------------------------------------
float   g_partSizeX         = 0.04;             // Particle size X-axis.
float   g_partSizeY         = 0.04;             // Particle size Y-axis.
float   g_partLife          = 1.2;              // How long each particle 'lives'.
float   g_partGravity       = 0.3;              // How much gravity affects the particles.
vector  g_partColor         = <1.0, 1.0, 1.0>;  // Color of the particles.
float   g_partRate          = 0.01;             // Interval between particle bursts.
integer g_partFollow        = 1;                // Particles move relative to the emitter.

// =========================================================================================================
// CAUTION: Modifying anything below this line may cause issues. Edit at your own risk!
// =========================================================================================================
string  g_curPartTex;                           // Current particle texture.
float   g_curPartSizeX;                         // Current particle X size.
float   g_curPartSizeY;                         // Current particle Y size.
float   g_curPartLife;                          // Current particle life.
float   g_curPartGravity;                       // Current particle gravity.
vector  g_curPartColor;                         // Current particle color.
float   g_curPartRate;                          // Current particle rate.
integer g_curPartFollow;                        // Current particle follow flag.
integer g_leashPartOn;                          // If TRUE, leashLink particles are on.
integer g_shacklePartOn;                        // If TRUE, shackleLink particles are on.
string  g_leashPartTarget;                      // Key of the target prim for LG/leash.
string  g_shacklePartTarget;                    // Key of the target prim for shackle.
integer g_leashLink;                            // Link number of the leashing point prim.
integer g_shackleLink;                          // Link number of the chain to shackles point prim.
integer g_particleMode;                         // FALSE = LG/LM, TRUE = Intercuff.
list    g_LGTags;                               // List of current LockGuard tags.
list    g_LMTags;                               // List of current LockMeister tags.

// State Variables.
// ---------------------------------------------------------------------------------------------------------
list    g_animList;                             // List of currently playing (base) anim names.
integer g_animToggle;                           // 0 = A versions playing. 1 = B versions playing.
integer g_powerLink;                            // Link number of the power core FX prim.
integer g_ledLink;                              // Link number of the LED light.
integer g_ledState;                             // Tracks the current on-off state of the LED.
integer g_ledCount;                             // Tracks how long to wait to blink LED.
integer g_shockCount;                           // Tracks how long to keep shock active.
integer g_ankleChain;                           // If TRUE, ankle chain is active.
integer g_isShackled;                           // If TRUE, wrist to ankle shackle chain active.
integer g_leashMode;                            // 0=Nothing,1=Collar,2=ChainGang,3=Cuffed.
list    g_curMenus;                             // Tracks current menu by user.
// ---------------------------------------------------------------------------------------------------------

// getAvChannel - Given an avatar key, returns a static channel XORed with g_appChan.
// ---------------------------------------------------------------------------------------------------------
integer getAvChannel(key av)
{
    return (0x80000000 | ((integer)("0x"+(string)av) ^ g_appChan));
}

// fMin - Given two floats, returns the smallest.
// ---------------------------------------------------------------------------------------------------------
float fMin(float f1, float f2)
{
    if (f2 < f1)
    {
        return f2;
    }
    return f1;
}

// fMax - Given two floats, returns the largest.
// ---------------------------------------------------------------------------------------------------------
float fMax(float f1, float f2)
{
    if (f2 > f1)
    {
        return f2;
    }
    return f1;
}

// inRange - Returns TRUE if the object is less than 6m from our position.
// ---------------------------------------------------------------------------------------------------------
integer inRange(key object)
{
    return (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(object, [OBJECT_POS]), 0)) < 6.0);
}

// getAnimVersion - Given a toggle state, returns the anim version as a string.
// ---------------------------------------------------------------------------------------------------------
string getAnimVersion(integer toggle)
{
    if (toggle)
    {
        return "b";
    }
    return "a";
}

// playRandomSound - Plays a random chain sound.
// ---------------------------------------------------------------------------------------------------------
playRandomSound()
{
    llTriggerSound(llList2String(g_chainSteps, (integer)llFrand(llGetListLength(g_chainSteps))), 0.2);
}

// stopCurAnims - Stop all AO anims that are playing.
// ---------------------------------------------------------------------------------------------------------
stopCurAnims()
{
    llSetTimerEvent(0.0); // Stop timer, then anims.
    integer i;
    for (i = 0; i < llGetListLength(g_animList); i++)
    {
        llStopAnimation(llList2String(g_animList, i) + getAnimVersion(g_animToggle));
    }
    g_animList = [];
    llSetTimerEvent(0.2); // Restart timer.

    playRandomSound();
}

// leashParticles - Turns outer/LockGuard chain/rope particles on or off.
// ---------------------------------------------------------------------------------------------------------
leashParticles(integer on)
{
    g_leashPartOn = on; // Save the state we passed in.
    
    if(!on) // If LG particles should be turned off, turn them off and reset defaults.
    {
        llLinkParticleSystem(g_leashLink, []); // Stop particle system and clear target.
        g_leashPartTarget   = NULL_KEY;
    }
    else // If LG particles are to be turned on, turn them on.
    {
        // Particle bitfield defaults.
        integer nBitField = (PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK);
    
        if(g_curPartGravity == 0) // Add linear mask if gravity is not zero.
        {
            nBitField = (nBitField | PSYS_PART_TARGET_LINEAR_MASK);
        }

        if(g_curPartFollow) // Add follow mask if flag is set.
        {
            nBitField = (nBitField | PSYS_PART_FOLLOW_SRC_MASK);
        }
        
        llLinkParticleSystem(g_leashLink,
        [
            PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_DROP,
            PSYS_SRC_BURST_PART_COUNT,  1,
            PSYS_SRC_MAX_AGE,           0.0,
            PSYS_PART_MAX_AGE,          g_curPartLife,
            PSYS_SRC_BURST_RATE,        g_curPartRate,
            PSYS_SRC_TEXTURE,           g_curPartTex,
            PSYS_PART_START_COLOR,      g_curPartColor,
            PSYS_PART_START_SCALE,      <g_curPartSizeX, g_curPartSizeY, 0.0>,
            PSYS_SRC_ACCEL,             <0.0, 0.0, (g_curPartGravity * -1.0)>,
            PSYS_SRC_TARGET_KEY,        (key)g_leashPartTarget,
            PSYS_PART_FLAGS,            nBitField
        ]);
    }
}

// shackleParticles - Turns inner chain/rope particles on or off.
// ---------------------------------------------------------------------------------------------------------
shackleParticles(integer on)
{
    g_shacklePartOn = on;

    if (!on) // Turn inner particle system off.
    {
        llLinkParticleSystem(g_shackleLink, []); // Stop particle system and clear target.
        g_shacklePartTarget   = NULL_KEY;
    }
    else // Turn the inner particle system on.
    {
        // Particle bitfield defaults.
        integer nBitField = (PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK);
    
        if(g_partGravity == 0) // Add linear mask if gravity is not zero.
        {
            nBitField = (nBitField | PSYS_PART_TARGET_LINEAR_MASK);
        }

        if(g_partFollow) // Add follow mask if flag is set.
        {
            nBitField = (nBitField | PSYS_PART_FOLLOW_SRC_MASK);
        }
        
        llLinkParticleSystem(g_shackleLink,
        [
            PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_DROP,
            PSYS_SRC_BURST_PART_COUNT,  1,
            PSYS_SRC_MAX_AGE,           0.0,
            PSYS_PART_MAX_AGE,          g_partLife,
            PSYS_SRC_BURST_RATE,        g_partRate,
            PSYS_SRC_TEXTURE,           g_partTex,
            PSYS_PART_START_COLOR,      g_partColor,
            PSYS_PART_START_SCALE,      <g_partSizeX, g_partSizeY, 0.0>,
            PSYS_SRC_ACCEL,             <0.0, 0.0, (g_partGravity * -1.0)>,
            PSYS_SRC_TARGET_KEY,        (key)g_shacklePartTarget,
            PSYS_PART_FLAGS,            nBitField
        ]);
    }
}

// toggleMode - Controls particle system when changing between LG/LM and Interlink.
// ---------------------------------------------------------------------------------------------------------
toggleMode(integer mode)
{
    if (g_particleMode != mode) // If the mode actually changed.
    {
        leashParticles(FALSE);   // Clear all particles.
        shackleParticles(FALSE);

        g_particleMode = mode; // Toggle mode.
    }
}

// giveCharSheet - Gives a copy of the character sheet to the user, if present.
// ---------------------------------------------------------------------------------------------------------
giveCharSheet(key user)
{
    if (llGetInventoryNumber(INVENTORY_NOTECARD)) // Notecard is present.
    {
        string note = llGetInventoryName(INVENTORY_NOTECARD, 0);

        // Make sure we can transfer a copy of the notecard to the toucher.
        if (llGetInventoryPermMask(note, MASK_OWNER) & (PERM_COPY | PERM_TRANSFER))
        {
            llOwnerSay("secondlife:///app/agent/" + ((string)user) + "/completename" +
                " has requested a copy of your character sheet.");

            llGiveInventory(user, note); // Offer notecard.
        }
        else
        {
            llInstantMessage(user, "No character sheet is available.");
        }
    }
    else // No notecard present.
    {
        llInstantMessage(user, "No character sheet is available.");
    }
}

// showMenu - Given a menu name string, shows the appropriate menu.
// ---------------------------------------------------------------------------------------------------------
showMenu(string menu, key user)
{
    integer i;
    for (i = 0; i < llGetListLength(g_curMenus); i += 3) // Updating existing and remove old.
    {
        if (llList2Key(g_curMenus, i) == user)
        {
            if (menu == "") // Access last used menu if menu argument is empty.
            {
                menu = llList2String(g_curMenus, (i + 2));
            }

            g_curMenus = llListReplaceList(g_curMenus, [(string)llGetTime(), menu], (i + 1), (i + 2));
        }
        else if (llList2Key(g_curMenus, i) != llGetOwner() &&
                 (llGetTime() - llList2Float(g_curMenus, (i + 1))) > 60.0)
        {
            g_curMenus = llDeleteSubList(g_curMenus, i, (i + 2));
            i -= 3;
        }
    }

    if (menu == "") // Ensure we always have a menu name.
    {
        menu = "main";
    }

    if (llListFindList(g_curMenus, [(string)user]) <= -1) // Add user if they are new.
    {
        g_curMenus += [(string)user, (string)llGetTime(), menu];
    }

    string text = "\n\nChoose an option:";
    list buttons = [];
    if (menu == "main") // Show main menu.
    {
        // Wearer Menu.
        // -----------------------------------------------
        // CharSheet        Shock           Poses
        // Ankle Chain      Chain Gang      Shackle Link
        // Cuff To          Grab Leash      Leash To
        // Textures         Sounds          Close
        //
        // Staff Menu.
        // -----------------------------------------------
        // CharSheet        Shock           Poses
        // Ankle Chain      Chain Gang      Shackle Link
        // Cuff To          Grab Leash      Leash To
        //
        // Inmate Menu.
        // -----------------------------------------------
        // CharSheet (Just give char sheet. No menu.)

        text = "Main Menu" + text;

        if (user == llGetOwner())
        {
            buttons = ["Textures",    "Sounds",     "Close",
                       "Cuff To",     "Grab Leash", "Leash To",
                       "Ankle Chain", "Chain Gang", "Shackle Link",
                       "CharSheet",   "Shock",      "Poses"];
        }
        else if (inRange(user))
        {
            buttons = ["Cuff To",     "Grab Leash", "Leash To",
                       "Ankle Chain", "Chain Gang", "Shackle Link",
                       "CharSheet",   "Shock",      "Poses"];
        }
        else // Only CharSheet option in menu, so just give CharSheet.
        {
            giveCharSheet(user);
            return;
        }
    }
    else if (menu == "poses") // Poses menu.
    {
        text = "Pose Selection Menu" + text;
        buttons = [" ", " ", "↺ Main", "Back U", "Release", "ComboSet", "Front X", "Front V", "Back V"];
    }
    else if (menu == "textures") // Textures menu.
    {
        text = "Texture Select Menu" + text;
        buttons = ["Blue", "Black", "↺ Main", "White", "Orange", "Lilac"];
    }
    else if (menu == "sounds") // Sound settings menu.
    {
        text = "Walking Sound Effects Menu" + text + "\n\nCurrent setting: ";
        if (g_useChainSteps)
        {
            text += "Walk Sounds";
        }
        else
        {
            text += "Walk Muted";
        }
        buttons = ["Mute Walk", "Unmute Walk", "↺ Main"];
    }
    llDialog(user, text, buttons, getAvChannel(llGetOwner()));
}

// Make sure we have permissions before we allow anything to happen.
// ---------------------------------------------------------------------------------------------------------
default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), 
            (PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION)
        );
    }

    run_time_permissions(integer perm)
    {
        if (perm & (PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION))
        {
            state main;
        }
    }
}

// Main state is where everything happens once we have perms.
// ---------------------------------------------------------------------------------------------------------
state main
{
    // Initialize collar.
    // -----------------------------------------------------------------------------------------------------
    state_entry()
    {
        // Set the texture anim for the electric effects on the collar base.
        llSetLinkTextureAnim(LINK_THIS, ANIM_ON | LOOP, 2, 32, 32, 0.0, 64.0, 20.4);

        integer i; // Find the prims we will work with.
        string tag;
        for (i = 1; i <= llGetNumberOfPrims(); i++)
        {
            tag = llList2String(llGetLinkPrimitiveParams(i, [PRIM_NAME]), 0);
            if (tag == "powerCore")
            {
                g_powerLink = i; // Also set texture anim for the power core.
                llSetLinkTextureAnim(i, ANIM_ON | LOOP, ALL_SIDES, 20, 20, 0.0, 64.0, 30.4);
            }
            else if (tag == "LED")
            {
                g_ledLink = i;
            }
            else if (tag == "leashingPoint")
            {
                g_leashLink = i;
            }
            else if (tag == "chainToShacklesPoint")
            {
                g_shackleLink = i;
            }
        }

        // Parse the description field for potential LM tags.
        list l = llParseString2List(llGetObjectDesc(),[":"],[]);
        
        if(l == []) // If we have ZERO config information, make a guess based on attach point.
        {
            l = llList2List(["","collar","thead","lblade","rblade","lhand","rhand","llcuff",
                            "rlcuff","collar","pelvis","lbit","rbit","","","","","nose",
                            "rbiceps","rcuff","lbiceps","lcuff","rfbelt","rtigh","rlcuff",
                            "lfbelt","ltigh","llcuff","fbelt","lnipple","rnipple","","","",
                            "","","","","","collar","fbelt"],
                llGetAttached(),llGetAttached());
        }

        // List of Lockmeister IDs which have LockGuard equivalents.
        // ------------------------------------------------------------------------------------
        list lmID = ["rcuff","rbiceps","lbiceps","lcuff","lblade","rblade","rnipple",
                    "lnipple","rtigh","ltigh","rlcuff","llcuff","pelvis","fbelt","bbelt",
                    "rcollar","lcollar","thead","collar","lbit","rbit","nose","bcollar",
                    "back"];

        // List of LockGuard IDs which correspond to the Lockmeister IDs.
        //  Multiples are separated by a bar |.
        // ------------------------------------------------------------------------------------
        list lgID = ["rightwrist|wrists|allfour","rightupperarm|arms","leftupperarm|arms",
                    "leftwrist|wrists|allfour","harnessleftshoulderloop",
                    "harnessrightshoulderloop","rightnipplering|nipples",
                    "leftnipplering|nipples","rightupperthigh|thighs","leftupperthigh|thighs",
                    "rightankle|ankles|allfour","leftankle|ankles|allfour",
                    "clitring|cockring|ballring","frontbeltloop","backbeltloop",
                    "collarrightloop","collarleftloop","topheadharness", "collarfrontloop",
                    "leftgag","rightgag","nosering","collarbackloop","harnessbackloop"];
        
        integer j; // Parse all the LM tags found.
        list tList;
        for(i = 0; i < llGetListLength(l); i++)
        {
            tag = llToLower(llStringTrim(llList2String(l,i), STRING_TRIM)); // Clean tag name.
            
            j = llListFindList(lmID, [tag]);
            if (j > -1) // LM tag. Add if not already present.
            {
                if (llListFindList(g_LMTags, [tag]) <= -1)
                {
                    g_LMTags += [tag];
                }

                // Add corresponding LG tags, if not present.
                tList = llParseString2List(llList2String(lgID, j), ["|"], []);
                if (llListFindList(g_LGTags, [llList2String(tList, 0)]) <= -1)
                {
                    g_LGTags += tList;
                }
            }
        }

        llSetMemoryLimit(llGetUsedMemory() + 2048); // Limit script memory consumption.

        if (g_LMTags == [] || g_shackleLink <= 0 || g_leashLink <= 0)
        {
            llOwnerSay("FATAL: Unknown anchor and/or missing chain emitters!");
            return;
        }

        g_curPartTex        = g_partTex;    // Set current LG settings back to defaults.
        g_curPartSizeX      = g_partSizeX;
        g_curPartSizeY      = g_partSizeY;
        g_curPartLife       = g_partLife;
        g_curPartGravity    = g_partGravity;
        g_curPartColor      = g_partColor;
        g_curPartRate       = g_partRate;
        g_curPartFollow     = g_partFollow;

        shackleParticles(FALSE); // Stop any particle effects and init.
        leashParticles(FALSE);

        llTakeControls( // Initial take of controls in passthrough, just to be safe.
                        CONTROL_FWD |
                        CONTROL_BACK |
                        CONTROL_LEFT |
                        CONTROL_RIGHT |
                        CONTROL_ROT_LEFT |
                        CONTROL_ROT_RIGHT |
                        CONTROL_UP |
                        CONTROL_DOWN |
                        CONTROL_LBUTTON |
                        CONTROL_ML_LBUTTON,
                        FALSE, TRUE
        );

        llListen(-8888,"",NULL_KEY,""); // Open up LockGuard and Lockmeister listens.
        llListen(-9119,"",NULL_KEY,"");

        llListen(getAvChannel(llGetOwner()), "", "", ""); // Open collar/cuffs avChannel.
        
        llSetTimerEvent(0.2); // Start the timer.
    }

    // Reset the script on rez.
    // ---------------------------------------------------------------------------------------------------------
    on_rez(integer param)
    {
        llResetScript();
    }
    
    // Show the menu to the user on touch.
    // ---------------------------------------------------------------------------------------------------------
    touch_start(integer num)
    {
        showMenu("main", llDetectedKey(0));
    }

    // Parse and interpret commands.
    // ---------------------------------------------------------------------------------------------------------
    listen(integer chan, string name, key id, string mesg)
    {
        if (chan == getAvChannel(llGetOwner())) // Process RRDC Menu/Commands.
        {
            if (llGetOwnerKey(id) != id) // Process RRDC commands.
            {
                list l = llParseString2List(mesg, [" "], []);
                if (llListFindList(g_LGTags, [llList2String(l, 1)]) > -1) // LG tag match.
                {
                    name = llToLower(llList2String(l, 0));
                    if (name == "unlink") // unlink collarfrontloop <leash|shackle>
                    {
                        if (llToLower(llList2String(l, 2)) == "shackle")
                        {
                            shackleParticles(FALSE);
                        }
                        else if (g_particleMode) // Leash.
                        {
                            leashParticles(FALSE);
                        }
                    }
                    else if (name == "link") // link collarfrontloop <leash|shackle> <dest-uuid>
                    {
                        toggleMode(TRUE);
                        if (llToLower(llList2String(l, 2)) == "shackle")
                        {
                            g_shacklePartTarget = llList2Key(l, 3);
                            shackleParticles(TRUE);
                        }
                        else // Leash.
                        {
                            g_leashPartTarget = llList2Key(l, 3);
                            leashParticles(TRUE);
                        }
                    }       // linkrequest collarfrontloop <leash|shackle> <src-tag> <inner|outer>
                    else if (name == "linkrequest")
                    {
                        if (llToLower(llList2String(l, 2)) == "shackle") // Get the link UUID.
                        {
                            name = (string)llGetLinkKey(g_shackleLink);
                        }
                        else // Leash.
                        {
                            name = (string)llGetLinkKey(g_leashLink);
                        }

                        llWhisper(getAvChannel(llGetOwner()), "link " + // Send link message.
                            llList2String(l, 3) + " " +
                            llList2String(l, 4) + " " + name
                        );
                    }
                    else if (name == "stopposes") // stopposes collarfrontloop
                    {
                        stopCurAnims();
                    }
                }
                return;
            }
            else if (mesg == "↺ Main") // Show main menu.
            {
                showMenu("main", id);
                return;
            }
            else if (mesg == "Close") // Close button does nothing but return.
            {
                return;
            }
            else if (mesg == "CharSheet") // Give notecard.
            {
                giveCharSheet(id);
            }
            else if (inRange(id) || id == llGetOwner()) // Only parse these if we're in range/the wearer.
            {
                if (mesg == "Shock") // Shock feature.
                {
                    llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                        " just activated your shock collar!");

                    llSetTimerEvent(0.0);
                    llTakeControls(
                                    CONTROL_FWD |
                                    CONTROL_BACK |
                                    CONTROL_LEFT |
                                    CONTROL_RIGHT |
                                    CONTROL_ROT_LEFT |
                                    CONTROL_ROT_RIGHT |
                                    CONTROL_UP |
                                    CONTROL_DOWN |
                                    CONTROL_LBUTTON |
                                    CONTROL_ML_LBUTTON,
                                    TRUE, FALSE
                    );
                    llStartAnimation(g_zapAnim);
                    llLoopSound(g_zapLoopSound, 0.5);
                    g_shockCount = 11; // 0.8 seconds, then 2.0 seconds.
                    llSetTimerEvent(0.2);
                }
                else if (mesg == "Ankle Chain") // Toggle chain between ankles.
                {
                    if (g_ankleChain = !g_ankleChain)
                    {
                        llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                            " attached your ankle chain.");

                        llWhisper(getAvChannel(llGetOwner()), "linkrequest rightankle inner leftankle inner");
                    }
                    else
                    {
                        llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                            " removed your ankle chain.");

                        llWhisper(getAvChannel(llGetOwner()), "unlink leftankle inner");
                    }
                    playRandomSound();
                }
                else if (mesg == "Shackle Link") // Toggle chains from wrists to ankles.
                {
                    if (g_isShackled = !g_isShackled)
                    {
                        llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                            " attached your shackle links.");

                        llWhisper(getAvChannel(llGetOwner()), "linkrequest leftankle outer leftwrist outer");
                        llWhisper(getAvChannel(llGetOwner()), "linkrequest rightankle outer rightwrist outer");
                    }
                    else
                    {
                        llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                            " removed your shackle links.");

                        llWhisper(getAvChannel(llGetOwner()), "unlink leftwrist outer");
                        llWhisper(getAvChannel(llGetOwner()), "unlink rightwrist outer");
                    }
                    playRandomSound();
                }
                // Pose Commands.
                // ---------------------------------------------------------------------------------------------
                else if (mesg == "Poses") // Pose selection menu.
                {
                    llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                        " is interacting with your handcuffs.");

                    showMenu("poses", id);
                    return;
                }
                else if (mesg == "Back U") // Emitter is always leftwrist inner or collar shacklesPoint.
                { // linkrequest <dest-tag> <inner|outer> <src-tag> <inner|outer>
                    stopCurAnims();
                    g_animList = [g_poseBackU];
                    shackleParticles(FALSE);
                    llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist outer leftwrist inner");
                }
                else if (mesg == "Back V")
                {
                    stopCurAnims();
                    g_animList = [g_poseBackV];
                    shackleParticles(FALSE);
                    llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist inner leftwrist inner");
                }
                else if (mesg == "Front X")
                {
                    stopCurAnims();
                    g_animList = [g_poseFrontX];
                    shackleParticles(FALSE);
                    llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist outer leftwrist inner");
                }
                else if (mesg == "Front V")
                {
                    stopCurAnims();
                    g_animList = [g_poseFrontV];
                    shackleParticles(FALSE);
                    llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist inner leftwrist inner");
                }
                else if (mesg == "ComboSet") // Combination two poses.
                {
                    stopCurAnims();
                    g_animList = g_poseComboSet;
                    llWhisper(getAvChannel(llGetOwner()), "linkrequest leftwrist inner collarfrontloop shackle");
                    llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist inner leftwrist inner");
                }
                else if (mesg == "Release") // Release from pose.
                {
                    stopCurAnims();
                    shackleParticles(FALSE);
                    llWhisper(getAvChannel(llGetOwner()), "unlink leftwrist inner");
                }
                else if (id == llGetOwner()) // Sound and texture commands are owner locked.
                {
                    // Texture Commands.
                    // -----------------------------------------------------------------------------------------
                    if (mesg == "Textures") // Texture select.
                    {
                        showMenu("textures", id);
                        return;
                    }
                    else if (mesg == "Blue") // Set textures.
                    {
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_TEXTURE, 0, g_blueTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                        ]);
                        llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_blueCuffTex);
                    }
                    else if (mesg == "Black")
                    {
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_TEXTURE, 0, g_blackTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                        ]);
                        llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_blackCuffTex);
                    }
                    else if (mesg == "White")
                    {
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_TEXTURE, 0, g_whiteTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                        ]);
                        llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_whiteCuffTex);
                    }
                    else if (mesg == "Orange")
                    {
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_TEXTURE, 0, g_orangeTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                        ]);
                        llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_orangeCuffTex);
                    }
                    else if (mesg == "Lilac")
                    {
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_TEXTURE, 0, g_lilacTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                        ]);
                        llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_lilacCuffTex);
                    }
                    // Sound Commands.
                    // -----------------------------------------------------------------------------------------
                    else if (mesg == "Sounds") // Turn chain walk sounds on/off.
                    {
                        showMenu("sounds", id);
                        return;
                    }
                    else if (mesg == "Mute Walk")
                    {
                        g_useChainSteps = FALSE;
                    }
                    else if (mesg == "Unmute Walk")
                    {
                        g_useChainSteps = TRUE;
                    }
                }
            }
            showMenu("", id); // Reshow current menu. Whitespace menu items end up here.
        }
        else if(chan == -8888 && llGetSubString(mesg, 0, 35) == ((string)llGetOwner())) // Process LM.
        {
            if(llListFindList(g_LMTags, [llGetSubString(mesg, 36, -1)]) > -1)
            {
                toggleMode(FALSE);
                llRegionSayTo(id, -8888, mesg + " ok");
            }
            else if (llGetSubString(mesg, 36, 54) == "|LMV2|RequestPoint|" &&      // LMV2.
                     llListFindList(g_LMTags, [llGetSubString(mesg, 55, -1)]) > -1)
            {
                llRegionSayTo(id, -8888, ((string)llGetOwner()) + "|LMV2|ReplyPoint|" + 
                    llGetSubString(mesg, 55, -1) + "|" + ((string)llGetLinkKey(g_leashLink))
                );
            }
        }                                                                          // Process LG.
        else if(chan == -9119 && llSubStringIndex(mesg, "lockguard " + ((string)llGetOwner())) == 0)
        {
            list tList = llParseString2List(mesg, [" "], []);
            
            // lockguard [avatarKey/ownerKey] [item] [command] [variable(s)] 
            if(llListFindList(g_LGTags, [llList2String(tList, 2)]) > -1 || llList2String(tList, 2) == "all")
            {
                integer i = 3; // Start at the first command position and parse the commands.
                while(i < llGetListLength(tList))
                {                    
                    name = llList2String(tList, i);
                    if(name == "link")
                    {
                        toggleMode(FALSE);
                        g_leashPartTarget = llList2Key(tList, (i + 1));
                        leashParticles(TRUE);
                        i += 2;
                    }
                    else if(name == "unlink")
                    {
                        g_curPartTex        = g_partTex;    // Set current LG settings back to defaults.
                        g_curPartSizeX      = g_partSizeX;
                        g_curPartSizeY      = g_partSizeY;
                        g_curPartLife       = g_partLife;
                        g_curPartGravity    = g_partGravity;
                        g_curPartColor      = g_partColor;
                        g_curPartRate       = g_partRate;
                        g_curPartFollow     = g_partFollow;

                        leashParticles(FALSE);
                        tList = [];
                        return;
                    }
                    else if(name == "gravity")
                    {
                        g_curPartGravity = fMax(0.0, fMin(llList2Float(tList, (i + 1)), 100.0));
                        i += 2;
                    }
                    else if(name == "life")
                    {
                        g_curPartLife = fMax(0.0, llList2Float(tList, (i + 1)));
                        i += 2;
                    }
                    else if(name == "texture")
                    {
                        name = llList2String(tList, (i + 1));
                        if(name == "chain" || name == "rope")
                        {
                            g_curPartTex = g_partTex;
                        }
                        else
                        {
                            g_curPartTex = llList2Key(tList, (i + 1));
                        }
                        i += 2;
                    }
                    else if(name == "rate")
                    {
                        g_curPartRate = fMax(0.0, llList2Float(tList, (i + 1)));
                        i += 2;
                    }
                    else if(name == "follow")
                    {
                        g_curPartFollow = (llList2Integer(tList, (i + 1)) > 0);
                        i += 2;
                    }
                    else if(name == "size")
                    {
                        g_curPartSizeX = fMax(0.03125, fMin(llList2Float(tList, (i + 1)), 4.0));
                        g_curPartSizeY = fMax(0.03125, fMin(llList2Float(tList, (i + 2)), 4.0));
                        i += 3;
                    }
                    else if(name == "color")
                    {
                        g_curPartColor.x = fMax(0.0, fMin(llList2Float(tList, (i + 1)), 1.0));
                        g_curPartColor.y = fMax(0.0, fMin(llList2Float(tList, (i + 2)), 1.0));
                        g_curPartColor.z = fMax(0.0, fMin(llList2Float(tList, (i + 3)), 1.0));
                        i += 4;
                    }
                    else if(name == "ping")
                    {
                        llRegionSayTo(id, -9119, "lockguard " + ((string)llGetOwner()) + " " +
                            llList2String(g_LGTags, 0) + " okay"
                        );
                        i++;
                    }
                    else if(name == "free")
                    {
                        if(g_leashPartOn)
                        {
                            llRegionSayTo(id, -9119, "lockguard " + ((string)llGetOwner()) + " " + 
                                llList2String(g_LGTags, 0) + " no"
                            );
                        }
                        else
                        {
                            llRegionSayTo(id, -9119, "lockguard " + ((string)llGetOwner()) + " " + 
                                llList2String(g_LGTags, 0) + " yes"
                            );
                        }
                        i++;
                    }
                    else // Skip unknown commands.
                    {
                        i++;
                    }
                }
                
                leashParticles(g_leashPartOn); // Refresh particles.
            }
        }
    }

    // Controls timed effects such as blinking light and shock.
    // ---------------------------------------------------------------------------------------------------------
    timer()
    {
        if (g_animList != []) // Persistent AO (0.2 seconds).
        {
            g_animToggle = !g_animToggle;

            integer i;
            for (i = 0; i < llGetListLength(g_animList); i++)
            {
                llStartAnimation(llList2String(g_animList, i) + getAnimVersion(g_animToggle));
                llStopAnimation(llList2String(g_animList, i) + getAnimVersion(!g_animToggle));
            }
        }

        if (g_shockCount > 0) // Shock effects.
        {
            if (g_shockCount == 10) // Ending effect.
            {
                llStopSound();
                llPlaySound(g_zapStopSound, 0.5);
            }
            g_shockCount--;
        }
        else // Release controls when the anim is done.
        {
            llTakeControls(
                            CONTROL_FWD |
                            CONTROL_BACK |
                            CONTROL_LEFT |
                            CONTROL_RIGHT |
                            CONTROL_ROT_LEFT |
                            CONTROL_ROT_RIGHT |
                            CONTROL_UP |
                            CONTROL_DOWN |
                            CONTROL_LBUTTON |
                            CONTROL_ML_LBUTTON,
                            FALSE, TRUE
            );
        }

        if (g_ledCount++ >= 4) // Blinking LED effects (1.0 seconds).
        {
            if (g_ledState = !g_ledState) 
            {
                llSetLinkPrimitiveParamsFast(g_ledLink, [
                    PRIM_COLOR, ALL_SIDES, <0.3, 0.0, 0.0>, llGetAlpha(0), 
                    PRIM_POINT_LIGHT, FALSE, ZERO_VECTOR, 0.5, 0.5, 0.1,
                    PRIM_GLOW, ALL_SIDES, 0.0
                ]);
            }
            else
            {
                llSetLinkPrimitiveParamsFast(g_ledLink, [
                    PRIM_COLOR, ALL_SIDES, <1.0, 0.0, 0.0>, llGetAlpha(0), 
                    PRIM_POINT_LIGHT, TRUE, <1.0, 0.0, 0.0>, 0.35, 0.075, 0.1,
                    PRIM_GLOW, ALL_SIDES, 1.0
                ]);
            }
            g_ledCount = 0;
        }
    }

    // Controls random chain sound effects.
    // ---------------------------------------------------------------------------------------------------------
    moving_start()
    {
        if (g_useChainSteps && (g_animList != [] || g_ankleChain || g_isShackled || g_leashMode))
        {
            playRandomSound();
        }
    }

    moving_end()
    {
        if (g_useChainSteps && (g_animList != [] || g_ankleChain || g_isShackled || g_leashMode))
        {
            playRandomSound();
        }
    }
}
