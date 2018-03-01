import Foundation
import UIKit

class Helper {

    static func regexMatches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map {
                nsString.substring(with: $0.range)
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    static func regexMatch(for regex: String, in text: String) -> Bool {
        return !Helper.regexMatches(for: regex, in: text).isEmpty
    }
    
    static func makeTransientNotificationAlert(title: String, body: String, viewController: ViewController ) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`))
        viewController.present(alert, animated: true, completion: nil)
    }

}
