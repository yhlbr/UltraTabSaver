//
//  window.swift
//  TabSaver Extension
//
//  Created by Matias Morsa on 28/03/2020.
//  Copyright © 2020 Matias Morsa. All rights reserved.
//

import Foundation
import SafariServices

struct Page : Codable, Equatable {
    var title: String
    var url: URL
    init() {
        self.title = "ERROR"
        self.url = URL(string:"https://www.google.com")!
    }
    init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}

class Persistance {
    
    
    var actual_page:SFSafariPage!
    static let shared = Persistance()
    var date = Date()
    let date_formatter = DateFormatter()
    var savedPages = [String:[Page]]()
    var currentIndex:String?

    init(){
        load()
        UserDefaults.standard.synchronize()
        date_formatter.dateFormat = "dd.MM.yyyy"
    }
    
    
    func setActualPage(page: SFSafariPage){
        self.actual_page = page
    }
    
    func getDictionaryAsString() -> [String:[Page]]{
        var dic2:[String:[Page]] = [:]
        for (k,_) in savedPages{
            dic2[k] = savedPages[k]
        }
        return dic2
    }
    
    func getURLlist(lista:[URL]) -> [String]{
        var lista2:[String] = []
        for url in  lista{
            lista2.append(url.absoluteString)
        }
        return lista2
    }
    
