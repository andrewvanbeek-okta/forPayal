
//
//  Created by Andrew Vanbeek 
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import UIKit
import Eureka
import OktaOidc
import LocalAuthentication
import KeychainAccess
import SwiftyJSON

class EurekaSimpleViewController: FormViewController {
    
    struct FormItems {
        static let name = "name"
        static let firstname = "firstname"
        static let lastname = "lastname"
        static let email = "email"
    }
    
    
    
    let alert = UIAlertController(title: nil, message: "Loading Profile", preferredStyle: .alert)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let keychain = self.getKeyChain()
        print(keychain["faceid"] as Any)
        let config = self.getConfig()
        let oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            // unauthenticated
            return
        }
        stateManager.getUser { response, error in
            if error != nil {
                // Error
                return
            }
            print(response as Any)
            DispatchQueue.main.async {
                let responseObject = JSON(response)
                var userInfo = responseObject.dictionaryValue
                let keys = Array(userInfo.keys)
                let section = Section()
                var header = HeaderFooterView<UIView>(.class)
                header.height = {300}
                header.onSetupView = { view, _ in
                    let width = view.frame.width
                    let height = view.frame.height
                    let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
                    imageViewBackground.image = UIImage(named: "vanbeeklabsforaws.png")
                    imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill
                    view.addSubview(imageViewBackground)
                    view.sendSubview(toBack: imageViewBackground)
                }
                section.header = header
                self.form +++
                section
                keys.forEach { item in
                    section <<< TextRow(item) {
                        $0.title = item
                        $0.value = userInfo[item]?.rawString()
                    }
                }
                section <<< SwitchRow("SwitchRow") { row in      // initializer
                    row.title = "Face Id"
                    if(keychain["faceid"] != nil) {
                        row.value = true
                    }
                    }.onChange { row in
                        row.title = (row.value ?? false) ? "faceid is on" : "faceid is off"
                        if(row.value!) {
                            keychain["faceid"] = "true"
                            print(keychain["faceid"] as Any)
                        } else {
                            keychain["faceid"] = nil
                            print(keychain["faceid"] as Any)
                        }
                        row.updateCell()
                }
                section <<< ButtonRow() {
                    $0.title = "refresh"
                    }.onCellSelection {cell, row in
                        self.refresh(form: self.form, stateManger: stateManager)
                }
                section <<< ButtonRow() {
                    $0.title = "Sign Out"
                    }.onCellSelection {  cell, row in
                        
                        let keychain = self.getKeyChain()
                        let isNative = keychain[string: "native"]
                        if(isNative != nil) {
                            self.performSegue(withIdentifier: "signOutFlow", sender: nil)
                        } else {
                            oktaOidc.signOutOfOkta(stateManager, from: self) { error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                print("GETS Here")
                                keychain["native"] = nil
                                DispatchQueue.main.async {
                                    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                    if(keychain["faceid"] == nil) {
                                        stateManager.clear()
                                    }
                                    if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "MainVc") as? UIViewController {
                                        self.present(viewController, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                }
            }
        }
    }
    
    func refresh(form: Form, stateManger: OktaOidcStateManager) {
        stateManger.getUser { response, error in
            if error != nil {
                // Error
                return
            }
            if(stateManger != nil) {
                if(stateManger.accessToken != nil) {
                    DispatchQueue.main.async {
                        let responseObject = JSON(response as Any)
                        var userInfo = responseObject.dictionaryValue
                        let keys = Array(userInfo.keys)
                        print(responseObject)
                        keys.forEach { item in
                            let row = form.rowBy(tag: item) as! TextRow
                            row.value = userInfo[item]?.rawString()
                            row.reload()
                        }
                    }
                }
            }
        }
    }
    
    func getOkta() -> OktaOidc {
        let config = self.getConfig()
        let oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        return oktaOidc
    }
}

extension UIViewController {
    
    func getKeyChain() -> Keychain {
        return Keychain(service: "com.avbGame.TwelveTest")
    }
    
    func getConfig() -> OktaOidcConfig {
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://avb.oktapreview.com/oauth2/auskkfitx0l6SNY6R0h7",
                "clientId": "0oakkch04alb3cucj0h7",
                "redirectUri": "com.oktapreview.avb:/callback",
                "logoutRedirectUri": "com.oktapreview.avb:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        return config
    }
}
