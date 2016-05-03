# ios-geotification-demo
Demo to show notifications based on user location

* **geofence-notifications** branch shows how to display a notification using geofences (<a href="https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html">region monitoring</a>).
* **location-based-notifications** branch shows how to display a notification using <a href="https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html#//apple_ref/doc/uid/TP40008194-CH103-SW37">iOS8 Location Based Notifications</a>.

Demo project is based on the following tutorial: http://www.raywenderlich.com/95014/geofencing-ios-swift

Tip: Using the simulator, set the Location to "Apple", create a Geotification, then switch to a custom location (e.g. lat=30.327014, long=-122.031027) to test entering/exiting to the regions. You can also test this by killing the application.

To clone this repository use:

```git clone git@github.com:fernandospr/ios-geotification-demo.git -b geofence-notifications```

To switch branch:

```git checkout location-based-notifications```

```git pull origin location-based-notifications```
