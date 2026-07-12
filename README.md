# local_agent

A Flutter plugin for running on-device, local AI reasoning and drawing loops using a ReAct (Reasoning and Action) execution harness.

Under the hood, it leverages **Google ML Kit GenAI** on Android and experimental **Chrome Built-in AI** (`window.chromeAi`) on the Web, with a mock fallback for testing and other platforms.

---

## Features
- **On-Device Inference:** Run prompts locally without external API keys or server costs.
- **ReAct Loop Orchestration:** Implements an iterative reasoning-action loop via `AgentHarness` that queries the model, executes tool calls in the application environment, feeds back the result, and loops until finished.
- **Multiplatform Support:** Runs on Android (Android 8.0+ / API 26+) and Web (Chrome Dev/Canary with Gemini Nano enabled).
- **CI/CD Integrated:** Automated GitHub Actions workflows verifying formatting, static analysis, unit/widget tests, and build compilation.

---

## Platform Requirements

### Android
- **Minimum SDK Version:** 26 (Android 8.0 Oreo). This is required due to the `com.google.mlkit:genai-prompt` dependency.
- Setting up the model download: The plugin uses ML Kit’s GenAI feature which handles local model weight downloads and management on-device.

### Web
- Requires experimental Chrome Built-in AI (`chromeAi`) enabled on the client browser.
- Ensure that the browser has Gemini Nano enabled and configured.

---

## Getting Started

### 1. Define your Agent Delegate
To customize how your agent interacts with the Flutter environment, implement the `AgentDelegate` class. This defines how the prompt history is formatted, provides visual context (images), and executes the tool commands output by the model.

```dart
import 'dart:typed_data';
import 'package:local_agent/local_agent.dart';

class MyDrawingAgentDelegate implements AgentDelegate {
  @override
  String formatPrompt(String userPrompt, List<AgentStepResult> history) {
    final buffer = StringBuffer("Prompt: $userPrompt\nHistory:\n");
    for (var step in history) {
      buffer.writeln("- Tool: ${step.tool}, Feedback: ${step.feedback}");
    }
    return buffer.toString();
  }

  @override
  Uint8List? getVisualInput() {
    // Return image bytes of the current drawing canvas for multimodal support
    return null; 
  }

  @override
  Future<String> applyAction(Map<String, dynamic> actionMap) async {
    // Parse the action parameters and update your app environment (e.g., draw a line)
    final tool = actionMap['tool'];
    final params = actionMap['params'];
    return "Successfully executed $tool with parameters $params";
  }

  @override
  bool isFinishAction(Map<String, dynamic> actionMap) {
    return actionMap['tool'] == 'finish';
  }
}
```

### 2. Run the Loop with AgentHarness
Initialize the `AgentHarness` with an `AiService` (e.g., using `MockAiService` for testing or the production `aiServiceProvider` for method channel / web integration) and your delegate. Then start the loop:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_agent/local_agent.dart';

void startAgent(WidgetRef ref) async {
  final aiService = ref.read(aiServiceProvider);
  final delegate = MyDrawingAgentDelegate();
  
  final harness = AgentHarness(
    aiService: aiService,
    delegate: delegate,
  );

  final results = await harness.runDrawingLoop(
    userPrompt: "Draw a red circle at center",
    maxSteps: 5,
    onStep: (stepResult, currentStep) {
      print("Step $currentStep thought: ${stepResult.thought}");
    },
  );
  
  print("Agent finished execution after ${results.length} steps.");
}
```

---

## Scripts & Tools
- **Release Tagger:** The project includes a utility script under `bin/tag.sh` to automate semantic version increments and pushes to the git remote:
  ```bash
  ./bin/tag.sh --patch # Increments patch version (e.g., v0.0.1 -> v0.0.2)
  ./bin/tag.sh --minor # Increments minor version (e.g., v0.0.1 -> v0.1.0)
  ./bin/tag.sh --major # Increments major version (e.g., v0.0.1 -> v1.0.0)
  ```
  Run `./bin/tag.sh --help` for full options.
