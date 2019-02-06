//
//  ViewController.swift
//  Onfido_test_build
//
//  Created by Martin Dimitrov on 6.02.19.
//  Copyright © 2019 Appolica Learning. All rights reserved.
//

import UIKit
import Onfido
import Alamofire
enum ApplicantError: Error {
    case apiError([String:Any])
}
class ViewController: UIViewController {
    let apiToken = "test_fHiDLXGhsxEw8T-wu3KXzlqim4712Hu4"
    @IBAction func startOnfido(_ sender: UIButton) {
        self.createApplicant { (applicantID, error) in
            guard error == nil else {
                self.showErrorMessage(forError: error!)
                return
            }
            
            self.runFlow(forApplicantWithID: applicantID!)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    private func showErrorMessage(forError error: Error) {
        let alert = UIAlertController(title: "Error", message: "Onfido SDK f'ed up", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: { _ in })
        alert.addAction(alertAction)
        self.present(alert, animated: true)
    }
    private func runFlow(forApplicantWithID applicantID: String) {
        let responseHandler: (OnfidoResponse) -> Void = { response in
            if case let OnfidoResponse.error(innerError) = response {
                self.showErrorMessage(forError: innerError)
            } else if case OnfidoResponse.success = response {
                let alert = UIAlertController(title: "Success", message: "Success", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default, handler: { _ in })
                alert.addAction(alertAction)
                self.present(alert, animated: true)
            } else if case OnfidoResponse.cancel = response {
                let alert = UIAlertController(title: "Canceled", message: "Canceled by user", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default, handler: { _ in })
                alert.addAction(alertAction)
                self.present(alert, animated: true)
            }
        }
        
        let config = try! OnfidoConfig.builder()
            .withToken(apiToken)
            .withApplicantId(applicantID)
            .withDocumentStep()
            .withFaceStep(ofVariant: .photo)
            .build()
        
        let onfidoFlow = OnfidoFlow(withConfiguration: config)
            .with(responseHandler: responseHandler)
        
        do {
            
            let onfidoRun = try onfidoFlow.run()
            onfidoRun.modalPresentationStyle = .formSheet // to present modally
            self.present(onfidoRun, animated: true, completion: nil)
            
        } catch let error {
            
            // cannot execute the flow
            // check CameraPermissions
            self.showErrorMessage(forError: error)
        }
    }

    private func createApplicant(_ completionHandler: @escaping(String?, Error?) -> Void) {
        let applicant: Parameters = [
            "first_name": "Theresa",
            "last_name": "May"
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": "Token token=\(apiToken)",
            "Accept": "application/json"
        ]
        
        Alamofire.request("https://api.onfido.com/v2/applicants",
            method: .post,
            parameters: applicant,
            encoding: JSONEncoding.default,
            headers: headers).responseJSON { (response: DataResponse<Any>) in
                guard response.error == nil else {
                    completionHandler(nil, response.error)
                    return
                }
                let response = response.result.value as! [String: Any]
                
                guard response.keys.contains("error") == false else {
                    completionHandler(nil, ApplicantError.apiError(response["error"] as! [String : Any]))
                    return
                }
                
                let applicantId = response["id"] as! String
                completionHandler(applicantId, nil)
        }
    }

}

