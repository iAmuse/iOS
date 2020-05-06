<p align="center" >
  <img src="https://remotelyyours.teamworklive.com/ProjectOverview.htm?sp=l2197159" alt="Team Portal" title="Team Portal">
</p>

# Directory Structure

This is the root for all iOS based work.  Subfolders should correspond to the
projects and workspaces, or an external but related context such as Design or
Assets.  No Xcode workspace or project files should be found at this level.

# General Application Understanding

## Idle Detection

Views should set the kiosk idleFeelingTimeoutMins to something appropriate for
an idle user interaction at that point in the workflow.  No sense each vc having
it's own timer which would have to be switched off on segue.