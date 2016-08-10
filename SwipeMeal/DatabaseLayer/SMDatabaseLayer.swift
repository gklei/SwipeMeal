//
//  SMDatabaseLayer.swift
//  SwipeMeal
//
//  Created by Gregory Klein on 6/9/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

import UIKit
import Firebase

private let kStorageURL = "gs://project-3806765351218467701.appspot.com"
private let kProfileImagesPathName = "profileImages"

private let kUsersPathName = "users"
private let kUserInfoPathName = "userInfo"
private let kUserGroupsPathName = "userGroups"
private let kUserProfileSetupCompletePathName = "profileSetupComplete"

typealias UserDataUploadCompletion = (error: NSError?, downloadURL: NSURL?) -> Void

struct SMDatabaseLayer
{
	static func upload(profileImage: UIImage, forSwipeMealUser user: SwipeMealUser, completion: UserDataUploadCompletion? = nil)
	{
		guard let imageData = UIImageJPEGRepresentation(profileImage, 0.5) else {
			return
		}
		
		let storage = FIRStorage.storage()
		let imagesRef = storage.referenceForURL(kStorageURL).child(kProfileImagesPathName)
		
		let fileName = "\(user.uid).jpg"
		let profileImageRef = imagesRef.child(fileName)
		
		profileImageRef.putData(imageData, metadata: nil) { (metadata, error) in
			
			let url = metadata?.downloadURL()
			completion?(error: error, downloadURL: url)
		}
	}
	
	static func setProfileSetupComplete(complete: Bool, forUser user: SwipeMealUser)
	{
		let ref = FIRDatabase.database().reference()
		let userInfoRef = ref.child(kUsersPathName).child("\(user.uid)/\(kUserInfoPathName)")
		userInfoRef.updateChildValues([kUserProfileSetupCompletePathName : complete])
		
		var storage = SwipeMealUserStorage(user: user)
		storage.profileSetupComplete = complete
	}
	
	static func profileSetupComplete(user: SwipeMealUser, callback: ((complete: Bool) -> ()))
	{
		let ref = FIRDatabase.database().reference()
		let userInfoRef = ref.child("\(kUsersPathName)/\(user.uid)/\(kUserInfoPathName)")
		userInfoRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
			
			var complete = false
			if let readValue = snapshot.value?[kUserProfileSetupCompletePathName] as? Bool {
				complete = readValue
			}
			
			callback(complete: complete)
		})
	}
	
	static func addUserToRespectiveGroup(user: SwipeMealUser) {
		guard let groupID = user.groupID else { return }
		
		let ref = FIRDatabase.database().reference()
		let userGroupRef = ref.child("\(kUserGroupsPathName)/\(groupID)")
		userGroupRef.updateChildValues([user.uid : true])
		
		let userRef = ref.child(kUsersPathName).child(user.uid)
		userRef.updateChildValues(["groupID" : groupID])
	}
}
