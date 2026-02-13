import Foundation
import Combine

class LinkPreviewService: ObservableObject {
    static let shared = LinkPreviewService()
    
    // Checks text for first URL
    func extractURL(from text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches.first?.url
    }
    
    func fetchMetadata(for url: URL, completion: @escaping (LinkPreview?) -> Void) {
        scrapeOGTags(url: url, completion: completion)
    }
    
    private func scrapeOGTags(url: URL, completion: @escaping (LinkPreview?) -> Void) {
         let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 5)
         URLSession.shared.dataTask(with: request) { data, response, error in
             guard let data = data, let html = String(data: data, encoding: .utf8) else {
                 DispatchQueue.main.async { completion(nil) }
                 return
             }
             
             // Naive regex scraping for Open Graph tags
             let title = self.extractMeta(html: html, property: "og:title") ?? self.extractTitle(html: html)
             let desc = self.extractMeta(html: html, property: "og:description")
             let image = self.extractMeta(html: html, property: "og:image")
             
             // Resolve relative image URL if needed
             var finalImageUrl = image
             if let img = image, !img.lowercased().hasPrefix("http") {
                 finalImageUrl = URL(string: img, relativeTo: url)?.absoluteString
             }
             
             if title == nil && finalImageUrl == nil {
                 DispatchQueue.main.async { completion(nil) }
                 return
             }
             
             let preview = LinkPreview(
                 url: url.absoluteString,
                 title: title,
                 description: desc,
                 imageUrl: finalImageUrl,
                 domain: url.host
             )
             
             DispatchQueue.main.async {
                 completion(preview)
             }
         }.resume()
    }
    
    private func extractMeta(html: String, property: String) -> String? {
        // Regex: <meta property="og:title" content="(.*?)">
        // Simplified pattern (doesn't handle all HTML edge cases but good for demo)
        let pattern = "<meta[^>]+property=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
        return self.regexMatch(pattern: pattern, text: html)
    }
    
    private func extractTitle(html: String) -> String? {
        return self.regexMatch(pattern: "<title>(.*?)</title>", text: html)
    }
    
    private func regexMatch(pattern: String, text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
             if let r = Range(match.range(at: 1), in: text) {
                 return String(text[r])
             }
        }
        return nil
    }
}
