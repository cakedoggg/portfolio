//
//  Parser.swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/11/20.
//

import Foundation

final class Parser {
    enum ParseError: Swift.Error {
        case parseFailure(_: String)
        case parserTypeMismatch(_: String)
    }
    
    var tokens: Array<Token>
    var current = 0
    
    let testMode = false
    var errorMode = false
    var errorMessage = ""
    var callNum = 0

    init(tokens: Array<Token>) {
        self.tokens = tokens
    }
    
    func parse() -> Array<Expr> {
        var finalExpr = Array<Expr>()
        
        do {
            while !isAtEnd() {
                if let expression = try exprDeclaration() {
                    finalExpr.append(expression)
                }
            }
            return finalExpr
        } catch {
            print(errorMessage)
            return finalExpr
        }
    }
}

//-------------------- Grammar Methods ---------------------------
extension Parser {
    
    func exprDeclaration() throws -> Expr? {
        do {
            // if the left parenthesis is found it is consumed...
            test(where: "expr, beginning", current: peek())
            if check(.LEFTPAREN,.QUOTE) {
                
                if !check(.QUOTE) {_ = try match(.LEFTPAREN)}
                test(where: "expr, non-literal path", current: peek())
                
                // ...and if the next token is the right parenthesis...
                if check(.RIGHTPAREN){
                    _ = try match(.RIGHTPAREN)
                    // ...the token is consumed and try exprDeclaration() is called on the next thing
                    return try exprDeclaration()
                }
                test(where: "expr, before unary", current: peek())
                // if the first thing after the left paren is a symbol, its application
                if check(.SYMBOL, .LEFTPAREN) { return try applicationDeclaration() }
                test(where: "expr, before unary", current: peek())
                // otherwise, check if the token after the left paren is an unary operator
                return try unaryDeclaration()
            } //else if match(.QUOTE) { return quoteDeclaration() }
            else {
                //if no left parenthesis is found, it's a literal
                test(where: "expr, literal", current: peek())
                return try literalDeclaration()
            }
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func literalDeclaration() throws -> Expr? {
        do {
            test(where: "literal", current: peek())
            
            if try match(.NUMBER, .STRING, .SYMBOL, .NIL, .FALSe, .TRUe, .MINUS) {
                
                switch previous().type{
                case .MINUS:
                    _ = try match(.NUMBER)
                    
                    var temp: Double?
                    if let a = previous().literal{
                        temp = -(a as! Double)
                    } else {temp = nil}
                    
                    return Expr.Literal(value: temp)
                case .NUMBER, .STRING:
                    return Expr.Literal(value: previous().literal)
                case .NIL:
                    return Expr.Literal(value: nil)
                case .FALSe:
                    return Expr.Literal(value: false)
                case .TRUe:
                    return Expr.Literal(value: true)
                case .SYMBOL:
                    return Expr.Symbol(value: previous().lexeme)
                default:
                    return nil
                }
            }
            return nil
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func unaryDeclaration() throws -> Expr? {
        do {
            test(where: "unary, beginning", current: peek())
            //if the token is Any? of those unary operators...
            if check(.SIN, .COS, .TAN, .CSC, .SEC, .COT, .NOT, .CAR, .CDR, .REFERENCE, .DEREFERENCE) {
                _ = try match(.SIN, .COS, .TAN, .CSC, .SEC, .COT, .NOT, .CAR, .CDR, .REFERENCE, .DEREFERENCE)
                //we store the operator and advance, and we store the next number of tokens as an expression
                let op = previous()
                test(where: "unary, expression", current: peek())
                let expr = try exprDeclaration()
                //we skip the leftover right parenthesis, and send the info into the visitor pattern
                _ = try match(.RIGHTPAREN)
                test(where: "unary, end", current: peek())
                return Expr.Unary(unaryOp: op, value: expr)
            }
            
            return try binaryDeclaration()
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func binaryDeclaration() throws -> Expr? {
        do {
            test(where: "binary, beginning", current: peek())
            //if the token is Any? of those binary operators...
            if check(.EQUAL, .GREATER, .GREATEREQUAL, .LESS, .SLASH, .LESSEQUAL, .PLUSEQUALS) {
                _ = try match(.EQUAL, .GREATER, .GREATEREQUAL, .LESS, .SLASH, .LESSEQUAL, .PLUSEQUALS)
                
                //we store the operator and advance, and we store the next two tokens as an expression
                let op = previous()
                let expr1 = try exprDeclaration()
                let expr2 = try exprDeclaration()
                
                //we skip the leftover right parenthesis, and send the info into the visitor pattern
                _ = try match(.RIGHTPAREN)
                test(where: "binary, end", current: peek())
                return Expr.Binary(binaryOp: op, value1: expr1, value2: expr2)
            }
            return try multiplearyDeclaration()
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func multiplearyDeclaration() throws -> Expr? {
        do {
            test(where: "multipleary, beginning", current: peek())
            //if the token is Any? of those operators that have 2 or more targets...
            if check(.PLUS, .MINUS, .STAR, .AND, .OR, .PRINT) {
                _ = advance()
                //we store the operator and advance, and we store the next x amount of tokens as an expression
                let op = previous()
                
                test(where: "multipleary, first value", current: peek())
                var exprList = [try exprDeclaration()]
                test(where: "multipleary, second value", current: peek())
                while !check(.RIGHTPAREN){
                    let a = try exprDeclaration()
                    exprList.append(a)
                }
                //we skip the leftover right parenthesis, and send the info into the visitor pattern
                _ = try match(.RIGHTPAREN)
                return Expr.Multipleary(multiplearyOp: op, values: exprList)
            }
            
            return try keywordDeclaration()
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func keywordDeclaration() throws -> Expr? {
        test(where: "keyword, beginning", current: peek())
        //if the token is Any? of those keywords, go to the corresponding function
        _ = advance()
        
        switch previous().type {
        case .IF: return try ifDeclaration()
        case .DEFINE: return try defineDeclaration()
        case .LAMBDA: return try lambdaDeclaration()
        case .SETBANG: return try setbangDeclaration()
        case .BEGIN: return try beginDeclaration()
        case .WHILE: return try whileDeclaration()
        case .FOR: return try forDeclaration()
        case .LET: return try letDeclaration()
        case .QUOTE: return try quoteDeclaration()
        case .CONS: return try consDeclaration()
        case .SETVAL: return try setValDeclaration()
        default: return nil
        }
    }
    
    func applicationDeclaration() throws -> Expr? {
        do {
            test(where: "application, before process", current: peek())
            let process = try exprDeclaration()
            
            test(where: "application, before args", current: peek())
            var args: [Expr?]
            if check(.RIGHTPAREN) {
                args = [nil]
            } else {
                args = [try exprDeclaration()]
            }
            
            test(where: "application, before args loop", current: peek())
            while !check(.RIGHTPAREN) {
                args.append(try exprDeclaration())
            }
            
            _ = try match(.RIGHTPAREN)
            return Expr.Application(process: process, args: args)
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* if statement syntax
        (  if  (  <condition>  )  (  <body>  ) else (  <body>  )  )
        ^   ^  ^       ^       ^  ^    ^     ^  ^   ^    ^     ^  ^
    */
    func ifDeclaration() throws -> Expr? {
        do {
            test(where: "if, beginning", current: peek())
            
            // handles the condition
            let isCondLiteral = literalNext()
            if isCondLiteral { _ = try match(.LEFTPAREN) }
            
            test(where: "if, before cond", current: peek())
            let cond = try exprDeclaration()
            
            if isCondLiteral {_ = try match(.RIGHTPAREN)}
            
            // handles the first body
            let isBodyLiteral = literalNext()
            if isBodyLiteral { _ = try match(.LEFTPAREN) }
        
            test(where: "if, before body", current: peek())
            var body = [try exprDeclaration()]
            
            while !check(.RIGHTPAREN,.ELSE){
                body.append(try exprDeclaration())
            }
            
            if isBodyLiteral { _ = try match(.RIGHTPAREN) }
            
            test(where: "if, before else body", current: peek())
            // if there is an else, handles it
            var elseBody: [Expr?]
            if check(.ELSE){
                _ = advance()
                
                let isElseLiteral = literalNext()
                if isElseLiteral { _ = try match(.LEFTPAREN) }
                
                test(where: "if, before else body", current: peek())
                elseBody = [try exprDeclaration()]
                
                while !check(.RIGHTPAREN){
                    body.append(try exprDeclaration())
                }
                
                if isElseLiteral { _ = try match(.RIGHTPAREN) }
                
            } else {elseBody = [nil]}
            
            _ = try match(.RIGHTPAREN)
            
            return Expr.If(condition: cond, body: body, elseBody: elseBody)
                
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* define statement syntax
     (   define   (   <name>   <args>*   )   <body>   )
                    OR
     (   define   <name>   <body>   )
     */
    func defineDeclaration() throws -> Expr? {
        do {
            test(where: "define, beginning", current: peek())
            
            if check(.LEFTPAREN) {  //  syntactic sugar for a lambda
                //get the name and all the arguments for the lambda
                _ = advance()
                
                test(where: "define (sugar), before name", current: peek())
                let name = try exprDeclaration()

                var args: [Expr?]
                
                test(where: "define (sugar), before args loop", current: peek())
                if !check(.RIGHTPAREN) {
                    var temp = [try exprDeclaration()]
                    while !check(.RIGHTPAREN) {
                        temp.append(try exprDeclaration())
                    }
                    args = temp
                } else { args = [nil]}
                
                _ = try match(.RIGHTPAREN)
                
                //get the body
                
                test(where: "define (sugar), before body", current: peek())
                var body = [try exprDeclaration()]
                
                while !check(.RIGHTPAREN){
                    body.append(try exprDeclaration())
                }
            
                _ = try match(.RIGHTPAREN)
                if let n = name as? Expr.Symbol {
                    if let arguments = args as? [Expr.Symbol?]{
                        return Expr.Define(name: n, body: [Expr.Lambda(args: arguments, body: body, env: nil)])
                    }
                    throw ParseError.parserTypeMismatch("The arguments in a define statement must be a symbol: (define (<symbol> <symbol>*) <body>*)"  )
                }
                throw ParseError.parserTypeMismatch("The name in a define statement must be a symbol: (define (<symbol> <symbol>*) <body>*)" )
            } else {
                //second syntax for define
                test(where: "define, before name", current: peek())
                let name = try exprDeclaration()
                test(where: "define, before body", current: peek())
                
                let isBodyLiteral = literalNext()
                if isBodyLiteral {_ = try match(.LEFTPAREN)}
                
                var body = [try exprDeclaration()]
                
                while !check(.RIGHTPAREN){
                    body.append(try exprDeclaration())
                }
                
                if isBodyLiteral {_ = try match(.RIGHTPAREN)}
                _ = try match(.RIGHTPAREN)
                
                if let n = name as? Expr.Symbol {
                    return Expr.Define(name: n, body: body)
                }
                throw ParseError.parserTypeMismatch("The name in a define statement must be a symbol: (define <symbol> <body>*)"  )
            }
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* lambda statement syntax
     (   lambda    (  <arg>*   )  <body>  )
     */
    func lambdaDeclaration() throws -> Expr? {
        do {
            test(where: "lambda, before args", current: peek())
            var argList: [Expr?]
            _ = try match(.LEFTPAREN)
            if check(.RIGHTPAREN) {
                argList = []
            }else {
                argList = [try exprDeclaration()]
                test(where: "lambda, before args loop", current: peek())
                // handles the arguments
                while !check(.RIGHTPAREN) {
                    argList.append(try exprDeclaration())
                }
            }
            _ = try match(.RIGHTPAREN)
            
            
            test(where: "lambda, before body", current: peek())
            var body = [try exprDeclaration()]
            
            while !check(.RIGHTPAREN){
                body.append(try exprDeclaration())
            }
            
            _ = try match(.RIGHTPAREN)
            
            if let argumentList = argList as? [Expr.Symbol?] {
                return Expr.Lambda(args: argumentList, body: body, env:nil)
            }
            throw ParseError.parserTypeMismatch("Arguments in a Lambda expression must be a symbol: (lambda (<symbol>*) <body>)" )
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* Cons syntax
     (   cons   <a>   <b>   )
     */
    func consDeclaration() throws -> Expr? {
        do {
            test(where: "cons, beginning", current: peek())
            
            let expr1 = try exprDeclaration()
            let expr2 = try exprDeclaration()
            
            //we skip the leftover right parenthesis, and send the info into the visitor pattern
            _ = try match(.RIGHTPAREN)
            test(where: "cons, end", current: peek())
            
            return Expr.Cons(expr1: expr1, expr2: expr2)
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* Quote syntax
        '   (   <arg1>  <arg2> ... <argn>   )
        turns into
        (cons <arg1> (cons <arg2> ... (cons <argn> <nil> )))
     */
    func quoteDeclaration() throws -> Expr? {
        do{
            _ = try match(.LEFTPAREN)
            
            if check(.RIGHTPAREN) {
                _ = try match(.RIGHTPAREN)
                return Expr.Literal(value: nil)
            }
            
            var items = [try exprDeclaration()]
            
            while !check(.RIGHTPAREN) {
                items.append(try exprDeclaration())
            }
            
            _ = try match(.RIGHTPAREN)
            
            
            let t = items.remove(at: items.endIndex - 1)
            print(t?.toString())
            var consExpr = Expr.Cons(expr1: t, expr2: nil)
            
            for item in items.reversed(){
                let temp = consExpr
                consExpr = Expr.Cons(expr1: item, expr2: temp)
            }
            
            return consExpr
            
        } catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
        
    }
    
    
    //          set! syntax:
    //  ( set    id       expr  )
    //  ^  ^      ^         ^   ^
    func setbangDeclaration() throws -> Expr? {
        do {
            test(where: "setbang, before variable name", current: peek())
            
            let name = try literalDeclaration()
            
            //variable value can be Any? expression
            test(where: "setbang, before variable value", current: peek())
            let value = try exprDeclaration()
            _ = try match(.RIGHTPAREN)
            
            return Expr.SetBang(name: name, val: value)
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    func beginDeclaration() throws -> Expr? {
        do {
            test(where: "begin, beginning", current: peek())
            
            var body = [try exprDeclaration()]
            
            while !check(.RIGHTPAREN) {
                body.append(try exprDeclaration())
            }
            _ = try match(.RIGHTPAREN)
            
            let returnExpr = body.remove(at: body.endIndex - 1)

            return Expr.Begin(exprs: body, expr: returnExpr)
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* while syntax:
     (   while   (   <cond>   )   body   )
    */
    func whileDeclaration() throws -> Expr? {
        do {
            // saves cond and body...
            test(where: "while, beginning", current: peek())
            let isCondLiteral = literalNext()
            if isCondLiteral {_ = try match(.LEFTPAREN)}
            
            test(where: "while, before body", current: peek())
            let cond = try exprDeclaration()
            
            if isCondLiteral {_ = try match(.RIGHTPAREN)}
            
            var body = [try exprDeclaration()]
            
            while !check(.RIGHTPAREN){
                body.append(try exprDeclaration())
            }
            _ = try match(.RIGHTPAREN)
            // ...then moves everything around to turn it into a define statement
            
            return Expr.While(cond: cond, body: body)
            
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* For statement syntax:
     (   for   (   (  =   i   <number>  )   <cond>     <operation>   )   <body>   )
     turns into:
     (define i <number>) (while (<cond>) <body> + <operation>)
     */
    func forDeclaration() throws -> Expr? {
        do {
            test(where: "for, beginning", current: peek())
            _ = try match(.LEFTPAREN)
            _ = try match(.LEFTPAREN)
            
            test(where: "for, before i", current: peek())
            _ = try match(.EQUAL)
            let i = try exprDeclaration()
            
            test(where: "for, before iVal", current: peek())
            let iVal = try exprDeclaration()
            _ = try match(.RIGHTPAREN)
            
            // extracts the comparison
            let condIsLiteral = literalNext()
            if condIsLiteral {_ = try match(.LEFTPAREN)}
            
            test(where: "for, before cond", current: peek())
            let cond = try exprDeclaration()
           
            if condIsLiteral {_ = try match(.RIGHTPAREN)}
            
            // extracts the operation on i
            let operationIsLiteral = literalNext()
            if operationIsLiteral {_ = try match(.LEFTPAREN)}
            
            test(where: "for, before operation", current: peek())
            let operation = try exprDeclaration()
            
            if operationIsLiteral {_ = try match(.RIGHTPAREN)}
            
            _ = try match(.RIGHTPAREN)
            
            // extracts the body
            let bodyIsLiteral = literalNext()
            if bodyIsLiteral {_ = try match(.LEFTPAREN)}
            
            test(where: "for, before body", current: peek())
            var body = [try exprDeclaration()]
            
            if bodyIsLiteral {_ = try match(.RIGHTPAREN)}
            
            while !check(.RIGHTPAREN) { body.append(try exprDeclaration())}
            
            _ = try match(.RIGHTPAREN)
            
            // transforms for into while:
            let define = Expr.Define(name: i as! Expr.Symbol, body: [iVal])
            body.append(Expr.SetBang(name: i as! Expr.Symbol, val: operation))
            
            let whileExpr = Expr.While(cond: cond, body: body)
            return Expr.Consecutive(expr1: define, expr2: whileExpr)
            
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
    
    /* let syntax:
    (   let   (   [   <id>    <val>   ]*   )   body   )
     Is actually:
    (   (   lambda   (   <id>*   )   (   body   )   )   <val>*   )
     */
    func letDeclaration() throws -> Expr? {
        do {
            test(where: "let, beginning", current: peek())
            _ = try match(.LEFTPAREN)
            _ = try match(.LEFTPAREN)
            
            test(where: "let, before id", current: peek())
            var idList = [try exprDeclaration()]
            test(where: "let, before val", current: peek())
            var valList = [try exprDeclaration()]
            _ = try match(.RIGHTPAREN)
            
            while !check(.RIGHTPAREN) {
                _ = try match(.LEFTPAREN)
                idList.append(try exprDeclaration())
                valList.append(try exprDeclaration())
                _ = try match(.RIGHTPAREN)
            }
            
            _ = try match(.RIGHTPAREN)
            test(where: "let, before body,", current: peek())
            var body = [try exprDeclaration()]
            
            while !check(.RIGHTPAREN){
                body.append(try exprDeclaration())
            }
            _ = try match(.RIGHTPAREN)
            
            if let idlst = idList as? [Expr.Symbol?]{
                return Expr.Application(process: Expr.Lambda(args: idlst, body: body, env: nil), args: valList)
            }
            throw ParseError.parserTypeMismatch("Arguments in a Lambda expression must be a symbol: (lambda (<symbol>*) <body>)" )
            
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }

    func setValDeclaration() throws -> Expr? {
        do {
            test(where: "setval, beginning", current: peek())

            _ = try match(.LEFTPAREN)
            
            test(where: "setval, before name loop", current: peek())
            var nameList = [try exprDeclaration()]
            
            while !check(.RIGHTPAREN) {
                nameList.append(try exprDeclaration())
            }
            _ = try match(.RIGHTPAREN)
            
            test(where: "setval, before value loop", current: peek())
            _ = try match(.LEFTPAREN)
            
            var valueList: [Expr?] = []
            for _ in nameList{
                valueList.append(try exprDeclaration())
            }
            
            _ = try match(.RIGHTPAREN)
            
            return Expr.SetVal(names: nameList, values: valueList)
        }  catch {
            print("Unexpected Error: \(error)")
            exit(0)
        }
    }
}

//--------------------- Helper Methods ---------------------------
extension Parser {
    func match(_ types: [TokenType]) throws -> Bool {
        for type in types {
            if check(type) {
                _ = advance()
                return true
            }
        }
        var message = ""
        for a in types{
            message.append(a.rawValue + ", ")
        }
        throw ParseError.parseFailure("Unexpected character: got \(peek().type), expected: \(message)"  )
    }

    func match(_ types: TokenType...) throws -> Bool {
        return try match(types)
    }
    
    func check(_ tokenType: TokenType) -> Bool {
        if isAtEnd() {
            return false
        }
        return peek().type == tokenType
    }
    
    func check(_ tokenTypes: TokenType...) -> Bool {
        for type in tokenTypes {
            if check(type) {
                return true
            }
        }
        return false
    }

    func checkNext(_ tokenType: TokenType) -> Bool {
        if isAtEnd() { return false }
        if tokens[current + 1].type == .EOF { return false }
        return tokens[current + 1].type == tokenType
    }
    
    func advance() -> Token {
        if !isAtEnd() {
            current += 1
        }
        return previous()
    }
    
    func previous() -> Token {
        return tokens[current - 1]
    }
    
    func isAtEnd() -> Bool {
        return peek().type == .EOF
    }
    
    func peek() -> Token {
        return tokens[current]
    }
    
    func literalNext() -> Bool{
        return checkNext(.TRUe) || checkNext(.FALSe) || checkNext(.NUMBER) || checkNext(.STRING)
    }
    
    func consume(_ type: TokenType, message: String) {
        if check(type) {
            _ = advance()
        }
    }
}

extension Parser {
    func test(where l: String, current c: Token){
        if testMode {
            print("#\(callNum) - Location: [\(l)] --- Current: [\(c)]")
            callNum += 1
        }
    }
}

