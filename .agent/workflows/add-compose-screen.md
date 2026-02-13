---
description: Add a new Compose screen to Android app
---

# Add Compose Screen

Steps to add new screens to the Android Support Bridge app.

## Steps

1. **Create screen composable** in `android/app/src/main/java/com/schoolable/supportbridge/ui/`:

```kotlin
package com.schoolable.supportbridge.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewFeatureScreen(
    viewModel: NewFeatureViewModel = viewModel(),
    onNavigate: (String) -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Feature Name") })
        }
    ) { padding ->
        when (uiState) {
            is UiState.Loading -> CircularProgressIndicator()
            is UiState.Success -> {
                LazyColumn(modifier = Modifier.padding(padding)) {
                    items(uiState.data) { item ->
                        ItemCard(item = item)
                    }
                }
            }
            is UiState.Error -> Text("Error: ${uiState.message}")
        }
    }
}
```

2. **Create ViewModel** in `ui/` folder:
```kotlin
class NewFeatureViewModel : ViewModel() {
    private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()
    
    init { loadData() }
    
    private fun loadData() {
        viewModelScope.launch {
            _uiState.value = try {
                UiState.Success(repository.getItems())
            } catch (e: Exception) {
                UiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
```

3. **Add to navigation** in MainActivity.kt's NavHost or tab selection

4. **Add to dependencies** in build.gradle.kts if needed

## UI State Pattern

```kotlin
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}
```
