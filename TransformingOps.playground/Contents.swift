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

example(of: "map", action: {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    [123, 4, 56].publisher
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""}
        .sink(receiveValue: { print("Received value: ", $0) })
        .store(in: &subscriptions)
})

example(of: "map with key paths", action: {
    let publisher = PassthroughSubject<Coordinate, Never>()
    
    publisher
        // There are versions of map that can map up to
        // three different key paths
        .map(\.x, \.y)
        .sink(receiveValue: {
            print("Received value: (\($0), \($1)), is in quadrant \(quadrantOf(x: $0, y: $1))")})
        .store(in: &subscriptions)
    
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(Coordinate(x: 0, y: 5))
})

example(of: "tryMap", action: {
    Just("directory name that does not exist")
        .tryMap {
            try FileManager.default.contentsOfDirectory(atPath: $0)}
        .sink(
            receiveCompletion: { print("Completed with: ", $0) },
            receiveValue: { print("Contents of file: ", $0) })
        .store(in: &subscriptions)
})

example(of: "flatMap", action: {
    // flatMap operator merges ("flattens") values coming from
    // different streams into the same stream
    
    let charlotte = Chatter(name: "Charlotte", message: "Hi, I'm Charlotte!")
    let james = Chatter(name: "James", message: "Hi, I'm James!")
    
    let chat = CurrentValueSubject<Chatter, Never>(charlotte)
    
    chat
        // To keep memory footprint low, we set the max number
        // of publishers that can be "flatten" in the same stream;
        // default maxPublishers value in .unlimited
        .flatMap(maxPublishers: .max(2))
            { $0.message }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
    
    charlotte.message.value = "How's it going?"
    
    // We add a second publisher to the stream, i.e.
    // values to both charlotte.message and james.message are now
    // merged ("flaten") in the same value stream;
    
    // note how we add a new stream by just re-assigning
    chat.value = james
    
    james.message.value = "James: Doing great. You?"
    charlotte.message.value = "Charlotte: I'm doing fine, thanks."
    
    let morgan = Chatter(name: "Morgan", message: "Hey guys, what are you up to?")
    chat.value = morgan  // Morgan tries to join the conversation
    
    // Since maxPublishers is 2, Morgan messages are ignored
    charlotte.message.value = "Charlotte: Did you hear something?"
})

example(of: "replaceNil", action: {
    ["A", nil, "B"].publisher
        .replaceNil(with: "-")
        
        // replaceNil() does not change the optional nature of the values,
        // just replaces nil values with something else;
        // thus, to avoid the "Expression implicitly coerced from 'String?' to 'Any'" warning
        // we just map the output of replaceNil, force unwrapping the values
        // (at this point we know there'll never arrive nil values)
        .map { $0! }
        
        .sink(receiveValue: { print("Received value: ", $0) })
        
        .store(in: &subscriptions)
    
        // While the coalescing operator ?? can return a new nil,
        // the replaceNil() operator does not
})

example(of: "replaceEmpty(with:)", action: {
    // An Empty publishers completes immediately,
    // i.e. does not emit any value
    let empty = Empty<Int, Never>()
    
    empty
        // If receives a completion event withou having emitted any value,
        // this operator emits at least this value and then completes
        .replaceEmpty(with: 1)
        
        .sink(
            receiveCompletion: { print("Completed with: ", $0) },
            receiveValue: { print("Received value: ", $0) })
        .store(in: &subscriptions)
})
