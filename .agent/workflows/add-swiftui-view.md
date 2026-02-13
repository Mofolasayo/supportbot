---
description: Add a new SwiftUI view to macOS/iOS apps
---

# Add SwiftUI View

Steps to add new views to the macOS or iOS Support Bridge apps.

## Steps

1. **Create the view file** in the appropriate Features folder:
   - macOS: `macos/SupportBridge/Features/<Feature>/`
   - iOS: `ios/SupportBridge/Features/<Feature>/`

2. **View structure**:
```swift
import SwiftUI

struct NewFeatureView: View {
    @EnvironmentObject var appState: AppState
    @State private var items: [Item] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                List(items) { item in
                    ItemRow(item: item)
                }
            }
        }
        .task {
            await loadData()
        }
        .navigationTitle("Feature Name")
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await APIService.shared.getItems()
        } catch {
            print("Error: \(error)")
        }
    }
}
```

3. **Add navigation** in ContentView.swift or MainView

4. **Update API service** if new endpoints needed:
```swift
// In Services/APIService.swift
func getItems() async throws -> [Item] {
    let response: APIResponse<[Item]> = try await get("/items")
    return response.data
}
```

## Platform Differences

| Aspect | macOS | iOS |
|--------|-------|-----|
| Layout | NavigationSplitView | NavigationStack |
| Navigation | Sidebar + Detail | Tab + Push |
| Window | Frame constraints | Full screen |
