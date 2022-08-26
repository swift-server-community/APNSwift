import CoreLocation

final class LocationPushService: NSObject, CLLocationPushServiceExtension, CLLocationManagerDelegate {
    var completion: (() -> Void)?
    var locationManager: CLLocationManager?

    func didReceiveLocationPushPayload(_ payload: [String: Any], completion: @escaping () -> Void) {
        self.completion = completion
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.locationManager!.requestLocation()
    }

    func serviceExtensionWillTerminate() {
        self.completion?()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.completion?()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completion?()
    }
}
