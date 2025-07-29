//
//  LocalizationHelper.swift
//  SimpleLoader
//
//  Created by Rak on 7/29/25.
//
import Foundation

extension String {
    var localized: String {
        let language = LanguageManager.shared.currentLanguage
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}
