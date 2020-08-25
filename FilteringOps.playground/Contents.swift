import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// NOTE:
// Most of the filtering operators have their tryXXX() counterpart;
// those counterparts allow to execute code that can throw, and in that case
// they just complete the stream with the error

example(of: "filter", action: {
    let publisher = (1...10).publisher
    
    publisher
        .filter({ $0.isMultiple(of: 3) })
        
        .collect()
        .sink(receiveValue: { print( "Received values: ", $0) })
        .store(in: &subscriptions)
})
