import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

// MARK: - Examples

example(of: "NC publisher + observer (the old way)", action: {
    let someNotification = Notification.Name("SomeNotification")
    
    let center = NotificationCenter.default
    let observer = center.addObserver(forName: someNotification, object: nil, queue: nil) { notification in
        print("Notification received (using an observer)!")
    }
    
    center.post(name: someNotification, object: nil)
    
    center.removeObserver(observer)
})

example(of: "NC publisher + Subscribing with basic sink()", action: {
    let someNotification = Notification.Name("SomeNotification")
    
    // Notification Center is extended to support Combine
    let publisher = NotificationCenter.default
        .publisher(for: someNotification, object: nil)
    
    let center = NotificationCenter.default
    
    // If we post a notification here, the publisher wouldn't emit it;
    // we need at least one subscriber "listening"
    
    let subscription = publisher
        .sink { _ in
            print("Notification received (using a publisher/subscriber)!")
    }
    
    center.post(name: someNotification, object: nil)
    
    // Not really needed in a Playground, but highly adviceble in a real project;
    // not calling the cancel() method causes the subscription to exist
    // until the publisher completes, or normal memory management causes a
    // stored subscription to be deinitialized.
    subscription.cancel()
})

example(of: "Just publisher + sink(receiveCompletion:receiveValue:)", action: {
    let just = Just("Hello world!")
    
    // Another variant on sink(), that can handle both
    // the value emitted and the completion event
    
    _ = just
        .sink(
            receiveCompletion: {
                print("Received completion: ", $0)
        },
            receiveValue: {
                print("Received value: ", $0)
        })
    
    _ = just
        .sink() {
            print("Recieved value (another): ", $0)
        }
})

example(of: "Subscribing with assign(to:on:)", action: {
    class SomeObject {
        var value: String = "" {
            didSet {
                print(value)
            }
        }
    }
    
    let object = SomeObject()
    
    // Arrays are also extended to support Combine :-)
    let publisher = ["Hello", "world!"].publisher
    
    // We specify the keypath to the property of the object
    // to which we want to assign the emitted value
    _ = publisher.assign(to: \.value, on: object)
})

example(of: "Custom subscriber", action: {
    // Ranges, another type that support Combine!!!
    let publisher = (1...6).publisher
    
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never  // Might be an Error type
        
        func receive(subscription: Subscription) {
            // Called on subscription
            print("Subscriber has been connected to a publisher")
            
            // Inform the publisher how many values we are willing to receive,
            // in this case, up to 3 values
            subscription.request(.max(3))
        }
        
        func receive(_ input: Int) -> Subscribers.Demand {
            // Called whenever a new value is emitted by the publisher
            print("Received value: ", input)
            
            // Inform the publisher we won't adjust our demand;
            // we won't handle more values
            return .none  // equivalent to .max(0)
            
            // Alternatively, we could have adjusted our demand to .unlimited
            // to handle all possible emitted events
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            // Called whenever the completion event is emitted by the publisher;
            // since we decided to handle up to 3 values, if the publisher
            // emitts more than two events, we won't ever receive the completion event
            print("Received completion: ", completion)
        }
    }
    
    // Let's go testing the custom subscriber...
    
    publisher.subscribe(IntSubscriber())
})

example(of: "Future", action: {
    // A Future is a publisher that will eventually produce a single value and finish, or fail
    
    // A Promise is a type alias closure that receives a Result containing either
    // a single value published by the Future, or an error
    
    func makeAddOneFuture(to integer: Int, afterDelay delay: TimeInterval) -> Future<Int, Never> {
        Future<Int, Never> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                promise(.success(integer + 1))
            }
        }
    }
    
    // WARNING: delay set to 0 secs to avoid delaying the playground
    // Set some value (for example, 3 secs), whenever you want to test this case
    let future = makeAddOneFuture(to: 1, afterDelay: 0)
    
    future.sink(
        receiveCompletion: {
            print("Future resolved (completed): ", $0) },
        receiveValue: {
            print("\nFirst subscription")
            print("Promised value received: ", $0)
            
        // Store the subscription so it continues living until the Future is resolved
        }).store(in: &subscriptions)
    
    // Second subcription receives the value immediately;
    // the reason is that Futures execute as soon as they are created,
    // the do not need to have a subcriber attached to start
    
    future.sink(
        receiveCompletion: {
            print("Future resolved (completed): ", $0) },
        receiveValue: {
            print("\nSecond subscription")
            print("Promised value received: ", $0)
            
        // Store the subscription so that it continues living until the Future is resolved
        }).store(in: &subscriptions)
})

