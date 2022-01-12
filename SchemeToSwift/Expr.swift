//
//  Expr.swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/11/20.
//

import Foundation

protocol ExprVisitor {
    associatedtype ExprVisitorReturn
    
    func visitLiteralExpr(_ expr: Expr.Literal) -> ExprVisitorReturn
    func visitSymbolExpr(_ expr: Expr.Symbol) -> ExprVisitorReturn
    func visitUnaryExpr(_ expr: Expr.Unary) -> ExprVisitorReturn
    func visitBinaryExpr(_ expr: Expr.Binary) -> ExprVisitorReturn
    func visitMultiplearyExpr(_ expr: Expr.Multipleary) -> ExprVisitorReturn
    func visitApplicationExpr(_ expr: Expr.Application) -> ExprVisitorReturn
    
    func visitIfExpr(_ expr: Expr.If) -> ExprVisitorReturn
    func visitLambdaExpr(_ expr: Expr.Lambda) -> ExprVisitorReturn
    func visitDefineExpr(_ expr: Expr.Define) -> ExprVisitorReturn
    func visitSetBangExpr(_ expr: Expr.SetBang) -> ExprVisitorReturn
    func visitWhileExpr(_ expr: Expr.While) -> ExprVisitorReturn
    func visitBeginExpr(_ expr: Expr.Begin) -> ExprVisitorReturn
    func visitConsExpr(_ expr: Expr.Cons) -> ExprVisitorReturn
    func visitSetValExpr(_ expr: Expr.SetVal) -> ExprVisitorReturn
    
    func visitConsecutiveExpr(_ expr: Expr.Consecutive) -> ExprVisitorReturn
}


class Expr {
    func accept<V: ExprVisitor, R>(visitor: V) -> R where R == V.ExprVisitorReturn {
        fatalError()
    }
    
    func toString() -> String{
        return ""
    }
    
    // literals, or number, string, true, false, nil
    class Literal: Expr {
        let value: Any?
        
        init(value: Any?){
            self.value = value
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitLiteralExpr(self)
        }
        
        override func toString() -> String {
            if let v = value {
                return "[Literal| value: \(v)]"
            } else {
                return "[Literal| lexeme: nil]"
            }
        }
    }
    
    class Symbol: Expr {
        let value: String
        
        init(value: String){
            self.value = value
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitSymbolExpr(self)
        }
        
        override func toString() -> String {
            return "[Symbol| value: \(value)]"
        }
    }
    
    class Unary: Expr {
        let value: Expr?
        let unaryOp: Token
        
        init(unaryOp: Token, value: Expr?){
            self.value = value
            self.unaryOp = unaryOp
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitUnaryExpr(self)
        }
        
        override func toString() -> String {
            return "[Unary| operator: \(unaryOp), value: \(value!.toString())]"
        }

    }
    
    class Binary: Expr {
        let value1: Expr?
        let value2: Expr?
        let binaryOp: Token
        
        init(binaryOp: Token, value1: Expr?, value2: Expr?){
            self.value1 = value1
            self.value2 = value2
            self.binaryOp = binaryOp
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitBinaryExpr(self)
        }
        
        override func toString() -> String {
            return "[Binary| operator: \(binaryOp), value1: \(value1!.toString()), value2: \(value2!.toString())]"
        }

    }
    
    class Multipleary: Expr {
        let multiplearyOp: Token
        let values: [Expr?]
        
        init(multiplearyOp: Token, values: [Expr?]){
            self.multiplearyOp = multiplearyOp
            self.values = values
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitMultiplearyExpr(self)
        }
        
        override func toString() -> String {
            var temp = "[Multipleary| operator: \(multiplearyOp), values: "
            for a in values{
                temp.append(a!.toString() + " ")
            }
            temp.append("]")
            return temp
        }

    }
    
    class Application: Expr {
        let process: Expr?
        let args: [Expr?]
        
        init(process: Expr?, args: [Expr?]){
            self.process = process
            self.args = args
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitApplicationExpr(self)
        }
        
        override func toString() -> String {
            var temp = "[Application| process: \(process!.toString()), values: "
            for a in args{
                if let arg = a {
                    
                    temp.append(arg.toString() + " ")
                }
            }
            temp.append("]")
            return temp
        }

    }
}

// ----------------------------- keyword classes --------------------------------
extension Expr{
    
    class If: Expr {
        let condition: Expr?
        let body: [Expr?]
        let elseBody: [Expr?]
        
        init(condition: Expr?, body: [Expr?], elseBody: [Expr?]){
            self.condition = condition
            self.body = body
            self.elseBody = elseBody
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitIfExpr(self)
        }
        
