import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Don't backup the documents directory with all the repository data
        var docUrl:URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
        do {
            try docUrl.setResourceValues(resourceValues)
        } catch _ as NSError {
            print("Could not exclude documents directory from backup")
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    
}
