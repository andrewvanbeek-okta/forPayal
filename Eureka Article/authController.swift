//
//  dasboardController.swift
//  telefonica
//
//  Created by Andrew Vanbeek on 4/26/19.
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import Foundation
import OktaOidc
import Eureka
import LocalAuthentication
import SwiftyJSON
import SCLAlertView

class AuthViewController: UIViewController {
    
    @IBAction func faceId(_ sender: Any) {
        self.checkIfValidUserForBio()
    }
    
    @IBOutlet weak var faceIdButton: UIButton!
    
    @IBOutlet weak var signIn: UIButton!
    // Struct for form items tag constants
    
    @IBAction func login(_ sender: Any) {
        print("TEST")
        self.authenticate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let keychain = self.getKeyChain()
        print(keychain["faceid"] as Any)
        signIn.layer.cornerRadius = 4
        self.addBackground()
        let config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            return
        }
        print(stateManager.accessToken as Any)
        print(stateManager.idToken as Any)
        print(stateManager.refreshToken as Any)
        stateManager.getUser { response, error in
            if error != nil {
                // Error
                return
            }
            if(response != nil) {
                DispatchQueue.main.async(){
                    let keychain = self.getKeyChain()
                    if(keychain["faceid"] == nil) {
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                        if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "userDashBoard") as? UIViewController {
                            self.present(viewController, animated: true, completion: nil)
                        }
                    } else {
                        self.biometric()
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let keychain = self.getKeyChain()
        print(keychain["faceid"] as Any)
        let config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            return
        }
        
        if(keychain["faceid"] == nil) {
            print(stateManager.accessToken as Any)
            print(stateManager.idToken as Any)
            print(stateManager.refreshToken as Any)
            DispatchQueue.main.async(){
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "userDashBoard") as? UIViewController {
                    self.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func authenticate() {
        let config = self.getConfig()
        let oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        
        oktaOidc.signInWithBrowser(from: self) { stateManager, error in
            if let error = error {
                print(error)
                return
            }
            stateManager!.writeToSecureStorage()
            print(stateManager!.accessToken as Any)
            print(stateManager!.idToken as Any)
            print(stateManager!.refreshToken as Any)
            DispatchQueue.main.async(){
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "userDashBoard") as? UIViewController {
                    self.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    func addBackground() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        imageViewBackground.image = (UIImage(named: "rogersbg.jpg"))
        imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill
        self.view.addSubview(imageViewBackground)
        self.view.sendSubview(toBack: imageViewBackground)
    }
    
    func biometric() {
        let laContext = LAContext()
        var error: NSError?
        let biometricsPolicy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
        let keychain = self.getKeyChain()
        let faceid = keychain["faceid"]
        if(faceid != nil) {
            if (laContext.canEvaluatePolicy(biometricsPolicy, error: &error)) {
                if let laError = error {
                    print("laError - \(laError)")
                    return
                }
                var localizedReason = "Unlock device"
                if #available(iOS 11.0, *) {
                    if (laContext.biometryType == LABiometryType.faceID) {
                        localizedReason = "Unlock using Face ID"
                        print("FaceId support")
                    } else if (laContext.biometryType == LABiometryType.touchID) {
                        localizedReason = "Unlock using Touch ID"
                        print("TouchId support")
                    } else {
                        print("No Biometric support")
                    }
                } else {
                    // Fallback on earlier versions
                }
                laContext.evaluatePolicy(biometricsPolicy, localizedReason: localizedReason, reply: { (isSuccess, error) in
                    DispatchQueue.main.async(execute: {
                        if let laError = error {
                            print("laError - \(laError)")
                        } else {
                            if isSuccess {
                                DispatchQueue.main.async(){
                                    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                    if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "userDashBoard") as? UIViewController {
                                        self.present(viewController, animated: true, completion: nil)
                                    }
                                }
                            } else {
                                print("failure")
                            }
                        }
                    })
                })
            }
        } else {
            SCLAlertView().showInfo("Important info", subTitle: "Faceid is not on")
        }
    }
    
    func checkIfValidUserForBio() {
        let config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            SCLAlertView().showInfo("Important info", subTitle: "Faceid is not on")
            return
        }
        print(stateManager.accessToken as Any)
        stateManager.getUser { response, error in
            if let error = error {
                print(error)
                return
            }
            let user = JSON(response as Any)
            var userDictionary = user.dictionaryValue
            let userId = userDictionary["sub"]?.stringValue
            print(userId as Any)
            if(userId != nil) {
                self.biometric()
            }
        }
    }
}
