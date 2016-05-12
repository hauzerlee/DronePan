/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import DJISDK

import CocoaLumberjackSwift

class MainViewController: UIViewController {
    @IBOutlet weak var batteryLabel: UILabel!

    @IBOutlet weak var cameraView: UIView!

    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningOffset: NSLayoutConstraint!

    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoOffset: NSLayoutConstraint!

    @IBOutlet weak var sequenceLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var satelliteLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var acYawLabel: UILabel!
    @IBOutlet weak var gimbalYawLabel: UILabel!
    @IBOutlet weak var gimbalPitchLabel: UILabel!
    @IBOutlet weak var gimbalRollLabel: UILabel!

    @IBOutlet weak var connectionStatusLabel: UILabel!

    @IBOutlet weak var startButton: UIButton!

    @IBOutlet weak var panoProgressBar: UIProgressView!

    var rcInFMode = false

    var product: DJIBaseProduct?

    var connectionController: ConnectionController?
    var previewController: PreviewController?

    var batteryController: BatteryController?
    var panoramaController: PanoramaController?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewController = PreviewController()
        self.panoramaController = PanoramaController()
        self.panoramaController!.delegate = self

        hideWarning()

        if (infoOverride()) {
            showInfo()
        }

        /*
        // TODO: this should be tested
        #ifndef DEBUG
        [self.startButton setEnabled:NO];
    #endif
 */

        self.rcInFMode = false

        self.resetLabels()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        DDLogInfo("Showing main window")
        trackScreenView("MainViewController")

        self.previewController?.startWithView(self.cameraView)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        DDLogInfo("Hiding main window")

        self.previewController?.removeFromView()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.connectionController = ConnectionController()
        self.connectionController!.delegate = self
        self.connectionController!.start()

    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    func showWarning(text: String) {
        // TODO: this view should be a custom class that has a set of messages that rotate
        if (self.warningOffset.constant == 0) {
            dispatch_async(dispatch_get_main_queue()) {
                self.warningLabel.text = text

                self.scrollView(self.cameraView, toOffset: -self.warningView.frame.size.height, usingConstraint: self.warningOffset)
            }
        }
    }

    func hideWarning() {
        if (self.warningOffset.constant > 0) {
            dispatch_async(dispatch_get_main_queue()) {
                self.scrollView(self.cameraView, toOffset: 0, usingConstraint: self.warningOffset)
            }
        }
    }

    func showInfo() {
        if (self.infoOffset.constant == 0) {
            dispatch_async(dispatch_get_main_queue()) {
                self.scrollView(self.infoView, toOffset: -self.infoView.frame.size.height, usingConstraint: self.infoOffset)
            }
        }
    }

