import Foundation

extension SkirClient {

    // =========================================================================
    // RawResponse
    // =========================================================================

    /// The raw HTTP response to return from a service handler.
    ///
    /// Pass these fields directly to your HTTP framework's response writer.
    public struct RawResponse {
        /// The response body.
        public let data: String
        /// The HTTP status code (e.g. 200, 400, 500).
        public let statusCode: Int
        /// The value for the `Content-Type` response header.
        public let contentType: String

        static func okJson(_ data: String) -> RawResponse {
            RawResponse(data: data, statusCode: 200, contentType: "application/json")
        }

        static func okHtml(_ data: String) -> RawResponse {
            RawResponse(data: data, statusCode: 200, contentType: "text/html; charset=utf-8")
        }

        static func badRequest(_ msg: String) -> RawResponse {
            RawResponse(data: msg, statusCode: 400, contentType: "text/plain; charset=utf-8")
        }

        static func serverError(_ msg: String, statusCode: Int) -> RawResponse {
            RawResponse(data: msg, statusCode: statusCode, contentType: "text/plain; charset=utf-8")
        }
    }

    // =========================================================================
    // HttpErrorCode
    // =========================================================================

    /// An HTTP error status code (4xx or 5xx).
    public enum HttpErrorCode: Int {
        case _400_BadRequest = 400
        case _401_Unauthorized = 401
        case _402_PaymentRequired = 402
        case _403_Forbidden = 403
        case _404_NotFound = 404
        case _405_MethodNotAllowed = 405
        case _406_NotAcceptable = 406
        case _407_ProxyAuthenticationRequired = 407
        case _408_RequestTimeout = 408
        case _409_Conflict = 409
        case _410_Gone = 410
        case _411_LengthRequired = 411
        case _412_PreconditionFailed = 412
        case _413_ContentTooLarge = 413
        case _414_UriTooLong = 414
        case _415_UnsupportedMediaType = 415
        case _416_RangeNotSatisfiable = 416
        case _417_ExpectationFailed = 417
        case _418_ImATeapot = 418
        case _421_MisdirectedRequest = 421
        case _422_UnprocessableContent = 422
        case _423_Locked = 423
        case _424_FailedDependency = 424
        case _425_TooEarly = 425
        case _426_UpgradeRequired = 426
        case _428_PreconditionRequired = 428
        case _429_TooManyRequests = 429
        case _431_RequestHeaderFieldsTooLarge = 431
        case _451_UnavailableForLegalReasons = 451
        case _500_InternalServerError = 500
        case _501_NotImplemented = 501
        case _502_BadGateway = 502
        case _503_ServiceUnavailable = 503
        case _504_GatewayTimeout = 504
        case _505_HttpVersionNotSupported = 505
        case _506_VariantAlsoNegotiates = 506
        case _507_InsufficientStorage = 507
        case _508_LoopDetected = 508
        case _510_NotExtended = 510
        case _511_NetworkAuthenticationRequired = 511

        /// The numeric HTTP status code.
        public var asInt: Int { rawValue }
    }

    // =========================================================================
    // ServiceError
    // =========================================================================

    /// Throw this from a method implementation to control the HTTP response
    /// sent to the client on error.
    ///
    /// Any other error propagated from a method implementation results in a 500
    /// response; the message is optionally forwarded to the client via
    /// `ServiceBuilder.setCanSendUnknownErrorMessage`.
    public struct ServiceError: Error {
        /// The HTTP status code to send (e.g. 400, 403, 404, 500).
        public let statusCode: HttpErrorCode
        /// The message to send to the client.
        public let message: String

        public init(statusCode: HttpErrorCode, message: String) {
            self.statusCode = statusCode
            self.message = message
        }
    }

    // =========================================================================
    // MethodErrorInfo
    // =========================================================================

    /// Context passed to the error logger when a method returns an error.
    public struct MethodErrorInfo {
        /// The error returned by the method. Cast to `ServiceError` to
        /// distinguish HTTP errors from unknown internal errors.
        public let error: Error
        /// The name of the method that failed.
        public let methodName: String
        /// The raw JSON of the request that caused the error.
        public let rawRequest: String
    }

    // =========================================================================
    // Service
    // =========================================================================

