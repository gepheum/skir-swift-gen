public enum SkirClient {
    public final class Box<T> {
        let value: T
        init(_ value: T) { self.value = value }
    }

    public enum KeepOrSet<T> {
        case keep
        case set(T)
    }
}
