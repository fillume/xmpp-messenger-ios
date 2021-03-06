//
//  OneChats.swift
//  OneChat
//
//  Created by Paul on 04/03/2015.
//  Copyright (c) 2015 ProcessOne. All rights reserved.
//

import Foundation

class OneChats: NSObject, NSFetchedResultsControllerDelegate {
	
	var chatList = NSMutableArray()
	var chatListBare = NSMutableArray()
	
	// MARK: Class function
	class var sharedInstance : OneChats {
		struct OneChatsSingleton {
			static let instance = OneChats()
		}
		return OneChatsSingleton.instance
	}
	
	class func getChatsList() -> NSArray {
		if 0 == sharedInstance.chatList.count {
			if let chatList: NSMutableArray = sharedInstance.getActiveUsersFromCoreDataStorage() as? NSMutableArray {//NSUserDefaults.standardUserDefaults().objectForKey("openChatList")
				chatList.enumerateObjectsUsingBlock({ (jidStr, index, finished) -> Void in
					OneChats.sharedInstance.getUserFromXMPPCoreDataObject(jidStr: jidStr as! String)
					
					if let user = OneRoster.userFromRosterForJID(jid: jidStr as! String) {
						OneChats.sharedInstance.chatList.addObject(user)
					}
				})
			}
		}
		return sharedInstance.chatList
	}
	
	private func getActiveUsersFromCoreDataStorage() -> NSArray? {
		var moc = OneMessage.sharedInstance.xmppMessageStorage?.mainThreadManagedObjectContext
		var entityDescription = NSEntityDescription.entityForName("XMPPMessageArchiving_Message_CoreDataObject", inManagedObjectContext: moc!)
		var request = NSFetchRequest()
		var predicateFormat = "streamBareJidStr like %@ "
		
		if let predicateString = NSUserDefaults.standardUserDefaults().stringForKey("kXMPPmyJID") {
			var predicate = NSPredicate(format: predicateFormat, predicateString)
			request.predicate = predicate
			request.entity = entityDescription
			
			if let results = moc?.executeFetchRequest(request, error: nil) {
				var message: XMPPMessageArchiving_Message_CoreDataObject
				var archivedMessage = NSMutableArray()
				
				for message in results {
					var element = DDXMLElement(XMLString: message.messageStr, error: nil)
					let sender: String
					
					if element.attributeStringValueForName("to") != NSUserDefaults.standardUserDefaults().stringForKey("kXMPPmyJID")! && !(element.attributeStringValueForName("to") as NSString).containsString(NSUserDefaults.standardUserDefaults().stringForKey("kXMPPmyJID")!) {
						sender = element.attributeStringValueForName("to")
						if !archivedMessage.containsObject(sender) {
							archivedMessage.addObject(sender)
						}
					}
				}
				return archivedMessage
			}
		}
		return nil
	}
	
	private func getUserFromXMPPCoreDataObject(#jidStr: String) {
		let moc = OneRoster.sharedInstance.managedObjectContext_roster() as NSManagedObjectContext?
		let entity = NSEntityDescription.entityForName("XMPPUserCoreDataStorageObject", inManagedObjectContext: moc!)
		let fetchRequest = NSFetchRequest()
		
		fetchRequest.entity = entity
		
		var predicate: NSPredicate
		
		if OneChat.sharedInstance.xmppStream == nil {
			predicate = NSPredicate(format: "jidStr == %@", jidStr)
		} else {
			predicate = NSPredicate(format: "jidStr == %@ AND streamBareJidStr == %@", jidStr, NSUserDefaults.standardUserDefaults().stringForKey("kXMPPmyJID")!)
		}
		
		fetchRequest.predicate = predicate
		fetchRequest.fetchLimit = 1
		
//		if let results = moc?.executeFetchRequest(fetchRequest, error: nil) {
//			println("get user from xmpp - results")
//			var user: XMPPUserCoreDataStorageObject
//			var archivedUser = NSMutableArray()
//			
//			for user in results {
//				println(user)
//				// var element = DDXMLElement(XMLString: user.messageStr, error: nil)
//				//        let sender: String
//				//
//				//        if element.attributeStringValueForName("to") != NSUserDefaults.standardUserDefaults().stringForKey("kXMPPmyJID")! && !(element.attributeStringValueForName("to") as NSString).containsString(NSUserDefaults.standardUserDefaults().stringForKey("kXMPPmyJID")!) {
//				//          sender = element.attributeStringValueForName("to")
//				//          if !archivedMessage.containsObject(sender) {
//				//            archivedMessage.addObject(sender)
//				//          }
//				//        }
//			}
//			//println("so response \(archivedMessage.count) from \(archivedMessage)")
//			//return archivedMessage
//		}
		//return nil
	}
	
	
	class func knownUserForJid(#jidStr: String) -> Bool {
		if sharedInstance.chatList.containsObject(OneRoster.userFromRosterForJID(jid: jidStr)!) {
			return true
		} else {
			return false
		}
	}
	
	class func addUserToChatList(#jidStr: String) {
		if !knownUserForJid(jidStr: jidStr) {
			sharedInstance.chatList.addObject(OneRoster.userFromRosterForJID(jid: jidStr)!)
			sharedInstance.chatListBare.addObject(jidStr)
		}
	}
	
	class func removeUserFromChatList(#user: XMPPUserCoreDataStorageObject) {
		if sharedInstance.chatList.containsObject(user) {
			sharedInstance.chatList.removeObjectIdenticalTo(user)
			sharedInstance.chatListBare.removeObjectIdenticalTo(user.jidStr)
		}
	}
}