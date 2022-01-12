//
//  Token.Swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/11/20.
//

import Foundation

enum TokenType : String{
    //single character
    case LEFTPAREN, RIGHTPAREN, SEMICOLON
    //literals
    case SYMBOL, STRING, NUMBER, NIL, FALSe, TRUe
    //unary
    case DOT, NOT, SIN, COS, TAN, COT, CSC, SEC, CAR, CDR, REFERENCE, DEREFERENCE, PLUSEQUALS
    //binary
    case EQUAL, GREATER, GREATEREQUAL, LESS, LESSEQUAL, SLASH
    //multipleary
    case MINUS, PLUS, AND, OR, STAR, PRINT
    //keywords
    case IF, ELSE, DEFINE, LAMBDA, SETBANG, BEGIN, FOR, WHILE, LET, SETVAL, QUOTE, CONS
    
    case EOF
}

struct Token: CustomStringConvertible {
    let type: TokenType
    let lexeme: String
    let literal: Any?
    let line: Int

    init(type: TokenType, lexeme: String, literal: Any? = nil, line: Int) {
        self.type = type
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
    }

    var description: String{
        let literalText: String
        if let literal = literal {
            literalText = " -> '\(literal)'"
        } else {
            literalText = ""
        }
        return "\(type): '\(lexeme)  '\(literalText)"
    }
    
}