    func getStringAsDate(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: date)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
        let myStringafd = formatter.string(from: yourDate!)
        return myStringafd
    }
    
    func saveActualPage(){
        if (actual_page != nil){
            actual_page.getPropertiesWithCompletionHandler({ (properties) in
                guard let properties = properties else {
                    self.validationHandler(false, "")
                    return
                }
                
                guard let url = properties.url else {
                    self.validationHandler(false, "")
                    return
                }
                guard url.scheme == "http" || url.scheme == "https" else {
                    self.validationHandler(false, "")
                    return
                }
                guard let title = properties.title else {
                    self.validationHandler(false, "")
                    return
                }
                let page = Page(title: String(title.prefix(65)), url: url)
                self.savedPages[self.getStringAsDate(date: Date())] = [page]
            })
        }
        persist()
        if(actual_page != nil ){
            actual_page!.getContainingTab(completionHandler: { currentTab in
                currentTab.getContainingWindow(completionHandler: { window in
                    window?.getAllTabs(completionHandler: { tab_list in
                        for _ in tab_list{
                            NSWorkspace.shared.open(URL(string:"https://www.google.com")!)
                            if (tab_list.count > 1){
                                currentTab.close()
                            }else{
                                NSWorkspace.shared.open(URL(string:"https://www.google.com")!)
                                currentTab.close()
                                return
                            }
                            
                        }
                    })
                })
            })
        }
    }
    
    
    func getUrlByKey(key:String) -> [Page] {
        var retorno = [Page()]
        for (k,_) in savedPages{
            if (k.elementsEqual(key)){
                retorno =  savedPages[k]!
            }
        }
        return retorno
    }
    
    func saveAllPages(key: String? = nil){
        var flag = true
        var nameIndex = key!
        if (key == nil) {
            nameIndex = getStringAsDate(date:Date())
        }

        SFSafariApplication.getActiveWindow { (window) in
            window?.getAllTabs(completionHandler: { tab_list in
                for tab in tab_list {
                    tab.getActivePage(completionHandler: { (page) in
                        guard let page = page else{
                            self.validationHandler(false, "")
                            return
                        }
                        page.getPropertiesWithCompletionHandler({ (properties) in
                            guard let properties = properties else {
                                self.validationHandler(false, "")
                                return
                            }
                            
                            guard let url = properties.url else {
                                self.validationHandler(false, "")
                                return
                            }
                            guard url.scheme == "http" || url.scheme == "https" else {
                                self.validationHandler(false, "")
                                return
                            }
                            guard let title = properties.title else {
                                self.validationHandler(false, "")
                                return
                            }
                            let page = Page(title: title, url: url)
                            if flag{
                                self.savedPages[nameIndex] = [page]
                                flag = false
                            }else{
                                self.savedPages[nameIndex]?.append(page)
                            }
                            self.persist()
                        })
                    })
                }
            })
        }
    }
    
    func updateAllPages() {
        if self.currentIndex != nil {
            saveAllPages(key: self.currentIndex)
        }
        else {
            let alert: NSAlert = NSAlert()
            alert.messageText = "Cant save"
            alert.informativeText = "Tabs will be lost"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func openByKey(indexKey: String) {
        SFSafariApplication.getActiveWindow { (window) in
            // Close all Tabs
            window?.getAllTabs(completionHandler: { (tabs) in
                for (tab) in tabs {
                    tab.close()
                }
            })

            // Open Tabs
            for page in self.getUrlByKey(key: indexKey) {
                let url = URL(string: page.url.absoluteString)!
                window?.openTab(with: url, makeActiveIfPossible: true)
            }
        }

        setActiveIndex(index: indexKey)
    }
    
    func validationHandler(_: Bool,_: String){
        
    }
    
    func getSelected(date:Date){
        
    }
    
    func deleteAll(){
        savedPages = [:]
        persist()
    }
    
    func getAll()-> [String:[Page]] {
        load()
        return self.savedPages
    }
    
    func persist(){
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        let dic2:[String:[Page]] = getDictionaryAsString()
        var  keyList = [String]()
        for (key,value) in dic2{
            do {
                
                let data = try JSONEncoder().encode(value)
                UserDefaults.standard.setValue(data, forKey: key)
                keyList.append(key)
                
            }
            catch {
                
                print(error)
            }
        }
        //     let myData = NSKeyedArchiver.archivedData(withRootObject: keys)
        UserDefaults.standard.set(keyList, forKey: "UTSkeysPages")
        
        UserDefaults.standard.set(currentIndex, forKey: "UTScurrentIndex")
        
        UserDefaults.standard.synchronize()
    }
    
    
    func load(){
        UserDefaults.standard.synchronize()
        let keys:[String] =  UserDefaults.standard.object(forKey: "UTSkeysPages") as? [String] ?? []
        UserDefaults.standard.synchronize()
        if(!keys.isEmpty){
            for key in keys
            {
                do {
                    
                    let storedData = UserDefaults.standard.data(forKey: key)
                    
                    let pages = try JSONDecoder().decode([Page].self, from: storedData!)
                    
                    savedPages[key] = getURLFromString(pages: pages)
                    
                }
                catch {
                    
                    print(error)
                }
                
            }
        }
        
        let index = UserDefaults.standard.string(forKey: "UTScurrentIndex")
        currentIndex = index
    }
    
    func deleteKey(key: String){
        savedPages.removeValue(forKey: key)
        persist()
    }
    
    func renameKey(oldKey:String, newKey:String){
        if(savedPages.keys.contains(newKey)){
            dialogOK(question: "This name already exist", text: "Try another value")
        }else{
            savedPages[newKey] = savedPages[oldKey]
            deleteKey(key: oldKey)
            persist()
        }
    }
    
    func addPage(key:String, page:Page){
        savedPages[key]?.append(page)
        persist()
    }
    
    func dialogOK(question: String, text: String) {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func deletePage(key:String, page:Page ){
        let index = savedPages[key]?.firstIndex(of: page) ?? -1
        if (index != -1){
            savedPages[key]?.remove(at: index)
        }
        persist()
    }
    
    
    func getURLFromString(pages:[Page]) -> [Page]  {
        var list:[Page] = []
        for page in  pages{
            list.append(page)
        }
        return list
    }
    
    func getActiveIndex() -> String? {
        return self.currentIndex
    }
    
    func setActiveIndex(index: String?) {
        self.currentIndex = index
        persist()
    }
}
