//
//  ViewController.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 30/07/2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import macOSThemeKit

class ViewController: NSViewController, NSTextFieldDelegate {

    var projectsViewController: ProjectsViewController?
    var devicesViewController: DevicesViewController?
    var packetsViewController: PacketsViewController?
    var detailVeiwController: DetailViewController?
    
    @IBOutlet weak var projectsBackgroundBox: NSBox!
    @IBOutlet weak var devicesBackgroundBox: NSBox!
    @IBOutlet weak var packetsBackgroundBox: NSBox!
    @IBOutlet weak var checkBox: NSButtonCell!
    @IBOutlet weak var ipTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = BagelController.shared
        
        self.projectsBackgroundBox.fillColor = ThemeColor.projectListBackgroundColor
        self.devicesBackgroundBox.fillColor = ThemeColor.deviceListBackgroundColor
        self.packetsBackgroundBox.fillColor = ThemeColor.packetListAndDetailBackgroundColor
        
        
        let isOnlyMe = UserDefaults.standard.bool(forKey: "isOnlyMe")

        if (isOnlyMe) {
            self.checkBox.state = NSControl.StateValue.on
        } else {
            self.checkBox.state = NSControl.StateValue.off
        }
    
        self.ipTextField.delegate = self
        let ipStr = UserDefaults.standard.string(forKey: "IP")
        self.ipTextField.stringValue = ipStr ?? ""
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {

        if let destinationVC = segue.destinationController as? ProjectsViewController {
            
            self.projectsViewController = destinationVC
            self.projectsViewController?.viewModel = ProjectsViewModel()
            self.projectsViewController?.viewModel?.register()
            
            self.projectsViewController?.onProjectSelect = { (selectedProjectController) in
                
                BagelController.shared.selectedProjectController = selectedProjectController
            }
            
        }
        

        if let destinationVC = segue.destinationController as? DevicesViewController {
            
            self.devicesViewController = destinationVC
            self.devicesViewController?.viewModel = DevicesViewModel()
            self.devicesViewController?.viewModel?.register()
            
            self.devicesViewController?.onDeviceSelect = { (selectedDeviceController) in
                
                BagelController.shared.selectedProjectController?.selectedDeviceController = selectedDeviceController
            }
            
        }
        

        if let destinationVC = segue.destinationController as? PacketsViewController {
            
            self.packetsViewController = destinationVC
            self.packetsViewController?.viewModel = PacketsViewModel()
            self.packetsViewController?.viewModel?.register()
            
            self.packetsViewController?.onPacketSelect = { (selectedPacket) in
            BagelController.shared.selectedProjectController?.selectedDeviceController?.select(packet: selectedPacket)
            }
            
        }
        

        if let destinationVC = segue.destinationController as? DetailViewController {
            
            self.detailVeiwController = destinationVC
            self.detailVeiwController?.viewModel = DetailViewModel()
            self.detailVeiwController?.viewModel?.register()
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    @IBAction func checkBoxAction(_ sender: NSButtonCell) {
        print("click \(self.checkBox.state.rawValue)");
        var isSelect :Bool;
        if (self.checkBox.state.rawValue == 1) {
            isSelect = true
        } else {
            isSelect = false
        }
        UserDefaults.standard.set(isSelect, forKey: "isOnlyMe")
        UserDefaults.standard.set(self.ipTextField.stringValue, forKey: "IP")
        projectsViewController?.reSet()
        devicesViewController?.reSet()
        packetsViewController?.reSet()
        BagelController.shared.reConnect(isOnly: isSelect);
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        print("candidatesForSelectedRange" + textField.stringValue)
        UserDefaults.standard.set(textField.stringValue, forKey: "IP")
        return []
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange selectedRange: NSRange) -> [NSTextCheckingResult] {
        print("forSelectedRange")
        return [];
    }

    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        print("shouldSelectCandidateAt")
        return true;
    }

}

