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
    //MARK: - Test Token String
    var applicantID = ""
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    //MARK: - IBActions
    @IBAction func startOnfido(_ sender: UIButton) {
        self.createApplicant { (applicantID, error) in
            guard error == nil else {
                self.showErrorMessage(forError: error!)
                return
            }
            if let applicantID = applicantID {
                self.runFlow(forApplicantWithID: applicantID)
            }
        }
    }
    //MARK: - Private Funcs
    private func showErrorMessage(forError error: Error) {
        let alert = UIAlertController(title: "Error", message: "Onfido SDK didn't work \(error)", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: { _ in })
        alert.addAction(alertAction)
        self.present(alert, animated: true)
    }
    private func runFlow(forApplicantWithID applicantID: String) {
        let responseHandler: (OnfidoResponse) -> Void = { response in
            if case let OnfidoResponse.error(innerError) = response {
                self.showErrorMessage(forError: innerError)
            } else if case OnfidoResponse.success = response {
                self.sendCheck(forResponse: response) { (checkId, error) in
                    guard error == nil else {
                        self.showErrorMessage(forError: error!)
                        return
                    }
                    print(checkId!)
                }
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
            .withToken(Constants.apiToken)
            .withApplicantId(applicantID)
            .withDocumentStep()
            .withFaceStep(ofVariant: .photo)
            .withAppearance(self.setupAppearance())
            .build()
        
        let onfidoFlow = OnfidoFlow(withConfiguration: config)
            .with(responseHandler: responseHandler)
        
        do {
            
            let onfidoRun = try onfidoFlow.run()
            onfidoRun.modalPresentationStyle = .formSheet // to present modally
            self.present(onfidoRun, animated: true, completion: nil)
            
        } catch let error {
            self.showErrorMessage(forError: error)
        }
    }

    private func createApplicant(_ completionHandler: @escaping(String?, Error?) -> Void) {
        Alamofire.request("https://api.onfido.com/v2/applicants",
            method: .post,
            parameters: Constants.applicant,
            encoding: JSONEncoding.default,
            headers: Constants.headers).responseJSON { (response: DataResponse<Any>) in
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
                print(applicantId)
                self.applicantID = applicantId
                completionHandler(applicantId, nil)
        }
    }
    
    private func sendCheck(forResponse response: OnfidoResponse, _ completionHandler: @escaping(String?, Error?) -> Void) {
        
        let checkRequestURL = "https://api.onfido.com/v2/applicants/" + applicantID + "/checks?" + Constants.checkType +  Constants.reportName1 + Constants.reportName2  + Constants.reportvariant
        
        Alamofire.request(checkRequestURL,
                          method: .post,
                          parameters: [:],
                          encoding: JSONEncoding.default,
                          headers: Constants.headers).responseJSON { (response: DataResponse<Any>) in
                            guard response.error == nil else {
                                completionHandler(nil, response.error)
                                return
                            }
                            let response = response.result.value as! [String: Any]

                            guard response.keys.contains("error") == false else {
                                print(response["error"] as! [String: Any])
                                completionHandler(nil, ApplicantError.apiError(response["error"] as! [String : Any]))
                                return
                            }
                            
                            let checkId = response["id"] as! String
                            
                            completionHandler(checkId, nil)
        }
    }
    
    private func setupAppearance() -> Appearance {
        let appearance = Appearance(
            primaryColor: UIColor(red: 0.09019607843, green: 0.1450980392, blue: 0.2588235294, alpha: 1.0),
            primaryTitleColor: UIColor(red: 0.3803921569, green: 0.4509803922, blue: 0.8558823529, alpha: 1.0),
            primaryBackgroundPressedColor: UIColor(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1.0),
            secondaryBackgroundPressedColor: UIColor(red: 0.5019607843, green: 0.9490196078, blue: 1, alpha: 1.0),
            fontRegular: "ArialHebrew",
            fontBold: "ArialHebrew-Bold")
        
        return appearance
    }
}

extension ViewController {
    struct Constants {
        static let apiToken: String = "test_fHiDLXGhsxEw8T-wu3KXzlqim4712Hu4"
        static let headers: HTTPHeaders = [
            "Authorization": "Token token=\(apiToken)",
            "Accept": "application/json"
        ]
        static let applicant: Parameters = [
            "first_name": "Martin",
            "last_name": "Dimitrov",
            "country": "BGR"
        ]
        static let checkType = "type=express"
        static let reportName1 = "&reports[][name]=document"
        static let reportName2 = "&reports[][name]=facial_similarity"
        static let reportvariant = "&reports[][variant]=express"
    }
}
