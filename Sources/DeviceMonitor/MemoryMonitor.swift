

import MachO
import Foundation

public struct DMMemoryUsageReport {
    let bytesUsed: Int
    
    var megabytesUsed: Double {
        return Double(bytesUsed) / (1024 * 1024)
    }
}

public enum DeviceMonitoringRetrieveError: Error {
    case MemoryReadingError
    case CPULoadReadingError
}

public class DMMemoryMonitor {
    
    public func getMemoryUsage() throws -> DMMemoryUsageReport {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return DMMemoryUsageReport(bytesUsed: Int(info.resident_size))
        } else {
            throw DeviceMonitoringRetrieveError.MemoryReadingError
        }
    }
}


