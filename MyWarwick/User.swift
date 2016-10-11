import Foundation


protocol User {
    var signedIn: Bool { get }
    var usercode: String? { get }
    var name: String? { get }
    var photoURL: String? { get }
}

class AnonymousUser: User {
    let signedIn: Bool = false
    let usercode: String? = nil
    let name: String? = nil
    let photoURL: String? = nil
}

class AuthenticatedUser: User {
    let signedIn = true
    var usercode: String?
    var name: String?
    var photoURL: String?
    
    init(usercode: String, name: String, photoURL: String) {
        self.usercode = usercode
        self.name = name
        self.photoURL = photoURL
    }
}
