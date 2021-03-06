//
//  InterfaceController.swift
//  BiologicalInfo WatchKit Extension
//
//  Created by Mika Miyakawa on 2021/03/03.
//

import WatchKit
import Foundation
import HealthKit


class InterfaceController: WKInterfaceController{

    @IBOutlet weak var labelHeartLatest: WKInterfaceLabel!
    let fontSize = UIFont.systemFont(ofSize: 80)
    var heartRateLatest: Double = 0.0 {
            didSet {
                if self.heartRateLatest < 0.0 {
                    labelHeartLatest.setText("最新 : ----")
                } else {
                    labelHeartLatest.setText("最新 : \(self.heartRateLatest)")
                }
            }
        }
    var dateWorkoutSessionStart: Date?
    var dateWorkoutSessionEnd: Date?
    var workoutSession: HKWorkoutSession?
    // HealthKit 関連データ
    let healthStore = HKHealthStore()
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let heartRateUnit = HKUnit(from: "count/min")
    var heartRateQuery: HKQuery?
 
    // 定周期処理
    var timerReadHK: Timer?
    let timerIntervalReadHK = 5.0
    
    @IBAction func switchActionWorkoutStatus(_ value: Bool) {
        if (value) {
            // WorkoutSession開始
            let config = HKWorkoutConfiguration()
            config.activityType = .other
            do {
                self.workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
                self.workoutSession?.delegate = self
                self.workoutSession?.startActivity(with: nil)
            }
            catch let e {
                print(e)
            }
        } else {
            // WorkoutSession終了
            self.workoutSession?.stopActivity(with: nil)
            //self.dateWorkoutSessionEnd = Date()
        }
    }
    
    
    func requestAuthorization(
            toShare typesToShare: Set<HKSampleType>?,
            read typesToRead: Set<HKObjectType>?,
        completion: @escaping (Bool, Error?) -> Void){}
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
//        // HealthKit関連初期化処理
//        //   ※HealthKit を使用できる場合のみ表示する
//        if (HKHealthStore.isHealthDataAvailable()) {
//            // HealthKit の使用許可ダイアログの表示
//            let readTypes: Set<HKObjectType> = [self.hkTypeHeartRate]
//            self.hkStore.requestAuthorization(toShare: nil, read: readTypes, completion: {(success, error) -> Void in
//                if success {
//                    NSLog("HealthKit Request Authorization succeeded")
//                    self.hkIsAuthorized = true
//                } else if let error = error {
//                    NSLog("HealthKit Request Authorization error \(error)")
//                } else {
//                    NSLog("HealthKit Request Authorization error")
//                }
//            })
//
//            // HealthKit定周期読み出し開始
//            self.startReadHK()
//        }
    }
    // HealthKit データ読み出しの開始
//    func startReadHK() {
//        self.timerReadHK = Timer.scheduledTimer(timeInterval: self.timerIntervalReadHK, target: self, selector: #selector(self.timerHandlerReadHK), userInfo: nil, repeats: true)
//    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
}

extension InterfaceController {

    private func createStreamingQuery() -> HKQuery {
        print(#function)
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: [])
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) in
            self.addSamples(samples: samples)
        }
        query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
            self.addSamples(samples: samples)
        }
        return query
    }

    private func addSamples(samples: [HKSample]?) {
        print(#function)
        guard let samples = samples as? [HKQuantitySample] else { return }
        guard let quantity = samples.last?.quantity else { return }

        let text = String(quantity.doubleValue(for: self.heartRateUnit))
//        print(text)
        let attrStr = NSAttributedString(string: text, attributes:[NSAttributedString.Key.font:self.fontSize])
        DispatchQueue.main.async {
            //self.label.setAttributedText(attrStr)
            self.labelHeartLatest.setText("最新 : \(attrStr)")
        }
    }
}

extension InterfaceController: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print(#function)
        switch toState {
        case .running:
            print("Session status to running")
            self.startQuery()
        case .stopped:
            print("Session status to stopped")
            self.stopQuery()
            self.workoutSession?.end()
        case .ended:
            print("Session status to ended")
            self.workoutSession = nil
        default:
            print("Other status \(toState.rawValue)")
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workoutSession delegate didFailWithError \(error.localizedDescription)")
    }

    func startQuery() {
        print(#function)
        heartRateQuery = self.createStreamingQuery()
        healthStore.execute(self.heartRateQuery!)
        DispatchQueue.main.async {
            //self.button.setTitle("Stop")
        }
    }

    func stopQuery() {
        print(#function)
        healthStore.stop(self.heartRateQuery!)
        heartRateQuery = nil
        DispatchQueue.main.async {
//            self.button.setTitle("Start")
//            self.label.setText("")
        }
    }
}
