Release History

1.1.18

- Camera mode resources required clean and build to pick up new splash image
- Foreground field added to PhotoLayout, if present it overlays it as final layer
	- sample provided with shark1.jpg|shark1mask.png in new default DB
	- disable by deleting foreground field on layout in DB

1.1.17

- Carousel preloading cache
- Camera splash replaced
- Thank you interval shortened to 10 sec

1.1.16

- Carousel reworked for 50 item event, smarter memory management, and incremental loading.

1.1.15

- Carousel selections increased in size by 40%.

1.1.14

- Enabled thank you sync feature, not being activated from iPad.

1.1.13

- Reverted background flip left to right, retaining video flip only.

1.1.12

- Hid the Print button for now, enabling the left-right flip for immediate use without print.

1.1.11

- Camera flipped left to right, providing guests the appearance of moving left when _they_ move left.
	- FoV Curtain modified to retain left/right setup based on installer looking at camera
	- Likewise offsets continue to work based on looking at camera not external screen

1.1.10

- First Version with Print
	- Requires the user to hit a second print button in the standard dialog
	- Remembers the last printer used successully
	- Scales the selected Photo with Aspect Fit to 4x6, 5x7, leaving a border top and bottom

1.1.9

- Fix for cloud activation using new iAmuse product code
- Changed & in default database T&C checkbox

1.1.8

- Corrected build directives not migrated since iAmuse branch split.

1.1.7

- Fix for Camera abort due to missing layout1.jpg
- Packaging changes for missing resources
- Updated default settings

1.1.6

- First release of iAmuse build target and new repo.
- Addition of Account username, password settings and device activation within datastore.

1.1.5

- Validation of email address to enable send button

1.1.4

- Removal of Done/Finish button, Send advances to Thank You and there is no way to send to multiple email accounts or send multiple photos
- Additional autolayout changes

1.1.3

- Sharing screen
	- Numerous behvaviour changes
	- Addition of Back button
- Additional autolayout fixes including forward button on Fact the TV view

1.1.2

- Fixed autolayout issue
- Newsletter selection posting to cloud
- Fixed crash caused by reset timer

1.1.1

- Countdown Step interval changed to 1 second
- Hi res header and footer
- Stepping back from Select Picture screen doesn't cancel the session

1.1.0

Please Delete Prior Version before Installation.  This build comes with the up to date Database and configurable settings embedded within it.

- PPT4 - Insert Taking Pictures Now View into Workflow
- PPT5.4 - Thank You Sync and Reset
- Cloud Collected Email Operations View
- Kiosk Device ID embedded in Database (iOS7 fix)
- Watermarked Photo Backgrounds

1.0.19

- Uprated to stable based on Jan 24 post testing signoff confirming it can be used for events as is.  
- Addition of device to Apple Development Portal Provisioning Profile. Re-archive, distribution signing, and upload to TestFlight.

1.0.18

- Touch Panel
	- Significant memory management improvement.
	- View Controller rework to Nav Controller basis completed.  Various tweaks required.
	- Bad Access memory access violations traced to DCRoundButton.  Dropped when latest CocoaPods version had same issue.
	
1.0.17

- Camera
	- Huge improvement in GL Texture management.  Largest single improvement yet.
	- Frame rate raised up to 10
	- Resolution back to High (highest)

1.0.16

- Manual CameraViewController creation and reuse after finding the the StoryBoard mechanism was always creating new instances each session.
- Expanded use of Texture Cache major improvement on photo session overhead.
- Starting to moving frame rate back up, now to 4.

1.0.15

- Memory profiling work.  Various changes to session setup and teardown.  Logging entries to support troubleshooting.
- Additional reduction of frame rate.

1.0.14

- Fixed potential memory issue where capture input was not being released across multiple photo sessions.
- Changed capture quality preset to Photo from High for testing.

1.0.13

- Fix for blank 3rd image, caused by a slight timing / concurrency change due to a number of log entries being disabled.  Improved the overall robustness as the camera will never return to splash until receiving notification that the photo has been processed and saved.

1.0.12

- Frame rate locked at 5 for increased reliability.
- Default device mode on new installation is Camera for iPhone idiom.
- Error dialogs in certain places rather than log entries.  Not on camera though, assuming no touch access.

1.0.11

- Fix for custom Kiosk Splash overlay splash_kiosk.png file not being loaded.

1.0.10

- Back button on Taking Pictures view with modal reset to splash workflow.  Meant to be used in case this screen stalls when the session is interrupted such as by Camera manual reset / crash.  Tells the Camera to stop if it can.

1.0.9

- All 1.0 release modifications are in this build.
- PPT3 Rework of GetReady view controller into confirmation use case.
- PPT5.3 says "Picture 1 of 3" instead of "Taking Picture 1 of 3" due to real estate in portrait.

1.0.8

- PPT2.2 - Background Selection Idle Timeout
- Addition of “Interaction Timeout” setting, in units of minutes.  Accepts decimal minutes as well (ex: 2.5).
- App Icon for all hardware options
- Fixed structural issue where some modal views were stepping back in the storyboard modally as well, instead of closing and cleaning up.

1.0.7

- Change of App ID from old personal dev account to Touchlytic in support of Test Flight.  Jurassic not changed to iAmuse at this point as new build target creation and testing is required (1-2 hours).
- CocoaPods updates since July including iOS7 compatibility.
- Full screen mode translucent status bars hidden.
- Info plists updated for iOS7.  Missing constraints.  Resolution of layout constraint/frame enforcement.
- Storyboard upgrades and layout change for iOS7.
- Addition of splash_kiosk.png customizable Kiosk splash screen graphic asset.  Will automatically add this from the dist resource bundle if it doesn't already exist.
- Additional layouts, confirmed correct internal data, isolating issue to carousel.  Add synchronized code section and updates to carousel.