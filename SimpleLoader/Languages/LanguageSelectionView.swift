//
//  LanguageSelectionView.swift
//  SimpleLoader
//
//  Created by Rak on 7/29/25.
//
import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            List {
                //PlainButtonStyle
                
                if #available(macOS 26.0, *){
                    ForEach(languageManager.availableLanguages(), id: \.self) { language in
                        Button(action: {
                            languageManager.setLanguage(language)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(languageManager.displayName(for: language))
                                Spacer()
                                if language == languageManager.currentLanguage {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(SmallPrimaryLiquidGlassStyle())
                        
                    }
                }else{
                    ForEach(languageManager.availableLanguages(), id: \.self) { language in
                        Button(action: {
                            languageManager.setLanguage(language)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(languageManager.displayName(for: language))
                                Spacer()
                                if language == languageManager.currentLanguage {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                }
                
            }
            if #available(macOS 26.0, *){
                Button(action: {
                    languageManager.setLanguage("auto")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("auto_detect".localized)
                        Spacer()
                        if languageManager.currentLanguage == "auto" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(SmallPrimaryLiquidGlassStyle())
                .padding()
            }else{
                Button(action: {
                    languageManager.setLanguage("auto")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("auto_detect".localized)
                        Spacer()
                        if languageManager.currentLanguage == "auto" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
            if #available(macOS 26, *){
                Button("close".localized, systemImage: "xmark") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(SmallPrimaryLiquidGlassStyle())
                .badge(3)
                Spacer()
            }else{
                Button("close".localized, systemImage: "xmark") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(BorderedButtonStyle())
                Spacer()
            }
        }
            
        .frame(width: 300, height: 300)
        .navigationTitle("language_settings".localized)
        .edgesIgnoringSafeArea(.all)
    }
        
}
