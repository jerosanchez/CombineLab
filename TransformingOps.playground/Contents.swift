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

