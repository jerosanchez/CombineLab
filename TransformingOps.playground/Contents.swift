import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "collect", action: {
    ["A", "B", "C", "D", "E"].publisher
        // Buffers values until completion and then returns
        // an array with all the values buffered;
//        .collect()
        
        // Alternatively, you can specify how many values
        // to "group" in each returned collection;
        // on completion it returns the values left
        .collect(2)
        
        .sink(receiveCompletion: {
            print($0)
        }, receiveValue: {
            print("Received value: ", $0)
        })
        .store(in: &subscriptions)
    
})
