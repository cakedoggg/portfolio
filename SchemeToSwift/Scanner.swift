//
//  Scanner.Swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/11/20.
//

import Foundation


import Foundation

class Scanner {
  private let source: String
  private var tokens = [Token]()

  private var start: String.Index
  private var current: String.Index
  private var line = 1

  static let keywords: Dictionary<String, TokenType> = [
    "and": .AND,
   // "class": .Class,
    "else": .ELSE,
    "false": .FALSe,
    "for": .FOR,
    "if": .IF,
    "nil": .NIL,
    "or": .OR,
    "true": .TRUe,
    "while": .WHILE,
    "lambda":  .LAMBDA,
    "ref": .REFERENCE,
    "deref": .DEREFERENCE,
    "\'": .QUOTE,
    "print": .PRINT,
    "cons": .CONS,
    "car": .CAR,
    "cdr": .CDR,
    "set": .SETBANG,
    "setvalues": .SETVAL,
    "begin": .BEGIN,
    "not": .NOT,
    "define": .DEFINE,
    "sin": .SIN,
    "cos": .COS,
    "tan": .TAN,
    "cot": .COT,
    "sec": .SEC,
    "csc": .CSC,
    "let": .LET
    ]

  enum Errors: Error{
    case SyntaxError
    case EOFError
  }
  
  init(source: String){
    self.source = source

    start = source.startIndex
    current = start
  }

  func scanTokens() -> [Token] {
    while isAtEnd() == false {
      start = current

      scanToken()
    }

    let finalToken = Token(type: .EOF, lexeme: "", literal: nil, line: line)
    tokens.append(finalToken)

    return tokens
  }

  func scanToken() {
    let a = advance()

    //add apostrophe,
    switch a {
        case "(":
            addToken(type: .LEFTPAREN)
        case ")":
            addToken(type: .RIGHTPAREN)
        case "\'":
            addToken(type: .QUOTE)
        case ".":
            addToken(type: .DOT)
        case "/":
            addToken(type: .SLASH)
        case "+" where match("="):
            addToken(type: .PLUSEQUALS)
        case "+":
            addToken(type: .PLUS)
        case "*":
            addToken(type: .STAR)
        case "-":
            addToken(type: .MINUS)
        case ";": // handles single-line comments
            while peek() != "\n" && isAtEnd() == false {
              _ = advance()
            }
        case "=":
            addToken(type: .EQUAL)
        case "<" where match("="):
            addToken(type: .LESSEQUAL)
        case "<":
            addToken(type: .LESS)
        case ">" where match("="):
            addToken(type: .GREATEREQUAL)
        case ">":
            addToken(type: .GREATER)
        case " ", "\r", "\t":
            break
        case "\"":
            string()
        case _ where isDigit(a):
            number()
        case _ where isAlpha(a):
            symbol()
        default:
            print("unexpected char")
    }
  }

// ------methods that deal with digits and alphas------
  private func symbol() {
    while isAlphaNumeric(peek()) {
        _ = advance()
    }

    // See if the symbol is a reserved word
    let text = String(source[start ..< current])
    
    // unwraps the optional value and passes the result of the keyword dictionary call or if it's null then sends in .symbol
    let type = Scanner.keywords[text] ?? .SYMBOL

    addToken(type: type, literal: text)
  }

  private func number() {
    //https://dmitripavlutin.com/useful-details-about-underscore-keyword-in-swift/
    while isDigit(peek()) {
      _ = advance()
    }

    if peek() == "." && isDigit(peekNext()) {
      // Consume the "."
      _ = advance()
    }

    while isDigit(peek()) {
      _ = advance()
    }

    let numberString = String(source[start ..< current])
    let number = Double(numberString)!
    addToken(type: .NUMBER, literal: number)
  }

  private func string() {
    while peek() != "\"" && isAtEnd() == false {
      if peek() == "\n" {
       line += 1
      }
     _ = advance()
   }

   // String without closing brackets
    if isAtEnd() {
      print("Unterminated string.")
     return
   }

    // The closing "\""
     _ = advance()

    // Trim the surrounding quotes.
    let newStart = source.index(after: start)
    let newCurrent = source.index(before: current)
    let value = String(source[newStart ..< newCurrent])

    addToken(type: .STRING, literal: value)
  }
  
// --------------helper methods----------------
  private func isDigit(_ char: Character) -> Bool {
    let digitList = CharacterSet.decimalDigits

// returns true if the char is a digit
    return digitList.contains(String(char).unicodeScalars.first!)
  }

  private func isAlpha(_ char: Character) -> Bool {
    let unicodeVal = String(char).unicodeScalars.first!

// returns true if the character is a lowercase or uppercase letter (or "_")
    return CharacterSet.lowercaseLetters.contains(unicodeVal)
       || CharacterSet.uppercaseLetters.contains(unicodeVal)
       || unicodeVal == "_"
  }

  private func isAlphaNumeric(_ char: Character) -> Bool {
    let unicodeVal = String(char).unicodeScalars.first!
    
    return CharacterSet.alphanumerics.contains(unicodeVal)
  }


  private func addToken(type: TokenType, literal: Any? = nil){
    let text = String(source[start ..< current])
    let token = Token(type: type, lexeme: text, literal: literal, line: line)
    tokens.append(token)
  }

  private func advance() -> Character {
    let temp = current
    current = source.index(after:current)
    let char = source[temp]
    return char
  }

 private func peek() -> Character {
    guard current != source.endIndex else { return "\0"}
    return source[current]
 }

 private func peekNext() -> Character {
  guard current != source.endIndex else {
     return "\0"
  }

  let next = source.index(after: current)
  guard next != source.endIndex else {
    return "\0"
  }

  return source[next]
 }

  func isAtEnd() -> Bool {
    return current == source.endIndex
   }

  private func match(_ expected: Character) -> Bool {
      guard isAtEnd() == false else { return false }
      guard source[current] == expected else { return false }
      
      current = source.index(after: current)
      return true
    }
}
