//
//  Environment.swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/15/20.
//

import Foundation

class Environment {
    let previous: Environment?
    var current: [String:Int]
    let stack: MemoryStack
    
    init(previous: Environment?, stack: MemoryStack){
        current = ["BEGINNING OF ENV": 0]
        self.previous = previous
        self.stack = stack
    }
    
    /*
     Searches for the value to return in the current environment, and if an outside env exists, searches there
     */
    func getVal(name: String) -> Expr? {
        if let a = current[name] {
            let ret = stack.valOfBinding(address: a)
            return ret
        }
        
        if let prev = previous {
            return prev.getVal(name: name)
        }
        return nil
    }
    
    /*
     Searches for the value to set in the current environment, and if an outside env exists, searches there
     */
    func setVal(name: String, val: Expr) {
        if let a = current[name] {
            stack.setBinding(val: val, address: a)
        }
        
        if let prev = previous {
            prev.setVal(name: name, val: val)
        }
    }
    
    func newVal(name: String, val: Expr) {
        current[name] = stack.addBinding(val: val)
    }
    
    func reference(name: String) -> Int? {
        if let a = current[name] {
            return a
        }
        
        if let prev = previous {
            return prev.reference(name: name)
        }
        return nil
    }
    
    func dereference(address: Int) -> Expr? {
        return stack.valOfBinding(address: address)
    }
    
    func display(){
        for (a,b) in current {
            print("Binding name: \(a), Binding address: \(b)")
        }
        if let a = previous{
            a.display()
        }
    }
}


