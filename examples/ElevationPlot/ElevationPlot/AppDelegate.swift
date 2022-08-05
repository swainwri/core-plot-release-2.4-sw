//
//  AppDelegate.swift
//  ElevationPlot
//
//  Created by Steve Wainwright on 27/01/2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupSandbox()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: -
    // MARK: Setup SandBox Initial Contents
    
    private func setupSandbox() {
        
        var dirPaths: [String]  = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        // Get the documents directory
        var docsDirURL: URL = URL(fileURLWithPath:dirPaths[0])
        docsDirURL = docsDirURL.appendingPathComponent("GMMCluster")
        if !FileManager.default.changeCurrentDirectoryPath(docsDirURL.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: docsDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                print("Can't create the Documents/GMMCluster folder\n\(error.localizedFailureReason ?? "unknown")")
                exit(-1)
                // Failed to create directory
            }
        }
        
        if let path = Bundle.main.resourcePath {
            let files = ["info_file1", "info_file2", "info_file3", "data1", "TrainingData21", "TrainingData22", "TestingData2", "data3"]
            var url: URL;
            var saved_url: URL
            for filename: String in files {
                url = URL(fileURLWithPath: path).appendingPathComponent(filename)
                saved_url = docsDirURL.appendingPathComponent(filename)
                do {
                    try FileManager.default.copyItem(at: url, to: saved_url)
                }
                catch let error as NSError  {
                    if error.code != NSFileWriteFileExistsError {
                        print("Can't copy resource to the Documents/GMMCluster folder\n\(error.localizedFailureReason ?? "unknown")")
                    }
                }
            }
        }
    }
}

