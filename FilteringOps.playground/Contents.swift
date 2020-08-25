import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// NOTE:
// Most of the filtering operators have their tryXXX() counterpart;
// those counterparts allow to execute code that can throw, and in that case
// they just complete the stream with the error

example(of: "filter", action: {
    let numbers = (1...10).publisher
    
    numbers
        .filter({ $0.isMultiple(of: 3) })
        
        .collect()
        .sink(receiveValue: { print( "Received values: ", $0) })
        .store(in: &subscriptions)
})

example(of: "removeDuplicates", action: {
    let words = "hey hey there! want to listen to mister mister ?"
        .components(separatedBy: " ")
        .publisher
    
    words
        .removeDuplicates()
        
        .collect()
        .map { $0.joined(separator: " ") }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
})
