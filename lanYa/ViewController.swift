//
//  ViewController.swift
//  lanYa
//
//  Created by lixcx on 2018/11/15.
//  Copyright © 2018 lixcx.sq. All rights reserved.
//

import UIKit
import CoreBluetooth
import CryptoSwift

// 特征的uuid CHARACTERISTIC_UUID
let CHARACTERISTIC_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb"
// 服务的uuid
let Service_UUID = "0000ffe0-0000-1000-8000-00805f9b34fb"
// 开启线程
let queue = DispatchQueue.global()
// 存储数据
var dataArray: [UInt8] = []
// 定时器
var timerDouble: Double = Double(0.0)
var timer: Timer? = nil
var fristOpen: Int = 0

//
let key = "AF55C676D79800A2"
let iv = ""

class ViewController: UIViewController {
    
    
    static let salt = "DEgdrgadfsfasdbadrggasdfgosnt"
    
    @IBOutlet weak var btn: UIButton!
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic? = nil
    var arr: Array<UInt8>? = []
    var lab = UILabel.init()
    var encrypted: [UInt8] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        lab.frame = CGRect(x: 40, y: 40, width: 100, height: 300)
        self.view.addSubview(lab)
        arr = ceshi(orderCode: "32", flowingWaterCode: "0004", deiveCode: "123456782435465489", batteryBoxSocketCode: "", otherCode: "")
        
//        print("arr:\(arr)")
//        lanYaFuncation()
        aesAndECB()
        aesDecrypt()
    }
    
    //蓝牙
    func lanYaFuncation() {
        
            centralManager = CBCentralManager.init(delegate: self, queue: .main)
        
    }
    
    // aes/ecb/PKCS5 加密
    func aesAndECB() {
        
        do {
//            encrypted = try AES(key: key, iv: iv, blockMode: .ECB, padding: PKCS7()).encrypt(arr)
//            加密前数据
            print("加密前数据:\(arr!)")
            //加密
            encrypted = try AES(key: key.bytes, blockMode: ECB.init(), padding: .pkcs5).encrypt(arr!)
            print("加密后数据: \(encrypted)")
            
        } catch {
        }
    }
    
    func aesDecrypt() {
        
        do {
            
            //解密
            let decrypted = try AES(key: key.bytes, blockMode: ECB.init(), padding: .pkcs5).decrypt(encrypted)
            print("解密后数据:\(decrypted)")
            
        } catch {
            print("解密报错")
            
        }
        
        
    }
    
    func someFunctionThatTakesAClosure(closure: (Int?) -> Void) {
        // 函数体部分
        closure(0)
    }
    
    
    @IBAction func btn(_ sender: UIButton) {
        
//        dataArray.removeAll()
        self.peripheral?.writeValue(Data(bytes: arr!), for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
            //        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.TimerStart), userInfo: nil, repeats: true)
            //        timer?.fire()
//            sender.isEnabled = false

    }
    
}
extension ViewController: CBCentralManagerDelegate {
    
    // 判断手机蓝牙的状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .unknown:
            print("未知的")
        case .resetting:
            print("重置中")
        case .unsupported:
            print("不支持")
        case .unauthorized:
            print("未验证")
        case .poweredOff:
            print("未启动")
        case .poweredOn:
            print("可用")
//[CBUUID.init(string: Service_UUID)]
            central.scanForPeripherals(withServices: nil, options: nil)
            
        }
    }
    
    // 发现符合要求的外设
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil {

            print("\(peripheral.name)")

            if peripheral.name == "JDY-08" {

                self.peripheral = peripheral
                print("rssi :\(peripheral)")
                centralManager?.connect(self.peripheral!, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
//                perform(#selector(closeConnect), with: nil, afterDelay: 5.0)

            }

        }
        
    }
    // 链接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("链接成功")
        //链接上停止扫描 省电
        self.centralManager?.stopScan()
        //链接外设代理，根据外设的uuid
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID.init(string: Service_UUID)])
        
    }
    
    /** 连接失败的回调 */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败")
    }
    
    /** 断开连接 */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("断开连接")
        // 重新连接
        central.connect(peripheral, options: nil)
        
    }
    
}

extension ViewController: CBPeripheralDelegate {
    
    /** 发现服务 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service: CBService in peripheral.services! {
            print("外设中的服务有：\(service)")
        }
        //本例的外设中只有一个服务
        let service = peripheral.services?.last
        // 根据UUID寻找服务中的特征
        peripheral.discoverCharacteristics([CBUUID.init(string: CHARACTERISTIC_UUID)], for: service!)
    }
    
    /** 发现特征 */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic: CBCharacteristic in service.characteristics! {
            print("外设中的特征有：\(characteristic)")
        }
        
        self.characteristic = service.characteristics?.last
        // 读取特征里的数据
        peripheral.readValue(for: self.characteristic!)
        // 订阅
        peripheral.setNotifyValue(true, for: self.characteristic!)
    }
    
    /** 订阅状态 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("订阅失败: \(error)")
            return
        }
        if characteristic.isNotifying {
            print("订阅成功")
        } else {
            print("取消订阅")
        }
    }
    
    /** 接收到数据 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
//        if timerDouble > Double(0.2) && timerDouble == 0.2 {
//
//            return
//
//        }
        if fristOpen == 0 {
            
            fristOpen = 1
            return
            
        }
        if timerDouble == Double(0.0) {

            if dataArray.count == 0 {

                timer = Timer.scheduledTimer(timeInterval: 0.005, target: self, selector: #selector(self.TimerStart), userInfo: nil, repeats: true)
                timer?.fire()

            }

        }

        if timerDouble < Double(0.3) && timerDouble > 0 {

            print("timerDouble:\(timerDouble),刷新定时器秒数")
            timerDouble = 0.0

        }
        let bytes = [UInt8](characteristic.value!)
        dataArray += bytes
        print("接收到字节长度:\(bytes.count),内容:\(bytes)")
        print("数据总长度:\(dataArray.count)")
//        queue.async {
//
//
//
//        }


        
        
    }
    
    @objc func closeConnect() {
        
//        centralManager?.cancelPeripheralConnection(peripheral!)
        
    }
    
    //MARK: 定时器开关
    @objc func TimerStart() {
//
        timerDouble += 0.005
        print("\(timerDouble)")
        if timerDouble > 0.3 || timerDouble == 0.3 {
            
            if timer != nil {
                timer!.invalidate() //销毁timer
                timer = nil
                btn.isEnabled = true
            }

            timerDouble = 0
            print("bytes:\(dataArray.count)")
            judgeInfomationOrderCode(bytes: dataArray)
            dataArray.removeAll()

        }
        
        
    }
    
}
