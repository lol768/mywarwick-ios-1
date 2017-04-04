import Foundation

protocol User {
    var signedIn: Bool { get }
    var usercode: String? { get }
    var name: String? { get }
    var photoURL: String? { get }
    var authoritative: Bool { get }
}

class AnonymousUser: User {
    let signedIn = false
    let usercode: String? = nil
    let name: String? = nil
    let photoURL: String? = nil
    var authoritative: Bool

    init(authoritative: Bool) {
        self.authoritative = authoritative
    }
}

class AuthenticatedUser: User {
    let signedIn = true
    var usercode: String?
    var name: String?
    var photoURL: String?
    var authoritative: Bool

    init(usercode: String, name: String, photoURL: String, authoritative: Bool) {
        self.usercode = usercode
        self.name = name
        self.photoURL = photoURL
        self.authoritative = authoritative
    }
}
