//
//  CPUMonitor.swift
//  
//
//  Created by Branimir Markovic on 14.12.23..
//

import Foundation

@propertyWrapper
struct TwoDecimalsRounded {
    private var value: Float
    var wrappedValue: Float {
        get { value }
        set { value = (newValue * 100).rounded() / 100 }
    }

    init(wrappedValue: Float) {
        self.value = (wrappedValue * 100).rounded() / 100
    }
}

public struct DMCPUUsage {
    @TwoDecimalsRounded var user: Float
    @TwoDecimalsRounded var system: Float
    @TwoDecimalsRounded var idle: Float
    @TwoDecimalsRounded var nice: Float
    
    var description: String {
        """
CPU Usage:
User: \(user * 100)%
System: \(system * 100)%
Idle: \(idle * 100)%
Nice: \(nice * 100)%
"""
    }
}

public class DMCPUMonitor {

    public func getCPUUsage() throws -> DMCPUUsage {
        var cpuLoad = [Float](repeating: 0.0, count: 4)
        var numCPUsU = uint(0)
        var numCPUs = Int32(0)
        var hostInfo = host_basic_info()
        var size = mach_msg_type_number_t(MemoryLayout<host_basic_info>.stride) / 4
        let host = mach_host_self()
        
        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_info(host, HOST_BASIC_INFO, $0, &size)
            }
        }

        if result != KERN_SUCCESS {
            throw DeviceMonitoringRetrieveError.CPULoadReadingError
        }

        numCPUs = Int32(hostInfo.max_cpus)
        var cpuInfo: processor_info_array_t!
        var cpuInfoSize = mach_msg_type_number_t(0)

        let status = host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &cpuInfoSize)

        if status != KERN_SUCCESS {
            throw DeviceMonitoringRetrieveError.CPULoadReadingError
        }

        for i in 0 ..< Int(numCPUs) {
            let inUse = Float(cpuInfo[Int(CPU_STATE_USER) + i * Int(CPU_STATE_MAX)]) +
            Float(cpuInfo[Int(CPU_STATE_SYSTEM) + i * Int(CPU_STATE_MAX)])
            let total = inUse + Float(cpuInfo[Int(CPU_STATE_IDLE) + i * Int(CPU_STATE_MAX)]) +
            Float(cpuInfo[Int(CPU_STATE_NICE) + i * Int(CPU_STATE_MAX)])
            cpuLoad[0] += inUse / total
            cpuLoad[1] += Float(cpuInfo[Int(CPU_STATE_SYSTEM) + i * Int(CPU_STATE_MAX)]) / total
            cpuLoad[2] += Float(cpuInfo[Int(CPU_STATE_IDLE) + i * Int(CPU_STATE_MAX)]) / total
            cpuLoad[3] += Float(cpuInfo[Int(CPU_STATE_NICE) + i * Int(CPU_STATE_MAX)]) / total
        }
        
        cpuLoad = cpuLoad.map { $0 / Float(numCPUs) }
        
        let usage = DMCPUUsage(user: cpuLoad[0], system: cpuLoad[1], idle: cpuLoad[2], nice: cpuLoad[3])
        return usage
    }
}

