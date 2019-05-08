//
//  NetworkManager.swift
//  booth2
//
//  Created by Daniel Young on 3/26/19.
//  Copyright © 2019 Daniel Young. All rights reserved.
//

import Foundation

class NetworkManager{
    static let sharedInstance = NetworkManager()
    private init() {}
    
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration, delegate:  nil, delegateQueue: .main)
    }()
    
    enum NMError: Error {
        case decodeError
    }
    
    #if targetEnvironment(simulator)
    let host = "http://localhost:8077"
    #else
    let host = "http://3.14.163.252:8080"
    #endif
    // http://macbookpro.local:8077
    // https://booth.v2.vapor.cloud
    // http://3.14.163.252:8080
    
    func postUser(with email: String,  callback: @escaping (User) -> Void) throws  {
        let parameters = ["email": email]
        let url = URL(string: "\(host)/user")!
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { return } 
            guard let data = data else { return }
            do {
                guard let user = try? JSONDecoder().decode(User.self, from: data) else { throw NMError.decodeError }
                callback(user)
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func postPhotoStack(photoStack: PhotoStack, callback: @escaping (PhotoStack) -> Void) throws {
        let parameters = ["urls": photoStack.urls, "userID": photoStack.userID] as [String : Any]
        let url = URL(string: "\(host)/photoStack")!
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { return }
            guard let data = data else { return }
            do {
                guard let photoStack = try? JSONDecoder().decode(PhotoStack.self, from: data) else { throw NMError.decodeError }
                callback(photoStack)
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func postVideo(video: Video, callback: @escaping (Video) -> Void) throws {
        let parameters = ["url": video.url, "userID": video.userID] as [String : Any]
        let url = URL(string: "\(host)/video")!
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { return }
            guard let data = data else { return }
            do {
                guard let video = try? JSONDecoder().decode(Video.self, from: data) else { throw NMError.decodeError }
                callback(video)
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
}
