//
//  SafariExtensionViewController.swift
//  TabSaver Extension
//
//  Created by Matias Morsa on 28/03/2020.
//  Copyright © 2020 Matias Morsa. All rights reserved.
//

import SafariServices


class SafariExtensionViewController: SFSafariExtensionViewController {
    
    @IBOutlet var custom_menu:NSMenu!
    @IBOutlet var set_this_page:NSButton!
    @IBOutlet var set_all_pages:NSButton!
    @IBOutlet var main_menu:NSMenu!
    var lista_submenu:Array<NSMenu>!
    var lista_de_items:Array<NSMenuItem>!
    var lista_de_subitems:Array<NSMenuItem>!
    var selectedPage:String!
    var selectedGroup:String!
    var selectedPageKey:String!
    var firstItemPoint:NSPoint!
    var originPage:Page!
    var flag = false
    static let shared = SafariExtensionViewController()

    
    override func viewDidLoad() {
        preferredContentSize = NSSize(width: 136, height: 199)
        super.viewDidLoad()
        Persistance.shared.updateAllPages()
    }
    
    func flag(bool: Bool){
        flag = bool
    }
    
    func toolbarItemClicked(sender: SFSafariWindow){
        flag = false
        main_menu = NSMenu()
        main_menu.addItem(getMenuItem(title: "Save all tabs", selector: #selector(saveAllLeftClick)))
        let getAll = getMenuItem(title: "Saved tabs", selector: #selector(getAllLeftClick))
        self.parse(list: Persistance.shared.getAll())
        getAll.submenu = custom_menu
        main_menu.addItem(getAll)
        main_menu.popUp(positioning: main_menu.item(at: 0), at: NSEvent.mouseLocation, in: nil)
    }

    @objc func savePageLeftClick(){
        Persistance.shared.saveActualPage()
        if (main_menu.items.count > 0){
            main_menu.removeAllItems()
        }
        getAllLeftClick()
    }
    
    @objc func saveAllLeftClick(){
        Persistance.shared.saveAllPages()
        custom_menu = NSMenu()
        
        getAllLeftClick()
    }
    
    @objc func getAllLeftClick(){
        self.parse(list: Persistance.shared.getAll())
    }

    @IBAction func saveAll(sender: AnyObject){
        Persistance.shared.saveAllPages()
    }
    
    
    @IBAction func getAll(sender: AnyObject){
        print("Get All")
        self.parse(list: Persistance.shared.getAll())
        custom_menu.popUp(positioning: custom_menu.item(at: 0), at: NSEvent.mouseLocation, in: nil)
    }    
    
    @objc func selectPage(sender: NSMenuItem){
        
        selectedPageKey = sender.parent?.title
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            // Right button click
            selectedPage = sender.title
            let url = URL(string: sender.keyEquivalent)!
            originPage = Page(title: selectedPage, url: url)
            let delete = getMenuItem(title: "Delete", selector: #selector(optionDeletePage))
            let copyToClipboard  = getMenuItem(title:  "Copy to clipboard", selector: #selector(optionSharePage) )
            
            let options = NSMenu()
            
            options.autoenablesItems = false
            options.addItem(delete)
            options.addItem(copyToClipboard)
            options.popUp(positioning: options.item(at: 0), at: NSEvent.mouseLocation, in: nil)
        }
        if event.type == NSEvent.EventType.leftMouseUp {
            let url = URL(string: sender.keyEquivalent)!
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func optionShareGroup(){
        NSPasteboard.general.clearContents()
        let url_list = Persistance.shared.getUrlByKey(key: selectedGroup).compactMap { $0.url.absoluteString }.joined(separator: "\n")
        NSPasteboard.general.setString(url_list, forType: .string)
        
    }
    
    @objc func optionDeleteGroup(){
        Persistance.shared.deleteKey(key: selectedGroup)
    }
    
    @objc func optionRenameGroup() -> Bool{
        let title = "Add a new name"
        let text = "Each group must have a UNIQUE name"
        let alert = NSAlert()
        alert.messageText = title
        alert.icon =  #imageLiteral(resourceName:"TextFieldRename.png")
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.stringValue = "New Name"
        alert.accessoryView = txt
        let response: NSApplication.ModalResponse = alert.runModal()
        alert.window.initialFirstResponder = txt
        
        if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
            Persistance.shared.renameKey(oldKey: selectedGroup, newKey: txt.stringValue)
            return true
        } else {
            return false
        }
    }
    
    @objc func optionSharePage(){
        let url = Persistance.shared.getUrlByKey(key: selectedPageKey)[0].url.absoluteString
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
    }
    
    @objc func optionDeletePage(){
        Persistance.shared.deletePage(key: selectedPageKey, page: originPage)
    }
    
    @objc func optionAddPage() ->Bool{
        let title = "Insert the URL"
        let text = " "
        let alert = NSAlert()
        alert.messageText = title
        alert.icon =  #imageLiteral(resourceName:"TextFieldRename.png")
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.stringValue = "URL"
        alert.accessoryView = txt
        let response: NSApplication.ModalResponse = alert.runModal()
        alert.window.initialFirstResponder = txt
        
        if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
            if(!txt.stringValue.isEmpty){
                Persistance.shared.addPage(key: selectedGroup, page: Page(title: "title", url: URL(string: txt.stringValue)!))
            }
            return true
        } else {
            return false
        }
    }
    
    @objc func deleteAll(){
        Persistance.shared.deleteAll()
    }
    
    
    func getMenuItem(title:String, selector: Selector) -> NSMenuItem  {
        let menuItem = NSMenuItem()
        menuItem.isAlternate = false
        menuItem.isEnabled = true
        menuItem.target = self
        menuItem.action = selector
        menuItem.title = title
        
        return menuItem
    }
    
    @objc func selectGroup(sender: NSMenuItem!){
        self.selectedGroup = sender.title
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            // Right button click
            let rename = getMenuItem(title: "Rename", selector: #selector(optionRenameGroup))
            let addPage = getMenuItem(title: "Add Page", selector: #selector(optionAddPage))
            let delete = getMenuItem(title: "Delete", selector: #selector(optionDeleteGroup))
            let copyToClipboard  = getMenuItem(title:  "Copy to clipboard", selector: #selector(optionShareGroup) )
            
            let options = NSMenu()
            options.autoenablesItems = false
            
            if(flag){
                options.addItem(rename)
            }
            options.addItem(delete)
            options.addItem(copyToClipboard)
            options.addItem(addPage)
            options.popUp(positioning: options.item(at: 0), at: NSEvent.mouseLocation, in: nil)
            
        } else {
            Persistance.shared.openByKey(indexKey: sender.title)
        }
    }
    
    func parse(list:[String:[Page]]){
        var i = 0
        var ii = 0
        custom_menu = NSMenu()
        lista_de_subitems = Array()
        lista_submenu = Array()
        lista_de_items = Array()
        let order_list = list.sorted(by: { $0.0 < $1.0 })
        
        if (!order_list.isEmpty){
            for (k,v) in order_list {
                lista_de_items.insert(NSMenuItem(), at: i)
                // FECHA
                lista_de_items[i] = getMenuItem(title: k, selector: #selector(selectGroup))
                custom_menu.autoenablesItems  = false
                lista_submenu.insert(NSMenu(), at: i)
                lista_submenu[i].autoenablesItems = false
                
                for page in v {
                    let a = NSMenuItem()
                    lista_de_subitems.insert(a, at: ii)
                    let pageTitle = page.title
                    
                    if (!pageTitle.isEmpty) {
                        self.lista_de_subitems[ii] = getMenuItem(title: String(pageTitle.prefix(65)), selector: #selector(selectPage))
                        self.lista_de_subitems[ii].keyEquivalent  = page.url.absoluteString.lowercased()
                        NSLog(page.url.absoluteString.lowercased())
                        self.lista_de_subitems[ii].keyEquivalentModifierMask = .init()
                        self.lista_submenu[i].addItem(self.lista_de_subitems[ii])
                        ii+=1
                    }
                    lista_de_items[i].submenu = lista_submenu[i]
                }
                i+=1
            }
        }else{
            let item = NSMenuItem()
            item.title = "Empty"
            item.isEnabled = true
            custom_menu.insertItem(item,at:0)
        }
        
        for _item in lista_de_items{
            custom_menu.addItem(_item)
        }
        if (custom_menu.items.count > 1){
            custom_menu.addItem(getMenuItem(title: "Delete all", selector: #selector(deleteAll)))
        }
    }
    
}


