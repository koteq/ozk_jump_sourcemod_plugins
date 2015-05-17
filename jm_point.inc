#if defined _jm_point_included_
 #endinput
#endif
#define _jm_point_included_

/**
 * Called when client start toch point area
 *
 * @param client        Client index
 * @param pointId       Point index
 * @param pointCaption  Point description
 */
forward JM_Point_OnStartTouch(client, pointId, const String:pointCaption[]);

/**
 * When on round start only if new poins was added to map
 *
 * @param newCount      Aye! new count
 */
forward JM_Point_OnPointsCountChanged(newCount);

public SharedPlugin:__pl_jm_point = {
    name = "jm_point",
    file = "jm_point.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};
