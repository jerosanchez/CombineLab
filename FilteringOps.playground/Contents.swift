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
        .sink(receiveValue: { print("Received words: ", $0) })
        .store(in: &subscriptions)
})

example(of: "compactMap", action: {
    let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher
    
    strings
        // As its Swift counterpart, it removes nil values from the stream
        .compactMap { Float($0) }
    
        .collect()
        .sink(receiveValue: { print("Received values: ", $0) })
        .store(in: &subscriptions)
})

example(of: "ignoreOutput", action: {
    let numbers = (1...10_000).publisher
    
    numbers
        .ignoreOutput()
        
        .sink(
            receiveCompletion: {
                print("Completed with: ", $0) },
            receiveValue: {
                print("Received values: ", $0) })  // This should never execute
        .store(in: &subscriptions)
})

example(of: "first(where:)", action: {
    let numbers = (1...9).publisher
    
    numbers
//        .print("numbers")  // Verify first() sends a cancel event as soon as it matches
        .first(where: { $0 % 2 == 0 })  // First even number
        
        .sink(
            receiveCompletion: {
                print("Completed with: ", $0) },
            receiveValue: { print("Received value: ", $0) })
        .store(in: &subscriptions)
})

example(of: "last(where:)", action: {
    let numbers = (1...9).publisher
    
    numbers
//        .print("numbers")  // Verify last() waits until completion to emit the value
        .last(where: { $0 % 2 == 0 })  // Last even number
        
        .sink(
            receiveCompletion: {
                print("Completed with: ", $0) },
            receiveValue: { print("Received value: ", $0) })
        .store(in: &subscriptions)
    
    // If the publisher is a PassthroughSubject, i.e. we are manually emitting values,
    // remember to complete the sequence so that last() can finish
})

example(of: "dropFirst", action: {
    let numbers = (1...10).publisher
    
    numbers
        .dropFirst(8)
        
        .collect()
        .sink(receiveValue: { print("Received values: ", $0) })
        .store(in: &subscriptions)
})

example(of: "drop(while:)", action: {
    let numbers = (1...10).publisher
    
    numbers
        .drop(while: { $0 % 5 != 0 })  // Start emitting when the first multiple of 5 is found
        
        .collect()
        .sink(receiveValue: { print("Received values: ", $0) })
        .store(in: &subscriptions)

})

example(of: "drop(untilOutputFrom:)", action: {
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    taps
        .drop(untilOutputFrom: isReady)
        
        .collect()
        .sink(receiveValue: { print("Received values: ", $0) })
        .store(in: &subscriptions)
    
    (1...5).forEach { n in
        taps.send(n)
        if n == 3 {
            isReady.send()
        }
    }
    
    taps.send(completion: .finished)
})

example(of: "prefix", action: {
    let numbers = (1...10).publisher
    
    numbers
        // The prefix operator does the opposite than drop: it continues
        // emitting values until the condition is met, ignoring the rest;
        // it also has the same variants as drop (see below)
        .prefix(2)
    
        .collect()
        .sink(
            receiveCompletion: {
                print("Completed with: ", $0) // this operator is lazy, terminates asap
        },
            receiveValue: {
                print("Received values: ", $0) })
        .store(in: &subscriptions)
})

example(of: "prefix(while:)", action: {
    let numbers = (1...10).publisher
    
    numbers
        .prefix(while: { $0 < 5 })
    
        .collect()
        .sink(
            receiveCompletion: {
                print("Completed with: ", $0) // this operator is lazy, too
        },
            receiveValue: {
                print("Received values: ", $0) })
        .store(in: &subscriptions)
})

example(of: "prefix(untilOutputFrom:)", action: {
    let isReady = PassthroughSubject<Void, Never>()
    let taps = PassthroughSubject<Int, Never>()
    
    taps
        .prefix(untilOutputFrom: isReady)
    
        .collect()
        .sink(
            receiveCompletion: {
                print("Completed with: ", $0) // this operator is lazy, too
        },
            receiveValue: {
                print("Received values: ", $0) })
        .store(in: &subscriptions)
    
    (1...5).forEach { n in
        taps.send(n)
        if n == 2 {
            isReady.send()
        }
    }
    
    taps.send(completion: .finished)
})
