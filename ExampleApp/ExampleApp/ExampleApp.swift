import CoreLocation
import PushKit
import SwiftUI
import UIKit

@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @AppStorage("background-push") var receivedBackgroundPush: Bool = false
    @AppStorage("voip-push") var receivedVoIPPush: Bool = false

    var body: some Scene {
        WindowGroup {
            Text("Hello, world!")
                .padding()
                .onAppear {
                    print("Appeared")
                }

            if UIApplication.shared.applicationIconBadgeNumber != 0 {
                VStack {
                    Button("Clear badge") {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                }
            }

            if receivedBackgroundPush {
                VStack {
                    Text("Received background push")
                    Button("Reset background push storage") {
                        self.receivedBackgroundPush = false
                    }
                }
            }
            if receivedVoIPPush {
                VStack {
                    Text("Received VoIP push")
                    Button("Reset VoIP push storage") {
                        self.receivedVoIPPush = false
                    }
                }
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var voipRegistry: PKPushRegistry!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { _, _ in }
        )

        // Register for push notifications
        application.registerForRemoteNotifications()
        self.registerNotificationCategories()

        // Register for location update notifications
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        Task {
            do {
                let deviceToken = try await locationManager.startMonitoringLocationPushes()
                print("Location token: \(deviceToken.asHexString)")
            } catch {
                print("Failed to start monitoring location pushes \(error)")
            }
        }

        // Register for VoIP notifications
        self.voipRegistry = PKPushRegistry(queue: nil)
        self.voipRegistry.delegate = self
        self.voipRegistry.desiredPushTypes = [.voIP]

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Device token: \(deviceToken.asHexString)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        UserDefaults.standard.set(true, forKey: "background-push")
        completionHandler(.newData)
    }
}

extension AppDelegate {
    private func registerNotificationCategories() {
        let customAction = UNNotificationAction(
            identifier: "CUSTOM_ACTION",
            title: "Custom",
            options: []
        )
        let customCategory = UNNotificationCategory(
            identifier: "CUSTOM",
            actions: [customAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: .customDismissAction
        )
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([customCategory])
    }
}

extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("Credentials for \(type): \(pushCredentials.token.asHexString)")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) async {
        UserDefaults.standard.set(true, forKey: "voip-push")
    }
}

extension Data {
    // Convenience method to convert `Data` to a hex `String`.
    fileprivate var asHexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