    /// Dispatches Skir RPC requests to registered method implementations.
    ///
    /// Create one using `ServiceBuilder`.
    public final class Service {
        private let keepUnrecognizedValues: Bool
        private let canSendUnknownErrorMessage: (MethodErrorInfo) -> Bool
        private let errorLogger: (MethodErrorInfo) -> Void
        private let studioAppJsUrl: String
        private var byNum: [Int64: MethodEntry]
        private var byName: [String: Int64]

        init(
            keepUnrecognizedValues: Bool,
            canSendUnknownErrorMessage: @escaping (MethodErrorInfo) -> Bool,
            errorLogger: @escaping (MethodErrorInfo) -> Void,
            studioAppJsUrl: String,
            byNum: [Int64: MethodEntry],
            byName: [String: Int64]
        ) {
            self.keepUnrecognizedValues = keepUnrecognizedValues
            self.canSendUnknownErrorMessage = canSendUnknownErrorMessage
            self.errorLogger = errorLogger
            self.studioAppJsUrl = studioAppJsUrl
            self.byNum = byNum
            self.byName = byName
        }

        /// Parses `body` and dispatches to the appropriate registered method.
        ///
        /// For GET requests in a standard HTTP stack, pass the decoded query
        /// string as `body`. For POST requests, pass the raw request body.
        public func handleRequest(_ body: String) async -> RawResponse {
            switch body {
            case "", "studio":
                return serveStudio(studioAppJsUrl)
            case "list":
                return serveList()
            default:
                break
            }
            let first = body.unicodeScalars.first.map { Character($0) } ?? " "
            if first == "{" || first.isWhitespace {
                return await handleJsonRequest(body)
            } else {
                return await handleColonRequest(body)
            }
        }

        private func serveList() -> RawResponse {
            let entries = byNum.values.sorted { $0.number < $1.number }
            var methods: [[String: Any]] = []
            for e in entries {
                var obj: [String: Any] = [
                    "method": e.name,
                    "number": e.number,
                ]
                if let reqDesc = try? JSONSerialization.jsonObject(with: Data(e.requestTypeDescriptorJson.utf8)) {
                    obj["request"] = reqDesc
                }
                if let respDesc = try? JSONSerialization.jsonObject(with: Data(e.responseTypeDescriptorJson.utf8)) {
                    obj["response"] = respDesc
                }
                if !e.doc.isEmpty {
                    obj["doc"] = e.doc
                }
                methods.append(obj)
            }
            let result: [String: Any] = ["methods": methods]
            guard let data = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
                  let json = String(data: data, encoding: .utf8)
            else {
                return RawResponse.okJson("{}")
            }
            return RawResponse.okJson(json)
        }

        private func handleJsonRequest(_ body: String) async -> RawResponse {
            guard let data = body.data(using: .utf8),
                  let jsonValue = try? JSONSerialization.jsonObject(with: data)
            else {
                return RawResponse.badRequest("bad request: invalid JSON")
            }
            guard let obj = jsonValue as? [String: Any] else {
                return RawResponse.badRequest("bad request: expected JSON object")
            }
            guard let methodVal = obj["method"] else {
                return RawResponse.badRequest("bad request: missing 'method' field in JSON")
            }
            let entry: MethodEntry
            if let number = methodVal as? Int {
                guard let e = byNum[Int64(number)] else {
                    return RawResponse.badRequest("bad request: method not found: \(number)")
                }
                entry = e
            } else if let number = methodVal as? Double, number == number.rounded() {
                guard let e = byNum[Int64(number)] else {
                    return RawResponse.badRequest("bad request: method not found: \(Int64(number))")
                }
                entry = e
            } else if let name = methodVal as? String {
                guard let number = byName[name], let e = byNum[number] else {
                    return RawResponse.badRequest("bad request: method not found: \(methodVal)")
                }
                entry = e
            } else {
                return RawResponse.badRequest("bad request: 'method' field must be a string or integer")
            }
            guard let requestVal = obj["request"] else {
                return RawResponse.badRequest("bad request: missing 'request' field in JSON")
            }
            guard let requestData = try? JSONSerialization.data(withJSONObject: requestVal),
                  let requestJson = String(data: requestData, encoding: .utf8)
            else {
                return RawResponse.badRequest("bad request: cannot re-serialize 'request' field")
            }
            return await invokeEntry(
                entry,
                requestJson: requestJson,
                keepUnrecognized: keepUnrecognizedValues,
                readable: true
            )
        }

