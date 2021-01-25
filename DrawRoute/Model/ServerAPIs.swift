//
//  ServerAPIs.swift
//  DrawRoute
//
//  Created by Swayam Infotech on 01/10/20.
//  Copyright © 2020 Swayam Infotech. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ServerAPIs: NSObject {

    class func getRequest(apiUrl:String, completion: @escaping (_ response: JSON, _ error: NSError?, _ statusCode: Int)-> ()){
        
        Alamofire.request(apiUrl, method: .get).responseJSON { (response) -> Void in
            
            if (response.result.error == nil) {
                print(response.result);
                if response.data?.count == 0 {
                    completion(JSON.null,nil,(response.response?.statusCode)!)
                }else{
                    let dataLog = try! JSON(data: response.data!)
                    completion(dataLog,nil,(response.response?.statusCode)!)
                }
            }else{
                if (response.response != nil){
                    completion(JSON.null,nil,(response.response?.statusCode)!)
                }else{
                    completion(JSON.null,nil,0)
                }
            }
        }
    }
}