example(of: "PassthroughSubject", action: {
    enum SomeError: Error {
        case test
    }
    
    final class StringSubscriber: Subscriber {
        typealias Input = String
        typealias Output = SomeError
        
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        func receive(_ input: String) -> Subscribers.Demand {
            print("Received value: ", input)
            
            // The returned value is added up to the current allowed demand;
            // in this case, if the input is "World", the new adjusted demand will be 3;
            // this allows us to dynamically adjust the demand
            return input == "World" ? .max(1) : .none
        }
        
        func receive(completion: Subscribers.Completion<SomeError>) {
            print("Received completion: ", completion)
        }
    }
    
    // A subject act as a publisher that allows non-Combine (i.e. imperative) code
    // to send values to whatever is subscribed to the subject
    
    let subject = PassthroughSubject<String, SomeError>()
    
    // First subscription, using our custom Combine subscriber
    
    _ = subject.subscribe(StringSubscriber())
    
    // Second subscription, using sink directly on our subject
    
    let subscription = subject
        .sink(
            receiveCompletion: {
                print("Received completion (sink): ", $0)
        },
            receiveValue: {
                print("Received value (sink): ", $0)
        })

    subject.send("Hello")
    subject.send("World")
    
    // If we cancel our second subscription, the custom publisher still receives the emitted events
    
    subscription.cancel()
    subject.send("Still there?")
    
    // Once the subject completes the publishing, all subscribers receive the completion event
    // and stop receiving further events (as expected from any publisher)
        
    subject.send(completion: .finished)

    // Alternatively, we could complete with a .failure(SomeError.test)
    
    subject.send("How about now?")
})

example(of: "CurrentValueSubject", action: {
    var subscriptions = Set<AnyCancellable>()
    
    // A current value subject is a subject that can be inspected to know its current value;
    // thus, it needs to be initialized with a first value
    
    let subject = CurrentValueSubject<Int, Never>(0)
    
    subject
        .print()  // trace subscription & cancelation
        .sink(receiveValue: { print("Received value: ", $0) })
        .store(in: &subscriptions)
    
    // At this moment, the subscription has already received the initial value, as expected
    
    subject.send(1)
    subject.send(2)
    
    // We can inspect the value of the subject at any time:
    
    print("Current value (inspected): ", subject.value)
    
    // We can even emit events by assigning a new value to the subject!!! :-O
    // ...but we cannot assign a completion event
    
    subject.value = 3
    print("Current value (inspected again):", subject.value)
    
    // New subscriptions start receiving the current value and on...
    
    subject
        .print()
        .sink(receiveValue: { print("Received value (second): ", $0) })
        .store(in: &subscriptions)
    
    // By using the print() trace before subscription we can test
    // that cancel() is called automatically when the subscriptions variable
    // goes out of scope (acting as a disposal bag)
})

example(of: "Type erasure", action: {
    let subject = PassthroughSubject<Int, Never>()
    
    // When we want subscribers to subscriber to receive events without being able to
    // access additional details about the publisher, we use type-erased publishers;
        
    let publisher = subject.eraseToAnyPublisher()
    
    publisher
        .sink(receiveValue: { print("Received value: ", $0) })
        .store(in: &subscriptions)
        
    subject.send(0)
    
    // Thanks to AnyPublisher, we have no send(_:) method; it also hides the fact that
    // the publisher is actually a PassthroughSubject

//    publisher.send(1)  // not possible
})