        override func toString() -> String {
            var temp = "[IF| condition: \(condition!.toString()), body: "
            for b in body {
                if let bod = b{
                    temp.append("\(bod.toString()) ")
                }
            }
            temp.append(", else body: ")
            
            for eb in elseBody {
                if let ebod = eb {
                    temp.append("\(ebod.toString()) ")
                }
            }
            temp.append("]")
            return temp
        }
    }
    
    class Lambda: Expr {
        let args: [Expr.Symbol?]
        let body: [Expr?]
        var env: Environment?
        var envExists = false
        
        init(args: [Expr.Symbol?], body: [Expr?], env: Environment?){
            self.args = args
            self.body = body
            self.env = env
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitLambdaExpr(self)
        }
        
        func getEnv(previous: Environment?, stack: MemoryStack) -> Environment{
            if let e = env {
                envExists = true
                return e
            }
            self.env = Environment(previous: previous, stack: stack)
            return env!
        }
        
        override func toString() -> String {
            var temp = "[LAMBDA| arguments: "
            for a in args{
                if let arg = a {
                    temp.append(arg.toString() + " ")
                }
            }
            temp.append(", body: ")
            for b in body{
                if let bod = b {
                    temp.append(bod.toString() + " ")
                }
            }
            temp.append("]")
            return temp
        }
        
    }
    
    class Define: Expr {
        let name: Expr.Symbol
        let body: [Expr?]
        
        init(name: Expr.Symbol, body: [Expr?]){
            self.name = name
            self.body = body
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitDefineExpr(self)
        }
        
        override func toString() -> String {
            var temp =  "[DEFINE| name: \(name.toString()), body:"
            for a in body{
                temp.append(a!.toString() + " ")
            }
            temp.append("]")
            return temp
        }
    }
    
    class SetBang: Expr {
            let name: Expr?
            let val: Expr?
            
            init(name: Expr?, val: Expr?){
                self.name = name
                self.val = val
            }
            
            override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
                return visitor.visitSetBangExpr(self)
            }

            override func toString() -> String {
                return "[SETBANG| name: \(name!.toString()), val: \(val!.toString())]"
            }
        }
    
    class While: Expr {
        let cond: Expr?
        let body: [Expr?]
        
        init(cond: Expr?, body: [Expr?]){
            self.cond = cond
            self.body = body
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitWhileExpr(self)
        }

        override func toString() -> String {
            var temp =  "[WHILE| cond: \(cond!.toString()), body: "
            
            for b in body {
                if let bod = b {
                    temp.append("\(bod.toString()) ")
                }
            }
            temp.append("]")
            
            return temp
        }
        
    }
    
    class Consecutive: Expr {
        let expr1: Expr?
        let expr2: Expr?
        
        init(expr1: Expr?, expr2: Expr?){
            self.expr1 = expr1
            self.expr2 = expr2
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitConsecutiveExpr(self)
        }

        override func toString() -> String{
            var temp = ""
            if let a = expr1{
                temp.append(a.toString() + " ")
            }
            if let b = expr2 {
                temp.append(b.toString() + " ")
            }
            return temp
        }
    }
    
    class Cons: Expr {
        let expr1: Expr?
        let expr2: Expr?
        
        init(expr1: Expr?, expr2: Expr?){
            self.expr1 = expr1
            self.expr2 = expr2
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitConsExpr(self)
        }

        override func toString() -> String{
            var temp = "[CONS| car: "
            if let a = expr1{
                temp.append(a.toString() + " ")
            }
            temp.append(", cdr: ")
            if let b = expr2 {
                temp.append(b.toString() + " ")
            }
            temp.append("]")
            return temp
        }
    }
    
    class Begin: Expr {
        let exprs: [Expr?]
        let expr: Expr?
        
        init(exprs: [Expr?], expr: Expr?){
            self.exprs = exprs
            self.expr = expr
        }
        
        override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
            return visitor.visitBeginExpr(self)
        }

        override func toString() -> String{
            var temp = "[BEGIN| Expressions: "
            for ex in exprs {
                if let a = ex {
                    temp.append(a.toString() + " ")
                }
            }
            temp.append(", return: ")
            if let b = expr {
                temp.append(b.toString() + " ")
            }
            temp.append("]")
            return temp
        }
    }
    
    class SetVal: Expr {
            let names: [Expr?]
            let values: [Expr?]
            
            init(names: [Expr?], values: [Expr?]){
                self.names = names
                self.values = values
            }
            
            override func accept<V, R>(visitor: V) -> R where V : ExprVisitor, R == V.ExprVisitorReturn {
                return visitor.visitSetValExpr(self)
            }

            override func toString() -> String {
                var temp = "[SETVAL| nameList: "
                var b = 0
                for a in names{
                    temp.append(a!.toString() + " set to ")
                    temp.append(values[b]!.toString() + ", ")
                    b += 1
                }
                return temp
            }
        }
    //END OF PROGRAM
}
