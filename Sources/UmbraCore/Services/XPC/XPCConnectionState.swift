/// State of an XPC connection
public enum XPCConnectionState: String {
    /// Connection is disconnected
    case disconnected
    /// Connection is connecting
    case connecting
    /// Connection is connected
    case connected
    /// Connection is disconnecting
    case disconnecting
    /// Connection was interrupted
    case interrupted
    /// Connection was invalidated
    case invalidated

    /// String representation of the state
    public var description: String {
        rawValue
    }
}
