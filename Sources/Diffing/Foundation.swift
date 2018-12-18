import Foundation

#if swift(>=5.0)
extension DataProtocol : OrderedCollection {}
#else
extension Data : OrderedCollection {}
#endif

extension IndexPath : OrderedCollection {}
