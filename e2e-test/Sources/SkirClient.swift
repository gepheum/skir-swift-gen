public enum SkirClient {
    public final class Box<T> {
        let value: T
        init(_ value: T) { self.value = value }
    }
}

extension SkirClient.Box: Equatable where T: Equatable {
    public static func == (lhs: SkirClient.Box<T>, rhs: SkirClient.Box<T>) -> Bool {
        lhs.value == rhs.value
    }
}

extension SkirClient {

    public enum KeepOrSet<T> {
        case keep
        case set(T)
    }
}
