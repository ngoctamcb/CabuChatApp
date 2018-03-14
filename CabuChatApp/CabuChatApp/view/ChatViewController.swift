//
//  ViewController.swift
//  CabuChatApp
//
//  Created by Tam Tran on 3/7/18.
//  Copyright © 2018 Tam Tran. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Foundation
import Firebase
import Photos


class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    private var photoMessageMap = [String: JSQPhotoMediaItem]()

    var sendToId: String = ""
    var sendToName: String = ""
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    private lazy var roomRef : DatabaseReference  = Database.database().reference().child("room")

    private lazy var messageFromRef: DatabaseReference = self.roomRef.child(senderId).child("messages").child(sendToId)

    private lazy var messageToRef: DatabaseReference = self.roomRef.child(sendToId).child("messages").child(senderId)
    
    private var newMessageRefHandle: DatabaseHandle?
    
    
    //TYPING
    private lazy var userIsTypingRef: DatabaseReference =
        self.roomRef.child(senderId).child("typingIndicator").child(senderId)
    
    private lazy var usersTypingQuery: DatabaseQuery = self.roomRef.child(sendToId).child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    
    private var localTyping = false // 2
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
//    Send Image
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://cabuchatapp.appspot.com")
    private let imageURLNotSetKey = "NOTSET"
    
    private var updatedMessageRefHandle: DatabaseHandle?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        // No avatars
        self.navigationItem.title = sendToName
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        print(sendToId)
        observeMessages()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeTyping()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemToRef = messageToRef.childByAutoId()
        let itemFromRef = messageFromRef.childByAutoId()
        let messageItem = [
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            ]
        
        itemToRef.setValue(messageItem)
        itemFromRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        isTyping = false
        finishSendingMessage()
    }
    
    func sendPhotoMessage() -> (String?, String?) {
        let itemToRef = messageToRef.childByAutoId()
        let itemFromRef = messageFromRef.childByAutoId()
        
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            ]
        
        itemToRef.setValue(messageItem)
        itemFromRef.setValue(messageItem)
        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return (itemToRef.key, itemFromRef.key)
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey keyTo: String, keyFrom: String) {
        let itemToRef = messageToRef.child(keyTo)
        let itemFromRef = messageFromRef.child(keyFrom)
        itemToRef.updateChildValues(["photoURL": url])
        itemFromRef.updateChildValues(["photoURL": url])

    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        
        showAlertOption()
        
    }
    
    func showAlertOption() {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let alert = UIAlertController(title: "Alert", message: "Choose Option", preferredStyle: UIAlertControllerStyle.alert)
            
        alert.addAction(UIAlertAction(title: "Take a Photo", style: UIAlertActionStyle.destructive, handler: { action in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
                picker.sourceType = UIImagePickerControllerSourceType.camera
                self.present(picker, animated: true, completion:nil)
                
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Choose Photo", style: UIAlertActionStyle.default, handler: { action in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)) {
                picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
                self.present(picker, animated: true, completion:nil)
            }
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func observeMessages() {
        let messageRef = messageFromRef
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                // 4
                self.addMessage(withId: id, name: name, text: text)
                
                // 5
                self.finishReceivingMessage()
            } else if let id = messageData["senderId"] as String!,
                let photoURL = messageData["photoURL"] as String! { // 1
                // 2
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 3
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
                    // 4
                    if photoURL.hasPrefix("gs://") {
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }
            
            
        })
        
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            
            if let photoURL = messageData["photoURL"] as String! { // 2
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] { // 3
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                }
            }
        })
    }
    
    private func observeTyping() {
        let typingIndicatorRef =  self.roomRef.child(sendToId).child("typingIndicator")

        userIsTypingRef.onDisconnectRemoveValue()
        
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
        
        usersTypingQuery.observe(.value) { (data: DataSnapshot) in

            // You're the only typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }

            // Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
        
        
    }
    
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        let storageRef = Storage.storage().reference(forURL: photoURL)
        
        // 2
        
            storageRef.getData(maxSize: INT64_MAX, completion: { (data, error) in
                if let error = error {
                    print("Error downloading image data: \(error)")
                    return
                }
                
                storageRef.getMetadata(completion: { (metadata, metadataErr) in
                    if let error = metadataErr {
                        print("Error downloading metadata: \(error)")
                        return
                    }
                    
                    // 4
                    if (metadata?.contentType == "image/gif") {
                        mediaItem.image = UIImage.gifWithData(data!)
                        
                    } else {
                        mediaItem.image = UIImage.init(data: data!)
                    }
                    self.collectionView.reloadData()
                    
                    // 5
                    guard key != nil else {
                        return
                    }
                    self.photoMessageMap.removeValue(forKey: key!)
                })
            })
        
    }
    
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }

}

// MARK: Image Picker Delegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        // 1
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        // 2
        let (keyTo, keyFrom) = sendPhotoMessage()
        if let keyTo = keyTo, let keyFrom = keyFrom {
            // 3
            let imageData = UIImageJPEGRepresentation(image, 1.0)
            // 4
            let imagePath = Auth.auth().currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
            // 5
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            // 6
            storageRef.child(imagePath).putData(imageData!, metadata: metadata) { (metadata, error) in
                if let error = error {
                    print("Error uploading photo: \(error)")
                    return
                }
                // 7
                self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: keyTo, keyFrom: keyFrom)
            }
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}

extension UIImage {
    
    public class func gifWithData(_ data: Data) -> UIImage? {
        // Create source from data
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("SwiftGif: Source for the image does not exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        // Fill arrays
        for i in 0..<count {
            // Add image
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            // At it's delay in cs
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                            source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        // Calculate full duration
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        // Get frames
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        // Heyhey
        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 1000.0)
        
        return animation
    }
    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        // Get dictionaries
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        // Get delay time
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()),
                                        to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        
        if delay < 0.1 {
            delay = 0.1 // Make sure they're not too fast
        }
        
        return delay
    }
    
    
    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    class func gcdForPair(_ _a: Int?, _ _b: Int?) -> Int {
        // Check if one of them is nil
        if _b == nil || _a == nil {
            if _b != nil {
                return _b!
            } else if _a != nil {
                return _a!
            } else {
                return 0
            }
        }
        
        var a = _a!
        var b = _b!
        
        // Swap for modulo
        if a < b {
            let c = a
            a = b
            b = c
        }
        
        // Get greatest common divisor
        var rest: Int
        while true {
            rest = a % b
            
            if rest == 0 {
                return b // Found it
            } else {
                a = b
                b = rest
            }
        }
    }

    
}