    func hideInfo() {
        if (!infoOverride()) {
            if (self.infoOffset.constant > 0) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.scrollView(self.infoView, toOffset: 0, usingConstraint: self.infoOffset)
                }
            }
        }
    }

    func scrollView(view: UIView, toOffset offset: CGFloat, usingConstraint constraint: NSLayoutConstraint) {
        constraint.constant = offset

        view.setNeedsUpdateConstraints()

        UIView.animateWithDuration(1) {
            view.layoutIfNeeded()
        }
    }

    func infoOverride() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("infoOverride")
    }

    func setSequence(current: Int? = nil, count: Int? = nil) {
        if let current = current, count = count {
            self.sequenceLabel.hidden = false
            self.sequenceLabel.text = "Photo: \(current)/\(count)"

            self.panoProgressBar.setProgress(Float(current) / Float(count), animated: true)
        } else {
            self.sequenceLabel.text = "Photo: -/-"

            self.panoProgressBar.setProgress(0, animated: false)
        }
    }

    func setAltitude(altitude: Int? = nil) {
        if let altitude = altitude {
            self.altitudeLabel.hidden = false
            self.altitudeLabel.text = "Alt: \(altitude)m"
        } else {
            self.altitudeLabel.text = "Alt: -"
        }
    }

    func setSatellites(satellites: Int? = nil) {
        if let satellites = satellites {
            self.satelliteLabel.hidden = false
            self.satelliteLabel.text = "Sats: \(satellites)"
        } else {
            self.satelliteLabel.text = "Sats: -"
        }
    }

    func setDistance(distance: Int? = nil) {
        if let distance = distance {
            self.distanceLabel.hidden = false
            self.distanceLabel.text = "Dist: \(distance)m"
        } else {
            self.distanceLabel.text = "Dist: -"
        }
    }

    func setBattery(batteryPercent: Int? = nil) {
        if let batteryPercent = batteryPercent {
            self.batteryLabel.hidden = false
            self.batteryLabel.text = "Batt: \(batteryPercent)%"
        } else {
            self.batteryLabel.text = "Batt: -"
        }
    }

    func resetLabels() {
        [self.sequenceLabel, self.batteryLabel, self.altitudeLabel, self.satelliteLabel, self.distanceLabel].forEach {
            (label) in
            label.hidden = true
        }

        setSequence()
        setAltitude()
        setSatellites()
        setDistance()
        setBattery()
    }

    func resetInfoLabels() {
        self.acYawLabel.text = "----"
        self.gimbalYawLabel.text = "----"
        self.gimbalPitchLabel.text = "----"
        self.gimbalRollLabel.text = "----"
    }

    @IBAction func startPanorama(sender: UIButton) {
        if let panoramaController = self.panoramaController {
            if (panoramaController.panoRunning) {
                DDLogInfo("Stopping pano from button")

                panoramaController.stop()
            } else {
                DDLogInfo("Starting pano from button")

                panoramaController.start()
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let settings = segue.destinationViewController as? SettingsViewController {
#if DEBUG
            if let model = self.panoramaController?.model, type = self.panoramaController?.type {
                settings.model = model
                settings.type = type
            } else {
                settings.model = "Simulator"
                settings.type = .Aircraft
            }
#else
            if let model = self.panoramaController?.model, type = self.panoramaController?.type {
                settings.model = model
                settings.type = type
            }
#endif
        }
    }
}

// MARK: - Connection Controller Delegate

extension MainViewController: ConnectionControllerDelegate {
    func sdkRegistered() {
        DDLogInfo("Registered")
    }

    func failedToRegister(reason: String) {
        DDLogWarn("Failed to register \(reason)")

        displayToastOnApp(reason)
    }

    func connectedToProduct(product: DJIBaseProduct) {
        DDLogInfo("New product \(product.model)")

        hideWarning()

        self.product = product

        self.previewController?.setMode(product)

        self.panoramaController?.product = product

        self.resetLabels()

        self.connectionStatusLabel.text = product.model

        self.startButton.enabled = true

        self.rcInFMode = false
    }

    func disconnected() {
        DDLogInfo("Disconnected")

        self.resetLabels()

        self.connectionStatusLabel.text = "Disconnected"

        self.startButton.enabled = false

        self.rcInFMode = false

        self.product = nil
        self.batteryController = nil

        self.panoramaController?.setFC(nil)
        self.panoramaController?.setCamera(nil)
        self.panoramaController?.setGimbal(nil)
        self.panoramaController?.setRemote(nil)
    }

    func connectedToBattery(battery: DJIBattery) {
        self.batteryController = BatteryController(battery: battery)
        self.batteryController!.delegate = self
    }

    func disconnectedFromBattery() {
        self.batteryController = nil
    }

    func connectedToCamera(camera: DJICamera) {
        self.panoramaController?.setCamera(camera, preview: self.previewController)
    }

    func disconnectedFromCamera() {
        self.panoramaController?.setCamera(nil)
    }

    func connectedToGimbal(gimbal: DJIGimbal) {
        self.panoramaController?.setGimbal(gimbal)
    }

    func disconnectedFromGimbal() {
        self.panoramaController?.setGimbal(nil)
    }

    func connectedToRemote(remote: DJIRemoteController) {
        self.panoramaController?.setRemote(remote)
    }

    func disconnectedFromRemote() {
        self.panoramaController?.setRemote(nil)
    }

    func connectedToFlightController(flightController: DJIFlightController) {
        self.panoramaController?.setFC(flightController)
    }

    func disconnectedFromFlightController() {
        self.panoramaController?.setFC(nil)
    }
}

// MARK: - Battery Controller Delegate

extension MainViewController: BatteryControllerDelegate {

    func batteryControllerPercentUpdated(batteryPercent: Int) {
        setBattery(batteryPercent)

        if (batteryPercent < 10) {
            showWarning("Battery Low: \(batteryPercent)%")
        }
    }

    func batteryControllerTemperatureUpdated(batteryTemperature: Int) {
        // TODO: Battery temperature
    }
}

// MARK: - Panorama Controller Delegate

extension MainViewController: PanoramaControllerDelegate {
    func postUserMessage(message: String) {
        displayToastOnApp(message)
    }

    func postUserWarning(warning: String) {
        showWarning(warning)
    }

    func panoStarting() {
        dispatch_async(dispatch_get_main_queue()) {
            self.startButton.setBackgroundImage(UIImage(named: "Stop"), forState: .Normal)
            self.panoProgressBar.setProgress(0, animated: false)

            if (!self.infoOverride()) {
                self.resetInfoLabels()

                self.scrollView(self.infoView, toOffset: -self.infoView.frame.size.height, usingConstraint: self.infoOffset)
            }

        }

    }

    func panoStopping() {
        dispatch_async(dispatch_get_main_queue()) {
            self.startButton.setBackgroundImage(UIImage(named: "Start"), forState: .Normal)
            self.panoProgressBar.setProgress(0, animated: false)

            if (!self.infoOverride()) {
                self.resetInfoLabels()

                self.scrollView(self.infoView, toOffset: 0, usingConstraint: self.infoOffset)
            }
        }
    }

    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.gimbalPitchLabel.text = String(format: "%.1f˚", pitch)
            self.gimbalYawLabel.text = String(format: "%.1f˚", yaw)
            self.gimbalRollLabel.text = String(format: "%.1f˚", roll)
        }
    }

    func aircraftYawChanged(yaw: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.acYawLabel.text = String(format: "%.1f˚", yaw)
        }
    }

    func aircraftSatellitesChanged(count: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setSatellites(count)
        }
    }

    func aircraftAltitudeChanged(altitude: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setAltitude(Int(altitude))
        }
    }

    func aircraftDistanceChanged(distance: CLLocationDistance) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setDistance(Int(distance))
        }
    }

    func panoCountChanged(count: Int, total: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setSequence(count, count: total)
        }
    }

    func panoAvailable(available: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.startButton.enabled = available
        }
    }
}
