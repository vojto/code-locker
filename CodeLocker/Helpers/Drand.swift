import Foundation

/*
 * Talks to drand, the public network whose signatures open time-locked secrets.
 * Used by AccountStore. drand publishes one numbered "round" every 3 seconds.
 * A secret locked for a round can only be opened with that round's signature,
 * which does not exist anywhere until the round's time comes.
 */

enum Drand {
    // The "quicknet" chain. These values never change for this chain.
    private static let baseURL = URL(string: "https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971")!
    private static let genesis: TimeInterval = 1_692_803_367
    private static let period: TimeInterval = 3

    static let publicKey = Data(hex: "83cf0f2896adee7eb8b5f01fcad3912212c437e0073e911fb90022d3e760183c8c4b450b6a0a6c3ac6a5776a2d1064510d1fec758c921cc22b0e17e63aaf4bcb5ed66304de9cf809bd274ca73bab4af5a6e9c76a4bc09e76eae8991ef5ece45a")

    // MARK: - Rounds and time

    /// The first round published at or after `date`.
    static func round(at date: Date) -> UInt64 {
        UInt64(max(0, ((date.timeIntervalSince1970 - genesis) / period).rounded(.up))) + 1
    }

    static func date(of round: UInt64) -> Date {
        Date(timeIntervalSince1970: genesis + Double(round - 1) * period)
    }

    // MARK: - Network

    /// The newest published round. Also tells us the real time, whatever the Mac's clock says.
    static func latestRound() async throws -> UInt64 {
        try await fetch("public/latest").round
    }

    /// Fails if the round has not been published yet.
    static func signature(for round: UInt64) async throws -> Data {
        Data(hex: try await fetch("public/\(round)").signature)
    }

    private struct Beacon: Decodable {
        let round: UInt64
        let signature: String
    }

    private static func fetch(_ path: String) async throws -> Beacon {
        let request = URLRequest(url: baseURL.appending(path: path), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Beacon.self, from: data)
    }
}
