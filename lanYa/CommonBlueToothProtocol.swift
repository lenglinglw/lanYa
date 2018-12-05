//
//  CommonBlueToothProtocol.swift
//  lanYa
//
//  Created by lixcx on 2018/11/20.
//  Copyright © 2018 lixcx.sq. All rights reserved.
//

import Foundation

enum SendInfomationOrderCode: String {
    
    case SendInfomatioOfCommonProtocol      = "10" //平台通用应答,无回复
    case SendInfomationOfStartCharing       = "11" //开始充电指令,回复 "40"
    case SendInfomationOfEndCharing         = "12" //停止充电
    case SendInfomationOfCommonControl      = "13" //通用控制指令
    case SendInfomationOfCheckCharingStatus = "14" //查询充电状态
    case SendInfomationOfCheckBTStatus      = "15" //查询终端状态
//    case SendBlueToothInfomationOfBTDeploy        = "16" //终端配置指令
//    case SendBlueToothInfomationOf
    case SendInfomationOfBTICheck           = "32" //查询蓝牙设备信息
    
}

enum ResponseInfomationOrderCode: String {

    case ResponseInfomationCommonProtocol   = "40" // 服务端通用应答
    case ResponseInfomationTCInfo           = "61" //透传
    case ResponseInfomationBTDeviceInfo     = "62" //查询蓝牙设备信息的应答
    
}

//判断头
func judgeInfomationOrderCode(bytes: Array<UInt8>) {
    
    //判断最短长度
    if bytes.count < 14 {
        
        return
        
    }
    
    if CRC_Check(bytes, UInt16(bytes.count)) != 0 {
        
        print("crc校验未通过")
        return
        
    }
    
    var strBytes: [String] = []
    for i in 0 ..< bytes.count {
        
        strBytes += [String(bytes[i], radix: 16)] //进制转化
        
    }
    print("\(strBytes)")
    // 筛选信息头
//    let orderCode: ResponseInfomationOrderCode = ResponseInfomationOrderCode(rawValue: strBytes[0])!  // 指令码
    let orderCode = strBytes[0]
    
    let flowingWaterCode = strBytes[1] + strBytes[2]  //流水号
    var deiveCodeStr: String? = nil //编码
    for i in 3 ..< 12 {
        
        if deiveCodeStr == nil {
            
            deiveCodeStr = strBytes[i]
            
        } else {
            
            deiveCodeStr = strBytes[i] + deiveCodeStr!
            
        }
        
    }
    strBytes.removeSubrange(Range(0...11))
    if orderCode == "40" { // 服务端通用应答
        
        
    } else if orderCode == "61" { //透传
        
        
    } else if orderCode == "62" { //查询蓝牙设备信息的应答
        
        analysisBTDeviceInfo(strBytes)
        
    }
    
}

// 解析 查询蓝牙设备信息
func analysisBTDeviceInfo(_ bytes: Array<String>) {
    
    
    if bytes.count < 68 {
        
        print("数据格式有误")
        return
        
    }
    
    if (bytes.count - 68)%6 != 0 {
        
        print("数据格式有误")
        return
        
    }
    
    var responseId:       String = "" // 以应答消息ID
    var deviceStatusCode: String = "" // 设备状态
    var deviceTypeCode:   String = "" // 类型配置
    var moneyTypeId:      String = "" // 计价配置Id
    
    //消息体
    for (index, value) in bytes.enumerated() {
        
        if index == 0 || index == 1 {
            responseId += String(format: "%02@", value)
            continue
        } else if index > 1 && index < 19 {
            deviceStatusCode += String(format: "%02@", value)
            continue
        } else if index > 18 && index < 35 {
            deviceTypeCode += String(format: "%02@", value)
        } else if index > 34 && index < 51 {
            deviceTypeCode += String(format: "%02@", value)
        } else if index > 50 && index < 67 {
            moneyTypeId    += String(format: "%02@", value)
        }
        
    }
    
    var moneyArr: Array<String> = bytes
    moneyArr.removeSubrange(Range(0 ... 65))
    moneyArr.removeSubrange(Range(moneyArr.count - 2 ... moneyArr.count - 1))
    let dictCount = moneyArr.count / 6
    var moneyRuleArr: Array<Dictionary<String, Any>> = []
    
    for i in 1 ..< dictCount {
        var dict: Dictionary<String,Any> = [:]
        dict["money"] = moneyArr[i * 6]
        dict["time"]  = moneyArr[i * 6 + 1] + moneyArr[i * 6 + 2]
        dict["fastMoney"] = moneyArr[i * 6 + 3]
        dict["fastTime"]  = moneyArr[i * 6 + 4] + moneyArr[i * 6 + 5]
        moneyRuleArr.append(dict)
    }
    print("成功")
}


// 发送充电状态查询
func ceshi(orderCode: String, flowingWaterCode: String, deiveCode: String, batteryBoxSocketCode: String, otherCode: String) ->Array<UInt8> {
    
    var arr: Array<UInt8> = []
    
//    arr?.append(orderCode)
//    let orderCode = orderCode //消息头
    var code: String = ""
    for i in (orderCode + flowingWaterCode + deiveCode + batteryBoxSocketCode + otherCode) {

        code += String(i)
        if code.count == 2 {
            arr.append(hexTodec(number: code))
            code = ""
        }
    }
    let aaa: UInt16 = CRC_Check(arr, UInt16(arr.count))
//    CRC16(arr, Int32(arr!.count), &aaa)
    let bbb = String(aaa, radix: 16)
    //        sum(1,2)
    for i in bbb {
        
        code += String(i)
        if code.count == 2 {
            arr.append(hexTodec(number: code))
            code = ""
        }
        
    }
    return arr
    
}

// MARK: - 十六进制转十进制
func hexTodec(number num:String) -> UInt8 {
    let str = num.uppercased()
    var sum = 0
    for i in str.utf8 {
        sum = sum * 16 + Int(i) - 48 // 0-9 从48开始
        if i >= 65 {                 // A-Z 从65开始，但有初始值10，所以应该是减去55
            sum -= 7
        }
    }
    return UInt8(sum)
}

