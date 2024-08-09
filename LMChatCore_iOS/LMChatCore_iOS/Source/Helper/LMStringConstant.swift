//
//  LMStringConstant.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 06/03/24.
//

import Foundation

public struct LMStringConstant {
    private init() { }
    
    public static var shared = Self()
    
    public var profileRoute = "route://member_profile/"
    public var appName = "LM Chat"
    public var genericErrorMessage = "Something went wrong!"
    public var maxUploadSizeErrorMessage = "Max Upload Size is %d"
    public var cancel = "Cancel"
    public var doneText = "Done"
    public var oKText = "OK"
    public var anonymousPollTitle = "Anonymous poll"
    public var anonymousPollMessage = "This being an anonymous poll, the names of the voters can not be disclosed."
    public var endPollVisibleResultMessage = "The results will be visible after the poll has ended."
    public var pollEndMessage = "Poll ended. Vote can not be submitted now."
    public var pollSubmittedTitle = "Vote submission successful"
    public var pollSubmittedMessage = "Your vote has been submitted successfully."
}