        private func handleColonRequest(_ body: String) async -> RawResponse {
            // Format: "name:number:format:requestJson"
            // number may be empty (lookup by name); format may be empty (dense).
            let parts = body.split(separator: ":", maxSplits: 3, omittingEmptySubsequences: false)
            guard parts.count == 4 else {
                return RawResponse.badRequest("bad request: invalid request format")
            }
            let nameStr = String(parts[0])
            let numberStr = String(parts[1])
            let format = String(parts[2])
            let requestJson = parts[3].isEmpty ? "{}" : String(parts[3])

            let entry: MethodEntry
            if numberStr.isEmpty {
                guard let number = byName[nameStr], let e = byNum[number] else {
                    return RawResponse.badRequest("bad request: method not found: \(nameStr)")
                }
                entry = e
            } else {
                guard let number = Int64(numberStr) else {
                    return RawResponse.badRequest("bad request: can't parse method number")
                }
                guard let e = byNum[number] else {
                    return RawResponse.badRequest("bad request: method not found: \(nameStr); number: \(number)")
                }
                entry = e
            }
            let readable = format == "readable"
            return await invokeEntry(
                entry,
                requestJson: requestJson,
                keepUnrecognized: keepUnrecognizedValues,
                readable: readable
            )
        }

        private func invokeEntry(
            _ entry: MethodEntry,
            requestJson: String,
            keepUnrecognized: Bool,
            readable: Bool
        ) async -> RawResponse {
            do {
                let responseJson = try await entry.invoke(requestJson, keepUnrecognized, readable)
                return RawResponse.okJson(responseJson)
            } catch {
                let info = MethodErrorInfo(
                    error: error,
                    methodName: entry.name,
                    rawRequest: requestJson
                )
                errorLogger(info)
                if let svcErr = error as? ServiceError {
                    let msg = svcErr.message.isEmpty
                        ? httpStatusText(svcErr.statusCode.asInt)
                        : svcErr.message
                    return RawResponse.serverError(msg, statusCode: svcErr.statusCode.asInt)
                } else {
                    let msg = canSendUnknownErrorMessage(info)
                        ? "server error: \(error)"
                        : "server error"
                    return RawResponse.serverError(msg, statusCode: 500)
                }
            }
        }
    }

    // =========================================================================
    // ServiceBuilder
    // =========================================================================

    /// Builder for `Service`.
    ///
    /// Register method implementations with `addMethod`, tune options with the
    /// `set*` methods, then call `build()`.
    public final class ServiceBuilder {
        private var keepUnrecognizedValues: Bool = false
        private var canSendUnknownErrorMessage: (MethodErrorInfo) -> Bool = { _ in false }
        private var errorLogger: (MethodErrorInfo) -> Void = { info in
            fputs("skir: error in method \(String(reflecting: info.methodName)): \(info.error)\n", stderr)
        }
        private var studioAppJsUrl: String = defaultStudioAppJsUrl
        private var byNum: [Int64: MethodEntry] = [:]
        private var byName: [String: Int64] = [:]

        public init() {}

        /// Registers the implementation of a method.
        ///
        /// The closure receives the deserialized request and must return the
        /// response or throw. Throw a `ServiceError` to send a specific HTTP
        /// status code and message to the client; any other error results in a
        /// 500 response.
        ///
        /// Returns an error if a method with the same number has already been
        /// registered.
        @discardableResult
        public func addMethod<Req, Resp>(
            _ method: Method<Req, Resp>,
            impl implFn: @escaping (Req) async throws -> Resp
        ) throws -> Self {
            guard byNum[method.number] == nil else {
                throw ServiceError(
                    statusCode: ._500_InternalServerError,
                    message: "skir: method number \(method.number) already registered"
                )
            }
            let reqSerializer = method.requestSerializer
            let respSerializer = method.responseSerializer
            let entry = MethodEntry(
                name: method.name,
                number: method.number,
                doc: method.doc,
                requestTypeDescriptorJson: reqSerializer.typeDescriptor().asJson(),
                responseTypeDescriptorJson: respSerializer.typeDescriptor().asJson(),
                invoke: { requestJson, keepUnrecognized, readable in
                    let req: Req
                    do {
                        req = try reqSerializer.fromJson(requestJson, keepUnrecognized: keepUnrecognized)
                    } catch {
                        throw ServiceError(
                            statusCode: ._400_BadRequest,
                            message: "bad request: can't parse JSON: \(error)"
                        )
                    }
                    let resp = try await implFn(req)
                    return respSerializer.toJson(resp, readable: readable)
                }
            )
            byName[method.name] = method.number
            byNum[method.number] = entry
            return self
        }

