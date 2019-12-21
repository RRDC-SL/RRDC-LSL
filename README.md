# RRDC Scripting Project
LSL scripts written for RRDC in Second Life.

Sub-projects are organized into directories. Not all sub-projects are used.
------

## Collar and Cuffs Upgrade Instructions ##

1. Rez collar and cuff set on the ground.
2. Delete all scripts from every prim of every object.
3. For each object, go through every prim in the linkset and copy any contents to your inventory.
    * (optional) After copying the contents, delete them from the prim.

4. Copy assets from the folder you created back into the collar/cuffs.
    * Copy all animations into the root prim of the collar.
    * (optional) Copy all sounds into the root prim of the collar.
    * (optional) Copy all textures into the root prim of the collar.
    * (optional) Copy 'thinchain' into the root prim of each cuff.

5. (optional, recommended) Remove unnecessary prims from each cuffs linkset.
    * Each cuff should have exactly two transparent spheres. One on each side.
    * Unlink and delete additional spheres. Pay attention to which side 'LM-LG link' spheres are on.
    * Make sure the remaining spheres are centered on the top of the cuff anchor point.

6. Name the spheres on the 'LM-LG link' side of each cuff 'outerLink'.
7. Name the spheres on the opposite side of each cuff 'innerLink'.
8. Set the description of the root prim of the collar and each cuff as follows:
    * Collar should have the description 'collar'.
    * Left wrist cuff should have the description 'lcuff'.
    * Right wrist cuff should have the description 'rcuff'.
    * Left ankle cuff should have the description 'llcuff'.
    * Right ankle cuff should have the descrption 'rlcuff'.

9. Drop the collar.lsl script into the root prim of the collar.
10. Drop the cuff.lsl script into the root prim of each cuff.
