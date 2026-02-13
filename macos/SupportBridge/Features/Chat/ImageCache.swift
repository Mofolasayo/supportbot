import SwiftUI
import Combine

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 50 // 50 MB
    }
    
    func get(forKey key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: NSImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

class ImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false
    
    private let url: URL
    private var cancellable: AnyCancellable?
    
    init(url: URL) {
        self.url = url
    }
    
    func load() {
        if let cached = ImageCache.shared.get(forKey: url.absoluteString) {
            self.image = cached
            return
        }
        
        isLoading = true
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { NSImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.isLoading = false
                if let image = image, let self = self {
                    ImageCache.shared.set(image, forKey: self.url.absoluteString)
                    self.image = image
                }
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    @StateObject private var loader: ImageLoader
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    init(
        url: URL,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let nsImage = loader.image {
                content(Image(nsImage: nsImage))
            } else {
                placeholder()
            }
        }
        .onAppear { loader.load() }
        .onDisappear { loader.cancel() }
    }
}
