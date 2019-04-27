//
//  EurekaSimpleViewController.swift
//  Eureka Article
//
//  Created by Tomáš Srna on 13/02/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import UIKit
import Eureka
import OktaOidc

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
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://movistar.vanbeeklabs.com/oauth2/default",
                "clientId": "0oahygjhxDYVr9LNc356",
                "redirectUri": "com.okta.dev-801790:/callback",
                "logoutRedirectUri": "com.okta.dev-801790:/callback",
                "scopes": "openid profile email offline_access"
                ])
        }()
        
        var oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            // unauthenticated
            return
        }
        
        form +++ Section("About You") {section in
            var header = HeaderFooterView<UIView>(.class)
            header.height = {300}
            header.onSetupView = { view, _ in
                view.backgroundColor = .red
                view.backgroundColor = UIColor(patternImage: UIImage(named: "userImage.png")!)
            }
            section.header = header
            }
            +++ Section("YOU")
            <<< TextRow(FormItems.name) { row in
                row.placeholder = "Your Name"
            }
            <<< TextRow(FormItems.firstname) { row in
                row.placeholder = "firstname"
            }
            <<< TextRow(FormItems.lastname) { row in
                row.placeholder = "lastname"
            }
            <<< TextRow(FormItems.email) { row in
                row.placeholder = "email"
                }.cellUpdate { cell, row in
                    print("RUNS")
                    //self.dismiss(animated: false, completion: nil)
            } <<< ButtonRow(){
                $0.title = "Sign Out"
                }.onCellSelection {  cell, row in
                    oktaOidc.signOutOfOkta(stateManager, from: self) { error in
                        if let error = error {
                            return
                        }
                        stateManager.clear()
                        print("gets here")
                        self.performSegue(withIdentifier: "signOut", sender: nil)
                    }
        }
        
        
        
        
        print(stateManager.accessToken)
        print(stateManager.idToken)
        print(stateManager.refreshToken)
        stateManager.getUser { response, error in
            if let error = error {
                // Error
                return
            }
            
            print(response)
            
            
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorView.Style.gray
            loadingIndicator.startAnimating();
            
            self.alert.view.addSubview(loadingIndicator)
            self.alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(self.alert, animated: true, completion: nil)
            
            if let nameRow = self.form.rowBy(tag: FormItems.name) as? RowOf<String>,
                let firstnameRow = self.form.rowBy(tag: FormItems.firstname) as? RowOf<String>,
                let lastnameRow = self.form.rowBy(tag: FormItems.lastname) as? RowOf<String>,
                let emailRow = self.form.rowBy(tag: FormItems.email) as? RowOf<String>
            {
                nameRow.value = response!["name"] as! String
                firstnameRow.value = response!["given_name"] as! String
                lastnameRow.value = response!["family_name"] as! String
                emailRow.value = response!["preferred_username"] as! String
                print(response!["name"])
                nameRow.updateCell()
                firstnameRow.updateCell()
                lastnameRow.updateCell()
                emailRow.updateCell()
                
            }
            
        }
        
    }
    
}
