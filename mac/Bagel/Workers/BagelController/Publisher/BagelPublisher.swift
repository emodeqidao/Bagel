//
//  BagelPublisher.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 26.09.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import CocoaAsyncSocket

protocol BagelPublisherDelegate {
    
    func didGetPacket(publisher: BagelPublisher, packet: BagelPacket)
}

class BagelPublisher: NSObject {
    var delegate: BagelPublisherDelegate?
    var isOnly: Bool = true
    var filterHost: [String] = []
    var mainSocket: GCDAsyncSocket!
    var sockets: [GCDAsyncSocket] = []
    var netService: NetService!
    
    
    func startPublishing() {
        
        self.sockets = []
    
        self.mainSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .background))

        do {
            try self.mainSocket.accept(onPort: UInt16(BagelConfiguration.netServicePort))
            
            self.sockets.append(self.mainSocket)
            
            self.netService = NetService(domain: BagelConfiguration.netServiceDomain, type: BagelConfiguration.netServiceType, name: BagelConfiguration.netServiceName, port: BagelConfiguration.netServicePort)
            self.netService.delegate = self
            self.netService.publish()
            
        } catch {
            self.tryPublishAgain()
        }
        
    }

    
    func lengthOf(data: Data) -> Int {
        
        var length = 0
        memcpy(&length, ([UInt8](data)), MemoryLayout<UInt64>.stride)

        return length
    }
    
    func parseBody(data: Data) {
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            
            let bagelPacket = try jsonDecoder.decode(BagelPacket.self, from: data)
            
            DispatchQueue.main.async {
                print(bagelPacket.device?.deviceName ?? "", bagelPacket.device?.deviceId ?? "", bagelPacket.device?.deviceDescription ?? "")
                self.delegate?.didGetPacket(publisher: self, packet: bagelPacket)
            }
            
        } catch {
            
            print(error)
        }
    }
}


extension BagelPublisher: NetServiceDelegate {
    
    func netServiceDidPublish(_ sender: NetService) {
        
        print("publish", sender)
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        
        print("error", errorDict)
    }

}


extension BagelPublisher: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        self.sockets.append(newSocket)
        newSocket.delegate = self
        newSocket.readData(toLength: UInt(MemoryLayout<UInt64>.stride), withTimeout: -1.0, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        if tag == 0 {
            print("tag = 0")
            let length = self.lengthOf(data: data)
            sock.readData(toLength: UInt(length), withTimeout: -1.0, tag: 1)
            
        } else if tag == 1 {
            print("tag = 1")
            if (isOnly) {
                print("仅自己")
                print("一共有： \(self.filterHost)")
                let connectHost = sock.connectedHost ?? ""
                if (self.filterHost.contains(connectHost)) {
                    print("符合条件：\(connectHost)")
                    self.parseBody(data: data)
                    sock.readData(toLength: UInt(MemoryLayout<UInt64>.stride), withTimeout: -1.0, tag: 0)
                } else {
                    print("条件不符合 \(connectHost)")
                }
            } else {
                print("所有都接收")
                self.parseBody(data: data)
                sock.readData(toLength: UInt(MemoryLayout<UInt64>.stride), withTimeout: -1.0, tag: 0)
            }
        }
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        
        if self.sockets.contains(sock) {
            print("有socket 断开了")
            sock.delegate = nil
            
            self.sockets = Array(self.sockets.filter { $0 !== sock })
            
            if self.sockets.count == 0 {
                
                self.tryPublishAgain()
                
            }
        }
    }
    
    func tryPublishAgain() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            self.startPublishing()
            
        }
        
    }
}
