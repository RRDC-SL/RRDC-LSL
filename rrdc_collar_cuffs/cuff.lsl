// [SGD] RRDC Cuffs Script v0.1 Copyright 2019 Alex Pascal (Alex Carpenter).
//  Based on combined Lockmeister and LockGuard script by Felis Darwin.
// ----------------------------------------------------------------------------------------
// This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. 
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
// ========================================================================================

// Modifiable Variables.
// ----------------------------------------------------------------------------------------
integer g_appChan           = -89039937;        // The channel for this application set.

// Assets.
// ----------------------------------------------------------------------------------------
string  g_partTex           = "40809979-b6be-2b42-e915-254ccd8d9a08"; // thinchain.

// Particle System Defaults. It is best not to mess with these.
// ----------------------------------------------------------------------------------------
float   g_partSizeX         = 0.04;             // Particle size X-axis.
float   g_partSizeY         = 0.04;             // Particle size Y-axis.
float   g_partLife          = 1.2;              // How long each particle 'lives'.
float   g_partGravity       = 0.3;              // How much gravity affects the particles.
vector  g_partColor         = <1.0, 1.0, 1.0>;  // Color of the particles.
float   g_partRate          = 0.01;             // Interval between particle bursts.
integer g_partFollow        = 0;                // Particles move relative to the emitter.

// ========================================================================================
// CAUTION: Modifying anything below this line may cause issues. Edit at your own risk!
// ========================================================================================
string  g_curPartTex;                           // Current particle texture.
float   g_curPartSizeX;                         // Current particle X size.
float   g_curPartSizeY;                         // Current particle Y size.
float   g_curPartLife;                          // Current particle life.
float   g_curPartGravity;                       // Current particle gravity.
vector  g_curPartColor;                         // Current particle color.
float   g_curPartRate;                          // Current particle rate.
integer g_curPartFollow;                        // Current particle follow flag.
integer g_particlesOn;                          // If TRUE, LG particles are on.
string  g_partTarget;                           // Key of the target prim for LG.
list    g_LGTags;                               // List of current LockGuard tags.
list    g_LMTags;                               // List of current LockMeister tags.
// ========================================================================================

// getAvChannel - Given an avatar key, returns a static channel XORed with g_appChan.
// ----------------------------------------------------------------------------------------
integer getAvChannel(key av)
{
    return (0x80000000 | ((integer)("0x"+(string)av) ^ g_appChan));
}

// fMin - Given two floats, returns the smallest.
// ----------------------------------------------------------------------------------------
float fMin(float f1, float f2)
{
    if (f2 < f1)
    {
        return f2;
    }
    return f1;
}

// fMax - Given two floats, returns the largest.
// ----------------------------------------------------------------------------------------
float fMax(float f1, float f2)
{
    if (f2 > f1)
    {
        return f2;
    }
    return f1;
}

// doParticles - Turns LockGuard chain/rope particles on or off.
// ----------------------------------------------------------------------------------------
doParticles(integer on)
{
    g_particlesOn = on; // Save the state we passed in.
    
    if(!on) // If LG particles should be turned off, turn them off and reset defaults.
    {
        llParticleSystem([]); // Stop particle system.

        g_curPartTex        = g_partTex;        // Set defaults and clear target.
        g_curPartSizeX      = g_partSizeX;
        g_curPartSizeY      = g_partSizeY;
        g_curPartLife       = g_partLife;
        g_curPartGravity    = g_partGravity;
        g_curPartColor      = g_partColor;
        g_curPartRate       = g_partRate;
        g_curPartFollow     = g_partFollow;
        g_partTarget        = NULL_KEY;
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
        
        llParticleSystem(
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
            PSYS_SRC_TARGET_KEY,        (key)g_partTarget,
            PSYS_PART_FLAGS,            nBitField
        ]);
    }
}

default
{
    // Initialize the script.
    // ----------------------------------------------------------------------------------------
    state_entry()
    {   
        llSetMemoryLimit(llGetUsedMemory()+4096); // Limit script memory consumption.

        llListen(-8888,"",NULL_KEY,""); // Open up LockGuard and Lockmeister listens.
        llListen(-9119,"",NULL_KEY,"");

        llListen(getAvChannel(llGetOwner()), "", "", ""); // Open collar/cuffs avChannel.
        
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
        
        integer i; // Parse all the LM tags found.
        integer j;
        string tag;
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

        doParticles(FALSE); // Stop any particles from LockGuard effects and init.
    }

    // Reset the script on rez and if the inventory changes.
    // ----------------------------------------------------------------------------------------
    on_rez(integer param)
    {
        llResetScript();
    }
    
    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

    // Listen for LG and LM commands.
    // ----------------------------------------------------------------------------------------
    listen(integer chan, string name, key id, string mesg)
    {
        if(chan == -8888 && llGetSubString(mesg, 0, 35) == ((string)llGetOwner())) // Process LM.
        {
            if(llListFindList(g_LMTags, [llGetSubString(mesg, 36, -1)]) > -1)
            {
                llRegionSayTo(id, -8888, mesg + " ok");
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
                        g_partTarget = llList2Key(tList, (i + 1));
                        doParticles(TRUE);
                        i += 2;
                    }
                    else if(name == "unlink")
                    {
                        doParticles(FALSE);
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
                        if(g_particlesOn)
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
                
                doParticles(g_particlesOn); // Refresh particles.
            }
        }
    }
}
