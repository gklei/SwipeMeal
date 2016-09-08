//
//  CreateStripeAccountOperation.swift
//  SwipeMeal
//
//  Created by Gregory Klein on 9/8/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import UIKit
import SwiftSpinner

// Return IP address of WiFi interface (en0) as a String, or `nil`
func getWiFiAddress() -> String? {
	var address : String?
	
	// Get list of all interfaces on the local machine:
	var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
	if getifaddrs(&ifaddr) == 0 {
		
		// For each interface ...
		var ptr = ifaddr
		while ptr != nil {
			defer { ptr = ptr.memory.ifa_next }
			
			let interface = ptr.memory
			
			// Check for IPv4 or IPv6 interface:
			let addrFamily = interface.ifa_addr.memory.sa_family
			if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
				
				// Check interface name:
				if let name = String.fromCString(interface.ifa_name) where name == "en0" {
					
					// Convert interface address to a human readable string:
					var addr = interface.ifa_addr.memory
					var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
					getnameinfo(&addr, socklen_t(interface.ifa_addr.memory.sa_len),
					            &hostname, socklen_t(hostname.count),
					            nil, socklen_t(0), NI_NUMERICHOST)
					address = String.fromCString(hostname)
				}
			}
		}
		freeifaddrs(ifaddr)
	}
	
	return address
}

class CreateStripeAccountOperation: BaseOperation {
	
	let _user: SwipeMealUser
	
	init(user: SwipeMealUser) {
		_user = user
		super.init()
	}
	
	override func execute() {
		guard let email = _user.email, ipAddress = getWiFiAddress() else {
			finish()
			return
		}
		
		SwiftSpinner.show("Creating Stripe Account...")
		let service = StripePaymentService.sharedPaymentService()
		
		print("creating account for: \(email), with ipAddress: \(ipAddress)")
		service.createCustomerWithUserID(_user.uid, email: email, ipAddress: ipAddress) { (info, error) in
			if error != nil {
				self.error = error
			}
			
			SwiftSpinner.hide()
			self.finish()
		}
	}
}