        /// Whether to keep unrecognized values when deserializing requests.
        ///
        /// Only enable this for data from trusted sources. Malicious actors
        /// could inject fields with IDs not yet defined in your schema.
        ///
        /// Defaults to `false`.
        @discardableResult
        public func setKeepUnrecognizedValues(_ keep: Bool) -> Self {
            keepUnrecognizedValues = keep
            return self
        }

        /// Whether the message of an unknown (non-`ServiceError`) error can be
        /// sent to the client in the response body.
        ///
        /// Defaults to `false` to avoid leaking sensitive information.
        @discardableResult
        public func setCanSendUnknownErrorMessage(_ can: Bool) -> Self {
            canSendUnknownErrorMessage = { _ in can }
            return self
        }

        /// Per-invocation predicate for whether to expose unknown error messages.
        @discardableResult
        public func setCanSendUnknownErrorMessageFn(
            _ fn: @escaping (MethodErrorInfo) -> Bool
        ) -> Self {
            canSendUnknownErrorMessage = fn
            return self
        }

        /// Callback invoked whenever an error occurs during method execution.
        ///
        /// Use this to log errors for monitoring, debugging, or alerting.
        /// Defaults to printing the method name and error message to stderr.
        @discardableResult
        public func setErrorLogger(_ logger: @escaping (MethodErrorInfo) -> Void) -> Self {
            errorLogger = logger
            return self
        }

        /// URL to the Skir Studio JavaScript bundle.
        ///
        /// Skir Studio is a web UI for exploring and testing your service.
        /// It is served when the request body is `""` or `"studio"`.
        ///
        /// Defaults to the CDN-hosted version.
        @discardableResult
        public func setStudioAppJsUrl(_ url: String) -> Self {
            studioAppJsUrl = url
            return self
        }

        /// Builds the `Service`.
        public func build() -> Service {
            Service(
                keepUnrecognizedValues: keepUnrecognizedValues,
                canSendUnknownErrorMessage: canSendUnknownErrorMessage,
                errorLogger: errorLogger,
                studioAppJsUrl: studioAppJsUrl,
                byNum: byNum,
                byName: byName
            )
        }
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    struct MethodEntry {
        let name: String
        let number: Int64
        let doc: String
        let requestTypeDescriptorJson: String
        let responseTypeDescriptorJson: String
        /// (requestJson, keepUnrecognized, readable) -> responseJson
        let invoke: (String, Bool, Bool) async throws -> String
    }
}

private func serveStudio(_ jsUrl: String) -> SkirClient.RawResponse {
    SkirClient.RawResponse.okHtml(studioHtml(jsUrl))
}

private func studioHtml(_ jsUrl: String) -> String {
    let safe = htmlEscapeAttr(jsUrl)
    // Copied from https://github.com/gepheum/skir-studio/blob/main/index.jsdeliver.html
    return """
    <!DOCTYPE html><html>
      <head>
        <meta charset="utf-8" />
        <title>RPC Studio</title>
        <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>⚡</text></svg>">
        <script src="\(safe)"></script>
      </head>
      <body style="margin: 0; padding: 0;">
        <skir-studio-app></skir-studio-app>
      </body>
    </html>
    """
}

private func htmlEscapeAttr(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "\"", with: "&#34;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}

private func httpStatusText(_ code: Int) -> String {
    switch code {
    case 200: return "OK"
    case 400: return "Bad Request"
    case 401: return "Unauthorized"
    case 403: return "Forbidden"
    case 404: return "Not Found"
    case 409: return "Conflict"
    case 422: return "Unprocessable Entity"
    case 429: return "Too Many Requests"
    case 500: return "Internal Server Error"
    case 502: return "Bad Gateway"
    case 503: return "Service Unavailable"
    default: return "Error"
    }
}

private let defaultStudioAppJsUrl =
    "https://cdn.jsdelivr.net/npm/skir-studio/dist/skir-studio-standalone.js"
