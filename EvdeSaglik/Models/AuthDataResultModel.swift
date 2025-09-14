//
//  AuthDataResultModel.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 14.09.2025.
//
import Foundation
import FirebaseAuth
struct AuthDataResultModel{
    let uid: String
    let email : String?
    let photoUrl : String?
    
    init(user : User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}
