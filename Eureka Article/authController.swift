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

class AuthViewController: UIViewController {
    
    @IBOutlet weak var signIn: UIButton!
    // Struct for form items tag constants
    
    @IBAction func login(_ sender: Any) {
        authenticate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signIn.layer.cornerRadius = 4
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://movistar.vanbeeklabs.com/oauth2/default",
                "clientId": "0oahygjhxDYVr9LNc356",
                "redirectUri": "com.okta.dev-801790:/callback",
                "logoutRedirectUri": "com.okta.dev-801790:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            // unauthenticated
            return
        }
        print(stateManager.accessToken)
        print(stateManager.idToken)
        print(stateManager.refreshToken)
        stateManager.getUser { response, error in
            if let error = error {
                // Error
                return
            }
            self.performSegue(withIdentifier: "signIn", sender: nil)
            print(response)
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func authenticate() {
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://movistar.vanbeeklabs.com/oauth2/default",
                "clientId": "0oahygjhxDYVr9LNc356",
                "redirectUri": "com.okta.dev-801790:/callback",
                "logoutRedirectUri": "com.okta.dev-801790:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        
        var oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        
        oktaOidc.signInWithBrowser(from: self) { stateManager, error in
            if let error = error {
                // Error
                return
            }
            stateManager!.writeToSecureStorage()
            self.performSegue(withIdentifier: "signIn", sender: nil)
            print(stateManager!.accessToken)
            print(stateManager!.idToken)
            print(stateManager!.refreshToken)
            
        }
        
    }
    
    
    
}
