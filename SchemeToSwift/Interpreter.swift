//
//  Interpreter.swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/13/20.
//

import Foundation

class Interpreter: ExprVisitor {
    
    enum InterpreterError: Error {
        case interpreterFailure(_ : String)
        case typeMismatch(_ : String)
        case dividingByZero
        case incorrectFunctionCall(_: String)
    }
    
    typealias ExprVisitorReturn = Any?
    
    let memStack: MemoryStack
    var currentEnv: Environment
    var callNum = 0
    let testMode = false
    
    init(_ expr: [Expr?]) {
        // Environment Created:
        memStack = MemoryStack()
        currentEnv = Environment(previous: nil, stack: memStack)
        //---------------------------------------------------------
        var value: Any?
        for a in expr{
            if let exp = a {
                value = evaluate(expr: exp)
            }
        }
        if let val = value {
            print("# - SCHEME: \(val)")
        }
        if testMode {currentEnv.display()}
    }
    
    func visitLiteralExpr(_ expr: Expr.Literal) -> Any? {
        return expr.value
    }
    
    func visitSymbolExpr(_ expr: Expr.Symbol) -> Any? {
        if let a = currentEnv.getVal(name: expr.value){
            return evaluate(expr: a)
        } else {return nil}
    }
    
    func visitUnaryExpr(_ expr: Expr.Unary) -> Any? {
        do {
            if let ex = expr.value { // checks if the value in (unaryOp value) exists
                
                // all unary: .SIN, .COS, .TAN, .CSC, .SEC, .COT, .NOT, .CAR, .CDR
                switch (expr.unaryOp.type){
                case .SIN:
                    let value = evaluate(expr: ex)
                    if let val = value as? Double {
                        return sin(val)
                    }
                    throw InterpreterError.typeMismatch("sin takes in a Double as input: (sin <double>)")
                case .COS:
                    let value = evaluate(expr: ex)
                    if let val = value as? Double {
                        return cos(val)
                    }
                    throw InterpreterError.typeMismatch("cos takes in a Double as input: (cos <double>)")
                case .TAN:
                    let value = evaluate(expr: ex)
                    if let val = value as? Double {
                        return tan(val)
                    }
                    throw InterpreterError.typeMismatch("tan takes in a Double as input: (tan <double>)")
                case .CSC:
                    let value = evaluate(expr: ex)
                    if let val = value as? Double {
                        return 1.0 / sin(val)
                    }
                    throw InterpreterError.typeMismatch("csc takes in a Double as input: (csc <double>)")
                case .SEC:
                    let value = evaluate(expr: ex)
                    if let val = value as? Double {
                        return 1.0 / cos(val)
                    }
                    throw InterpreterError.typeMismatch("sec takes in a Double as input: (sec <double>)")
                case .COT:
                    let value = evaluate(expr: ex)
                    if let val = value as? Double {
                        return sin(val) * cos(val)
                    }
                    throw InterpreterError.typeMismatch("cot takes in a Double as input: (cot <double>)")
                case .NOT:
                    let value = evaluate(expr: ex)
                    if let val = value as? Bool {
                        return !(val)
                    }
                    throw InterpreterError.typeMismatch("not takes in a Boolean as input: (not <bool>)")
                case .CAR:
                    var input: Expr?
                    
                    if let cons = ex as? Expr.Cons{
                        input = evaluate(expr: cons) as? Expr
                    } else {
                        input = evaluate(expr: evaluate(expr: ex) as! Expr) as? Expr
                    }
                    if let cons = input as? Expr.Lambda{
                        if let ifStmt = cons.body[0] as? Expr.If{
                            if let temp = ifStmt.body[0]! as? Expr.Literal {
                                return evaluate(expr: temp)
                            } else {
                                return ifStmt.body[0]
                            }
                        }
                    }

                    throw InterpreterError.typeMismatch("car only takes cons as an input: (car (cons x y))")
                case .CDR:
                    var input: Expr?
                    
                    if let cons = ex as? Expr.Cons{
                        input = evaluate(expr: cons) as? Expr
                    } else {
                        input = evaluate(expr: evaluate(expr: ex) as! Expr) as? Expr
                    }
                    
                    if let cons = input as? Expr.Lambda{
                        if let ifStmt = cons.body[0] as? Expr.If{
                            if let temp = ifStmt.elseBody[0]! as? Expr.Literal {
                                return evaluate(expr: temp)
                            } else {
                                return ifStmt.elseBody[0]
                            }
                        }
                    }
                    throw InterpreterError.typeMismatch("cdr only takes cons as an input: (cdr (cons x y))")
                case .REFERENCE:
                    if let expression = ex as? Expr.Symbol {
                        if let ref = currentEnv.reference(name: (ex as! Expr.Symbol).value) {
                            return Double(ref)
                        }
                        throw InterpreterError.interpreterFailure("No binding with name [\(expression.value)]")
                    }
                    throw InterpreterError.typeMismatch("ref only takes a symbol as input: (ref <symbol>)")
                    
                case .DEREFERENCE:
                    if let value = evaluate(expr: ex) {
                        if let val = value as? Double {
                            if let deref = currentEnv.dereference(address: Int(val)) {
                                return evaluate(expr: deref)
                            }
                            throw InterpreterError.interpreterFailure("No binding with address \(val)")
                        }
                        throw InterpreterError.typeMismatch("Deref only takes an int as input: (deref <int>)")
                    }
                default: return nil
                }
            }
            return nil
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func visitBinaryExpr(_ expr: Expr.Binary) -> Any? {
        do {
            if let v1 = expr.value1{
                if let v2 = expr.value2 {
                    let value1 = evaluate(expr: v1)
                    let value2 = evaluate(expr: v2)
                    
                    // Possible binary types: EQUAL, GREATER, GREATEREQUAL, LESS, LESSEQUAL, SLASH
                    switch (expr.binaryOp.type){
                    case .EQUAL:
                        if let val1 = value1 as? Double {
                            if let val2 = value2 as? Double {
                                return val1 == val2
                            }
                        }
                        throw InterpreterError.typeMismatch("= takes in two Doubles: (= <Double> <Double>)")
                    case .GREATER:
                        if let val1 = value1 as? Double {
                            if let val2 = value2 as? Double {
                                return val1 > val2
                            }
                        }
                        throw InterpreterError.typeMismatch("> takes in two Doubles: (> <Double> <Double>)")
                    case .GREATEREQUAL:
                        if let val1 = value1 as? Double {
                            if let val2 = value2 as? Double {
                                return val1 >= val2
                            }
                        }
                        throw InterpreterError.typeMismatch("=> takes in two Doubles: (=> <Double> <Double>)")
                    case .LESS:
                        if let val1 = value1 as? Double {
                            if let val2 = value2 as? Double {
                                return val1 < val2
                            }
                        }
                        throw InterpreterError.typeMismatch("< takes in two Doubles: (= <Double> <Double>)")
                    case .LESSEQUAL:
                        if let val1 = value1 as? Double {
                            if let val2 = value2 as? Double {
                                return val1 <= val2
                            }
                        }
                        throw InterpreterError.typeMismatch("<= takes in two Doubles: (= <Double> <Double>)")
                    case .SLASH:
                        if let val1 = value1 as? Double {
                            if let val2 = value2 as? Double {
                                if val2 != 0 {
                                    return val1 / val2
                                }
                                throw InterpreterError.dividingByZero
                            }
                        }
                    case .PLUSEQUALS:
                        if let name = expr.value1 as? Expr.Symbol {
                            if let val = value2 as? Double {
                                _ = evaluate(expr: Expr.SetBang(name: name, val: Expr.Literal(value: evaluate(expr: name) as! Double + val)))
                                return nil
                            }
                        }
                        throw InterpreterError.typeMismatch("+= takes in a Double and a symbol: (+= <Symbol> <Double>)")
                    default: throw InterpreterError.interpreterFailure("No Such Binary Expression")
                    }
                }
            }
            return nil
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func visitMultiplearyExpr(_ expr: Expr.Multipleary) -> Any? {
        do {
            //possible multipleary types: MINUS, PLUS, AND, OR, STAR
            switch (expr.multiplearyOp.type){
            case .MINUS:
                var array = expr.values
                
                if var temp = evaluate(expr: array.remove(at: 0)!) as? Double {
                    for val in array {
                        if let v = evaluate(expr: val!) as? Double {
                            temp -= v
                        } else {
                            throw InterpreterError.typeMismatch("- takes in two or more Doubles: (- <Double> <Double>...)")
                        }
                    }
                    return temp
                }
                throw InterpreterError.typeMismatch("- takes in two or more Doubles: (- <Double> <Double>...)")
                
            case .PLUS:
                var array = expr.values
                
                if var temp = evaluate(expr: array.remove(at: 0)!) as? Double {
                    for val in array {
                        let t = evaluate(expr: val!)
                        if let v = t as? Double {
                            temp += v
                        } else {
                            throw InterpreterError.typeMismatch("+ HEYtakes in two or more Doubles: (+ <Double> <Double>...)")
                        }
                    }
                    return temp
                }
                throw InterpreterError.typeMismatch("+ takes in two or more Doubles: (+ <Double> <Double>...)")
            case .AND:
                var temp = true
                for val in expr.values {
                    if let a = evaluate(expr: val!) as? Bool {
                        temp = temp && a
                    } else {
                        throw InterpreterError.typeMismatch("and takes in two or more Booleans: (and <Boolean> <Boolean>...)")
                    }
                }
                return temp
            case .OR:
                var temp = false
                for val in expr.values {
                    if let a = evaluate(expr: val!) as? Bool {
                        temp = temp || a
                    } else {
                        throw InterpreterError.typeMismatch("or takes in two or more Booleans: (or <Boolean> <Boolean>...)")
                    }
                }
                return temp
            case .STAR:
                var temp = 1.0
                for val in expr.values {
                    if let a = evaluate(expr: val!) as? Double {
                        temp *= a
                    } else {
                        throw InterpreterError.typeMismatch("* takes in two or more Doubles: (or <Double> <Double>...)")
                    }
                }
                return temp
            case .PRINT:
                var string = "" as String
                for val in expr.values {
                    if let value = val {
                        if let eval = evaluate(expr: value) {
                            string.append("\(eval)")
                        }
                    }
                }
                return print(string)
            default: return nil
            }
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func visitApplicationExpr(_ expr: Expr.Application) -> Any? {
        do {
            // get the Body of the process...
            let process = evaluate(expr: expr.process!)
            if let proc = process as? Expr.Lambda {
                    
                let body = proc.body
                
                //... as well as variable names from lambda and variable values from apply.
                let varNames = proc.args
                let varVal = expr.args
                
                //get the environment from the lambda to do all the evaluations in
                let newEnv = proc.env!
                
                //... and make and Expr that when evaluated initializes all instance vars (only if the env doesnt already exist
                var varPair: Expr?
                if !proc.envExists {
                    if varNames.endIndex < 1 {
                        varPair = nil
                    } else if varNames.endIndex < 2 {
                        if let names = varNames[0] {
                            varPair = Expr.Define(name: names, body: [varVal[0]])
                        } else {
                            throw InterpreterError.typeMismatch("Arguments in a process must be a symbol.")
                        }
                        
                    } else {
                        if let names = varNames[0] {
                            varPair = Expr.Define(name: names, body: [varVal[0]])
                            
                            if varNames.count == varVal.count{
                                var i = 1
                                while i < varNames.endIndex {
                                    let temp = varPair
                                    varPair = Expr.Consecutive(expr1: temp, expr2: Expr.Define(name: varNames[i]!, body: [varVal[i]]))
                                    i += 1
                                    
                                }
                            } else {
                                throw InterpreterError.incorrectFunctionCall("Incorrect number of function arguments: expected \(varNames.count), got \(varVal.count)")
                            }
                        } else {
                            throw InterpreterError.typeMismatch("Arguments in a process must be a symbol.")
                        }
                    }
                }
                
                // Make the new environment the current environment
                currentEnv = newEnv
                
                if let vp = varPair {
                    _ = evaluate(expr: vp)
                }
                
                var result: Any!
                for a in body {
                    result = evaluate(expr: a!)
                }
                
                currentEnv = currentEnv.previous!
                return result
            } else {
                throw InterpreterError.typeMismatch("to call a function, follow the following format: (<process> <args>...)")
            }
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func visitIfExpr(_ expr: Expr.If) -> Any? {
        do{
            var result: Any!
            //evaluates each expr in body
            if isTrue(evaluate(expr: expr.condition!)){
                let array = expr.body
                for e in array{
                    if let exp = e{
                        result = evaluate(expr: exp)
                    }
                    else { throw InterpreterError.interpreterFailure("show me the body") }
                }
                return result
            }
            //evaluates each expr in else body
            else if !(isTrue(evaluate(expr: expr.condition!))){
                let array = expr.elseBody
                for e in array{
                    if let exp = e {
                        result = evaluate(expr: exp)
                    }
                    else {throw InterpreterError.interpreterFailure("else-body not found in if-else expression")}
                }
                return result
            }
            else {
                throw InterpreterError.interpreterFailure("Cannot interpret if-else expression.")
            }
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func isTrue(_ object: Any?) -> Bool{
        guard let object = object else {
            return false
        }

        if let b = object as? Bool {
            return b
        }

        return true

    }
    
    func isTrue(_ result: Result<Any, InterpreterError>?) -> Bool{
        guard let result = result else{
            return false
        }
        
        switch result {
        case .success(let object):
            return isTrue(object)
        case .failure:
            return false
        }
    }
    
    func visitLambdaExpr(_ expr: Expr.Lambda) -> Any? {
        _ = expr.getEnv(previous: currentEnv, stack: memStack)
        
        return expr
    }
    
    func visitDefineExpr(_ expr: Expr.Define) -> Any? {
        let name = expr.name.value
        var body: Expr
        
        if expr.body.endIndex < 2 {
            body = expr.body[0]!
        }
        else if expr.body.endIndex == 2 {
            body = Expr.Consecutive(expr1: expr.body[0], expr2: expr.body[1])
        }
        else{
            var i = expr.body.endIndex - 1
            body = Expr.Consecutive(expr1: expr.body[i - 1], expr2: expr.body[i])
            i -= 2
            while i <= 0 {
                let temp = body
                body = Expr.Consecutive(expr1: expr.body[i], expr2: temp)
                i -= 1
            }
        }
        currentEnv.newVal(name: name, val: body)
        return 0
    }
    
    /*
     Takes only one thing
     */
    func visitSetBangExpr(_ expr: Expr.SetBang)  -> Any? {
        do{
            let varName = (expr.name as! Expr.Symbol).value
            let newVal = evaluate(expr: expr.val!)
            
            if let _ = currentEnv.getVal(name: varName) {
                //variable must already exist so the var can be mutated
                currentEnv.setVal(name: varName, val: Expr.Literal(value: newVal!))
            }
            else {
                //variable does not exist so you
                throw InterpreterError.interpreterFailure("Variable \(varName) does not already exist")
            }
            return nil
        }
        catch{
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func visitWhileExpr(_ expr: Expr.While) -> Any? {
        var cond = evaluate(expr: expr.cond!)
        
        while cond as! Bool {
            for e in expr.body {
                _ = evaluate(expr: e!)
            }
            cond = evaluate(expr: expr.cond!)
        }
        return nil
    }
    
    func visitBeginExpr(_ expr: Expr.Begin) -> Any? {
        for a in expr.exprs {
            _ = evaluate(expr: a!)
        }
        return evaluate(expr: expr.expr!)
    }

    func visitConsExpr(_ expr: Expr.Cons) -> Any? {
        
        // create a process that returns value1 when true and value2 when false
        let condition = Expr.Symbol(value: "x")
        let ifBody = expr.expr1
        let elseBody = expr.expr2
        let body: Expr
        
        if let eb = elseBody {
            body = Expr.If(condition: condition, body: [ifBody], elseBody: [elseBody])
        } else {
            body = Expr.If(condition: condition, body: [ifBody], elseBody: [nil])
        }
        
        return Expr.Lambda(args: [Expr.Symbol(value: "x")], body: [body], env: nil)
    }
    
    func visitConsecutiveExpr(_ expr: Expr.Consecutive) -> Any? {
        _ = evaluate(expr: expr.expr1!)
        return evaluate(expr: expr.expr2!)
    }
    
    /*
     like setbang but multiple
    */
    func visitSetValExpr(_ expr: Expr.SetVal) -> Any? {
        return nil
    }
}
// ------------------------ Helper Methods -----------------------------
extension Interpreter {
    
    func evaluate(expr :Expr) -> Any? {
        return expr.accept(visitor: self)
    }
    
    func test(where l: String, current c: Any?){
        if testMode {
            print("#\(callNum) - Location: [\(l)] --- Current: [\(c)]")
            callNum += 1
        }
    }
}
