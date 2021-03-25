//
//  ChatViewController.swift
//  Chat
//
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import MessageKit
import FirebaseFirestore
import SDWebImage
import UIGradients


class ChatViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, UITextViewDelegate {

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = user2Name
        navigationItem.largeTitleDisplayMode = .never
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .secondarySystemBackground
        messageInputBar.sendButton.setTitleColor(.systemBlue, for: .normal)
        messageInputBar.sendButton.activityViewColor = .blue
        
        messagesCollectionView.backgroundColor = .black
        messageInputBar.delegate = self
        messageInputBar.inputTextView.layer.cornerRadius = 6
        messageInputBar.inputTextView.backgroundColor = .secondarySystemBackground
        messageInputBar.inputTextView.textInputView.backgroundColor = .init(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        messageInputBar.inputTextView.placeholder = "Message..."
        messageInputBar.inputTextView.textColor = .white
        messageInputBar.inputTextView.frame = CGRect(x: 50, y: 10, width: 300, height: 60)
        messageInputBar.inputTextView.returnKeyType = .default
        messageInputBar.inputTextView.delegate = self
        messageInputBar.backgroundColor = .black
        messageInputBar.backgroundView.backgroundColor = .black
//        messageInputBar.inputTextView.isHidden = true
//        messageInputBar.sendButton.isHidden = true
        messageInputBar.separatorLine.isHidden = true
        messagesCollectionView.messagesDataSource = self
        
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        loadChat()
        
        messagesCollectionView.scrollToBottom(animated: true)

    }
    

    var currentUser: User = Auth.auth().currentUser!
    private var docReference: DocumentReference?
    var messages: [Message] = []
    //I've fetched the profile of user 2 in previous class from which //I'm navigating to chat view. So make sure you have the following //three variables information when you are on this class.
    var user2Name = "Zergy Development"
    var user2ImgUrl = "https://lh3.googleusercontent.com/a-/AOh14GjS_AU236TsnG6Rz2yIfUrRLwSRMwL88MY3DyN_=s96-"
    var user2UID = "kef6FORfS5Nv5itXiR7W1c7Fvnw1"

    func loadChat() {
    //Fetch all the chats which has current user in it
    let db = Firestore.firestore().collection("Chats").whereField("users", arrayContains: Auth.auth().currentUser?.uid ?? "Not Found User 1")
    db.getDocuments { (chatQuerySnap, error) in
    if let error = error {
    print("Error: \(error)")
    return
    } else {
    //Count the no. of documents returned
    guard let queryCount = chatQuerySnap?.documents.count else {
    return
    }
    if queryCount == 0 {
    //If documents count is zero that means there is no chat available and we need to create a new instance
    self.createNewChat()
    }
    else if queryCount >= 1 {
    //Chat(s) found for currentUser
    for doc in chatQuerySnap!.documents {
    let chat = Chat(dictionary: doc.data())
    //Get the chat which has user2 id
        if ((chat?.users.contains(self.user2UID)) != nil) {
    self.docReference = doc.reference
    //fetch it's thread collection
    doc.reference.collection("thread")
    .order(by: "created", descending: false)
    .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
    if let error = error {
    print("Error: \(error)")
    return
    } else {
    self.messages.removeAll()
    for message in threadQuery!.documents {
    let msg = Message(dictionary: message.data())
    self.messages.append(msg!)
    print("Data: \(msg?.content ?? "No message found")")
    }
    self.messagesCollectionView.reloadData()
        self.messagesCollectionView.scrollToBottom(animated: true)
    }
    })
    return
    }
    //end of if
    } //end of for
    self.createNewChat()
    } else {
    print("Let's hope this error never prints!")
    }}}}
    
    
    
    func insertNewMessage(_ message: Message) {
    //add the message to the messages array and reload it
    messages.append(message)
    
    messagesCollectionView.reloadData()
    DispatchQueue.main.async {
    self.messagesCollectionView.scrollToBottom(animated: true)
    }
    }
    private func save(_ message: Message) {
    //Preparing the data as per our firestore collection
    let data: [String: Any] = [
    "content": message.content,
    "created": message.created,
    "id": message.id,
    "senderID": message.senderID,
    "senderName": message.senderName
    ]
    //Writing it to the thread using the saved document reference we saved in load chat function
    docReference?.collection("thread").addDocument(data: data, completion: { (error) in
    if let error = error {
    print("Error Sending message: \(error)")
    return
    }
    self.messagesCollectionView.scrollToBottom()
        
    })
    }
    
    @objc func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
    //When use press send button this method is called.
    let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: currentUser.uid, senderName: currentUser.displayName!)
    //calling function to insert and save message
    insertNewMessage(message)
    save(message)
    //clearing input field
    
    messagesCollectionView.reloadData()
    messagesCollectionView.scrollToBottom(animated: true)
    inputBar.inputTextView.resignFirstResponder()
    inputBar.inputTextView.text = ""
    }
    
    func currentSender() -> SenderType {
    return Sender(id: Auth.auth().currentUser!.uid, displayName: Auth.auth().currentUser?.displayName ?? "Name not found")
    }
    //This return the MessageType which we have defined to be text in Messages.swift
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return messages[indexPath.section]
    }
    //Return the total number of messages
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    if messages.count == 0 {
    print("There are no messages")
    return 0
    } else {
    return messages.count
    }
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return .zero
    }

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        return isFromCurrentSender(message: message) ? .blue: .lightGray
    }
    //THis function shows the avatar
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    //If it's current user show current user photo.
    if message.sender.senderId == currentUser.uid {
    SDWebImageManager.shared.loadImage(with: currentUser.photoURL, options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
    avatarView.image = image
    }
    } else {
        SDWebImageManager.shared.loadImage(with: URL(string: user2ImgUrl), options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
    avatarView.image = image
    }
    }
    }
    //Styling the bubble to have a tail
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
    
    return .bubbleTail(corner, .curved)
    }
    
    func createNewChat() {
    let users = [self.currentUser.uid, self.user2UID]
    let data: [String: Any] = [
    "users":users
    ]
    let db = Firestore.firestore().collection("Chats")
    db.addDocument(data: data) { (error) in
    if let error = error {
    print("Unable to create chat! \(error)")
    return
    } else {
    self.loadChat()
    }
    }
    }
    
    
    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) {
        inputBar.resignFirstResponder()
    }
    
    
    
}



