//
//  MemoryStack.swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/15/20.
//

import Foundation

class MemoryStack{
    var stack: [Expr?]
    
    init(){
        stack = [Expr()]
    }
    
    /*
     creates a new binding and returns the adress of the binding
     */
    func addBinding(val: Expr) -> Int{
        stack.append(val)
        return stack.endIndex - 1
    }
    /*
     looks for the binding with the specified address and changes it to val
     */
    func setBinding(val: Expr, address: Int){
        stack[address] = val
    }
    
    /*
     returns the Expr value associated with the address
     */
    func valOfBinding(address: Int) -> Expr?{
        if address < stack.endIndex {
            return stack[address]
        } else { return nil }
    }
}
