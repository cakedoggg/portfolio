//
//  main.swift
//  SchemeToSwift
//
//  Created by Michał Cieslik on 12/11/20.
//

import Foundation
let cfExample = "(for ( (= a 0) (<= a 10) (+ a 1) ) (if (> a 5) (print a) else (print \"Not over 5\")))"
let lambdaExample = "(define mycounter (let ((count 0)) (lambda () (set count (+ count 1)) count))) (print (mycounter)) (print (mycounter)) (print (mycounter))"
let consExample = "(define a '(1 2 (cons 3 4))) (print (car a)) (print (car (cdr a))) (print (car (car (cdr (cdr a)))))"
let refDerefExample = "(define a 100) (define referenceOfa (ref a)) (print \"Reference: \"referenceOfa \"\nValue at that reference: \" (deref referenceOfa))"

let scanner = Scanner(source: refDerefExample)
let scanarray = scanner.scanTokens()
let parser = Parser(tokens: scanarray)

let parseArray = parser.parse()

//print(scanarray)

for a in parseArray {
   //print(a.toString())
}
let interpreter = Interpreter(parseArray)

