import Foundation

actor ExteraPillLiveData {
    static let shared = ExteraPillLiveData()

    enum Source: Hashable {
        case markets
        case weather(ExteraWeatherCity)

        var minimumLifetime: TimeInterval {
            switch self {
            case .markets: return 60
            case .weather: return 900
            }
        }

        var url: URL? {
            switch self {
            case .markets: return URL(string: "https://api.coinbase.com/v2/exchange-rates?currency=USD")
            case let .weather(city):
                let location = city.coordinates
                return URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(location.0)&longitude=\(location.1)&current=temperature_2m")
            }
        }
    }

    struct Reading {
        let value: Double
        let stale: Bool
    }

    private struct Entry {
        let values: [ExteraPill: Double]
        let expires: Date
        let staleUntil: Date
    }

    private struct Retry {
        let failures: Int
        let after: Date
    }

    private enum Outcome {
        case values([ExteraPill: Double])
        case retryAfter(TimeInterval?)
    }

    private struct RatesResult: Decodable {
        struct Rates: Decodable { let rates: [String: String] }
        let data: Rates
    }

    private struct WeatherResult: Decodable {
        struct Current: Decodable { let temperature_2m: Double }
        let current: Current
    }

    private let session: URLSession
    private var entries: [Source: Entry] = [:]
    private var retries: [Source: Retry] = [:]
    private var pending: [Source: Task<Outcome, Never>] = [:]

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 14
        config.httpShouldSetCookies = false
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func read(_ source: Source, interval: Int) async -> [ExteraPill: Reading] {
        let now = Date()
        if let entry = self.entries[source], now < entry.expires { return self.readings(entry, at: now) }
        if let retry = self.retries[source], now < retry.after { return self.readings(self.entries[source], at: now) }
        if let pending = self.pending[source] {
            if case let .values(values) = await pending.value {
                return values.mapValues { Reading(value: $0, stale: false) }
            }
            return self.readings(self.entries[source], at: Date())
        }
        let task = Task { [session = self.session] in
            return await Self.fetch(source, session: session)
        }
        self.pending[source] = task
        let outcome = await task.value
        self.pending[source] = nil
        let finished = Date()
        switch outcome {
        case let .values(values):
            self.retries[source] = nil
            let ttl = max(source.minimumLifetime, TimeInterval(interval))
            self.entries[source] = Entry(values: values, expires: finished.addingTimeInterval(ttl),
                staleUntil: finished.addingTimeInterval(max(ttl * 6, 1_800)))
        case let .retryAfter(serverWait):
            let previous = self.retries[source]?.failures ?? 0
            let failures = previous == 3 ? 1 : previous + 1
            let cooldown = failures == 3 ? 900 : 30 * Double(1 << (failures - 1))
            self.retries[source] = Retry(failures: failures, after: finished.addingTimeInterval(max(cooldown, serverWait ?? 0)))
        }
        return self.readings(self.entries[source], at: finished)
    }

    private func readings(_ entry: Entry?, at date: Date) -> [ExteraPill: Reading] {
        guard let entry, date < entry.staleUntil else { return [:] }
        return entry.values.mapValues { Reading(value: $0, stale: date >= entry.expires) }
    }

    private static func fetch(_ source: Source, session: URLSession) async -> Outcome {
        guard let url = source.url else { return .retryAfter(nil) }
        do {
            let (data, response) = try await session.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  response.url?.scheme == "https", response.url?.host == url.host else { return .retryAfter(nil) }
            if response.statusCode == 429 {
                return .retryAfter(response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init))
            }
            guard (200..<300).contains(response.statusCode), data.count <= 512 * 1024 else { return .retryAfter(nil) }
            switch source {
            case .markets:
                let values = try JSONDecoder().decode(RatesResult.self, from: data).data.rates
                var result: [ExteraPill: Double] = [:]
                for (widget, ticker) in [(ExteraPill.btc, "BTC"), (.gram, "TON"), (.currency, "EUR")] {
                    if let raw = values[ticker], let number = Double(raw), number.isFinite, number > 0 {
                        let value = widget == .currency ? number : 1 / number
                        if value.isFinite { result[widget] = value }
                    }
                }
                return result.isEmpty ? .retryAfter(nil) : .values(result)
            case .weather:
                let temperature = try JSONDecoder().decode(WeatherResult.self, from: data).current.temperature_2m
                guard temperature.isFinite, (-100...80).contains(temperature) else { return .retryAfter(nil) }
                return .values([.weather: temperature])
            }
        } catch {
            return .retryAfter(nil)
        }
    }
}
