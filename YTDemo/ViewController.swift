//
//  ViewController.swift
//  YTDemo
//
//  Created by Gabriel Theodoropoulos on 27/6/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
//https://www.appcoda.com/youtube-api-ios-tutorial/
    @IBOutlet weak var tblVideos: UITableView!
    
    @IBOutlet weak var segDisplayedContent: UISegmentedControl!
    
    @IBOutlet weak var viewWait: UIView!
    
    @IBOutlet weak var txtSearch: UITextField!
    
    var apiKey = "AIzaSyARFDRgWB7Hg6ipjWQ82eZnefLbvUZE-DE"
    
    var desiredChannelsArray = ["Apple" , "Google", "Microsoft" ]
    
    var channelIndex = 0
    
    var channelsDataArray: Array<Dictionary<String, AnyObject>> = []
    
    var videosArray: Array<Dictionary<String, AnyObject>> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tblVideos.delegate = self
        tblVideos.dataSource = self
        txtSearch.delegate = self
        
        getChannelDetails(useChannelIDParam: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }


    // MARK: IBAction method implementation
    
    @IBAction func changeContent(sender: AnyObject) {
        tblVideos.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .fade)
    }
    
    
    // MARK: UITableView method implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if segDisplayedContent.selectedSegmentIndex == 0 {
            
            return channelsDataArray.count
            
        }else{
            return videosArray.count
        }
        
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if segDisplayedContent.selectedSegmentIndex == 0{
            cell = tableView.dequeueReusableCell(withIdentifier: "idCellChannel", for: indexPath)
            
            let channelTitleLabel = cell.viewWithTag(10) as! UILabel
            let channelDescriptionLabel = cell.viewWithTag(11) as! UILabel
            let thumbnailImageView = cell.viewWithTag(12) as! UIImageView
            
            let channelDetails = channelsDataArray[indexPath.row]
            channelTitleLabel.text = channelDetails["title"] as? String
            channelDescriptionLabel.text = channelDetails["description"] as? String
            let urlData = URL(string: (channelDetails["thumbnail"] as? String)!)
            do{
                let data = try Data(contentsOf: urlData!)
                thumbnailImageView.image = UIImage(data: data)
            }catch let error{
                print("Error = \(error.localizedDescription)")
            }
            
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "idCellVideo", for: indexPath)
            
            let videoTitle = cell.viewWithTag(10) as! UILabel
            let videoThumbnail = cell.viewWithTag(11) as! UIImageView
            
            let videoDetails = videosArray[indexPath.row]
            videoTitle.text = videoDetails["title"] as? String
            let urlData = videoDetails["thumbnail"] as? String
            let imgURL = URL(string: urlData!)
            do{
                let data = try Data(contentsOf: imgURL!)
                 videoThumbnail.image = UIImage(data: data)
            }catch let error{
                print("Error = \(error.localizedDescription)")
            }
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if segDisplayedContent.selectedSegmentIndex == 0{
            
            segDisplayedContent.selectedSegmentIndex = 1
            
            viewWait.isHidden = false
            
            videosArray.removeAll(keepingCapacity: false)
            
            getVideosForChannelAtIndex(index: indexPath.row)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140.0
    }
    
    
    // MARK: UITextFieldDelegate method implementation
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        viewWait.isHidden = false
        
       
        
        var type = "channel"
        
        if segDisplayedContent.selectedSegmentIndex == 1 {
            type = "video"
            videosArray.removeAll(keepingCapacity: false)
            
        }
        
        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(textField.text ?? "dd")&type=\(type)&key=\(apiKey)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .illegalCharacters)!
        
        let targetURL = URL(string: urlString)
        
        performGetRequest(targetURL: targetURL!) { (data, HTTPStatusCode, error) in
            if HTTPStatusCode == 200 && error == nil {
                
                do{
                    let resultDict = try JSONSerialization.jsonObject(with: data!, options: [.mutableContainers]) as! Dictionary<String,AnyObject>
                    
                    let items: Array<Dictionary<String, AnyObject>> = resultDict["items"] as! Array<Dictionary<String, AnyObject>>
                    
                    for i:Int in 0 ..< items.count{
                        let snippetDict = items[i]["snippet"] as! Dictionary<String,AnyObject>
                        
                        if self.segDisplayedContent.selectedSegmentIndex == 0{
                            self.desiredChannelsArray.append(snippetDict["channelId"] as! String)
                        }else{
                            var videoDetailsDict = Dictionary<String, AnyObject>()
                            videoDetailsDict["title"] = snippetDict["title"]
                            videoDetailsDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<String, AnyObject>)["default"] as! Dictionary<String, AnyObject>)["url"]
                             videoDetailsDict["videoID"] = (items[i]["id"] as! Dictionary<String, AnyObject>)["videoId"]
                            
                            self.videosArray.append(videoDetailsDict)
                            self.tblVideos.reloadData()
                        }
                    }
                    
                    if self.segDisplayedContent.selectedSegmentIndex == 0 {
                        self.getChannelDetails(useChannelIDParam: true)
                    }
                    
                }catch let error{
                    print("Error = \(error.localizedDescription)")
                }
                
            }else{
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel videos: \(String(describing: error?.localizedDescription))")
            }
            self.viewWait.isHidden = true
        }
        
        return true
    }
    

    
    func performGetRequest(targetURL:URL, completion: @escaping(_ data:Data?,_ HTTPStatusCode:Int,_ error:Error?)->()){
        
        var request = URLRequest(url: targetURL)
        request.httpMethod = "GET"
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                completion(data,(response as! HTTPURLResponse).statusCode,error)
            }
            
        }
        
        task.resume()
        
        
    }
    
    func getChannelDetails(useChannelIDParam:Bool) {
        var urlString: String!
        if !useChannelIDParam {
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&forUsername=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
        }else{
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&id=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"

        }
        
        let targetURL = NSURL(string: urlString)
        
        performGetRequest(targetURL: targetURL! as URL) { (data, HTTPStatusCode, error) in
            if HTTPStatusCode == 200 && error == nil {
                do{
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options: [.mutableContainers]) as! [String: AnyObject]
                    
                    let items  = resultsDict["items"] as! [[String: AnyObject]]
                    
                    let firstItemDict = items[0] as Dictionary<String,AnyObject>
                    let snippetDict = firstItemDict["snippet"] as! Dictionary<String,AnyObject>
                    
                    var desiredValuesDict: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                    
                    desiredValuesDict["title"] = snippetDict["title"]
                    desiredValuesDict["description"] = snippetDict["description"]
                    
                    desiredValuesDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<String,AnyObject>)["default"] as! Dictionary<String,AnyObject>)["url"]
                    
                    desiredValuesDict["playlistID"] = ((firstItemDict["contentDetails"] as! Dictionary<String, AnyObject>)["relatedPlaylists"] as! Dictionary<String, AnyObject>)["uploads"]
                    
                    self.channelsDataArray.append(desiredValuesDict as [String : AnyObject])
                    
                    self.tblVideos.reloadData()
                    self.channelIndex += 1
                    
                    if self.channelIndex < self.desiredChannelsArray.count{
                        self.getChannelDetails(useChannelIDParam: useChannelIDParam)
                    }else{
                        self.viewWait.isHidden = true
                    }
                
                    
                }catch let error{
                    print("ERROR = \(error.localizedDescription)")
                }
                
            }else{
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel details: \(error!.localizedDescription)")
            }
        }
    }
    
    func getVideosForChannelAtIndex(index: Int!){
        
        let playlistID = channelsDataArray[index]["playlistID"] as! String
        
        
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(playlistID)&key=\(apiKey)"
        
        let targetURL = URL(string: urlString)
        
        performGetRequest(targetURL: targetURL!) { (data, HttpStatusCode, error) in
            
            if HttpStatusCode == 200 && error == nil{
                
                do{
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options: [.mutableContainers]) as! Dictionary<String,AnyObject>
                    
                    let items: Array<Dictionary<String,AnyObject>> = resultsDict["items"] as! Array<Dictionary<String, AnyObject>>
                    
                    for i:Int in 0 ..< items.count {
                        
                        let playlistSnippetDict = (items[i] as Dictionary<String, AnyObject>)["snippet"] as! Dictionary<String, AnyObject>
                        
                        var desiredPlaylistItemDataDict = Dictionary<String, AnyObject>()
                        
                        desiredPlaylistItemDataDict["title"] = playlistSnippetDict["title"]
                        desiredPlaylistItemDataDict["thumbnail"] = ((playlistSnippetDict["thumbnails"] as! Dictionary<String, AnyObject>)["default"] as! Dictionary<String, AnyObject>)["url"]
                        
                        desiredPlaylistItemDataDict["videoID"] = (playlistSnippetDict["resourceId"] as! Dictionary<String, AnyObject>)["videoId"]
                        
                        self.videosArray.append(desiredPlaylistItemDataDict)
                        self.tblVideos.reloadData()
                        
                        
                    }
                   
                    
                    
                }catch let error{
                    print("Error = \(error.localizedDescription)")
                }
                
                
            } else {
                print("HTTP Status Code = \(HttpStatusCode)")
                print("Error while loading channel videos: \(error!.localizedDescription)")
            }
            
            self.viewWait.isHidden = true
        }

    }
    
    
    
}

