//
//  Observer.swift
//  Observer
//
//  Created by Dmitry Gordin on 12/23/16.
//  Copyright © 2016 Dmitry Gordin. All rights reserved.
//

import Foundation

public typealias ObserverMethod<Params> = (AnyObject) -> (Params) -> Void

open class Observer<Params> {
    fileprivate weak var observer: AnyObject?
    fileprivate let method: ObserverMethod<Params>
    
    init(_ observer: AnyObject, _ method: @escaping ObserverMethod<Params>) {
        self.observer = observer
        self.method = method
    }
}

open class Subject<Params> {
    private var observers: [Observer<Params>] = []
    
    @discardableResult
    open func attach<ObserverType: AnyObject>(_ observer: ObserverType, _ method: @escaping (ObserverType) -> (Params) -> Void) -> Observer<Params> {
        let item = Observer<Params>(observer, { method($0 as! ObserverType) })
        objc_sync_enter(self)
        observers.append(item)
        objc_sync_exit(self)
        return item
    }
    
    open func deatach(_ observer: Observer<Params>) {
        objc_sync_enter(self)
        observers = observers.filter({ $0 !== observer })
        objc_sync_exit(self)
    }
    
    open func notify(_ params: Params) {
        var methods: [(Params) -> Void] = []
        
        objc_sync_enter(self)
        observers = observers.filter{ $0.observer != nil }
        for item in observers {
            methods.append(item.method(item.observer!))
        }
        objc_sync_exit(self)
        
        for method in methods {
            method(params)
        }
    }
}
