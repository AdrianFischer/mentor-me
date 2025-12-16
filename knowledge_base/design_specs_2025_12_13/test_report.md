# Test Report
**Status**: FAIL ❌
**Time**: 2025-12-16T23:22:12.497737

## Output
```
00:00 +0: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart                                                                                                            00:01 +0: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart                                                                                                            00:02 +0: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart                                                                                                            00:03 +0: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart                                                                                                            00:04 +0: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart                                                                                                            00:04 +0: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart: Config Reads API key from dotenv                                                                                  00:04 +1: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart: Config Reads API key from dotenv                                                                                  00:04 +1: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart: Config Handles missing API key gracefully                                                                         00:04 +2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart: Config Handles missing API key gracefully                                                                         00:05 +2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/config_test.dart: Config Handles missing API key gracefully                                                                         00:05 +2: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart                                                                                                   00:05 +2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry describes add_project correctly                                    00:05 +3: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry describes add_project correctly                                    00:05 +3: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry describes add_task correctly                                       00:05 +4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry describes add_task correctly                                       00:05 +4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes add_project and calls DataService                         00:05 +4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes add_project and calls DataService                         
[VERIFY_FLOW] Tool Execution Start: add_project with args {title: New App}
00:05 +5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes add_project and calls DataService                         00:05 +5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes add_task and calls DataService                            00:05 +5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes add_task and calls DataService                            
[VERIFY_FLOW] Tool Execution Start: add_task with args {project_id: p1, title: Fix Bug}
00:05 +6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes add_task and calls DataService                            00:05 +6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes delete_item and calls DataService                         00:05 +6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes delete_item and calls DataService                         
[VERIFY_FLOW] Tool Execution Start: delete_item with args {item_id: item_1}
00:05 +7: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ToolRegistry executes delete_item and calls DataService                         00:05 +7: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ProposedAction model creation                                                   00:05 +8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ProposedAction model creation                                                   00:05 +8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ChatMessage model creation                                                      00:05 +9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/assistant_logic_test.dart: AI Assistant Logic Tests ChatMessage model creation                                                      00:05 +9 -1: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/gemini_api_test.dart [E]                                                                                                 
  Failed to load "/Users/adi/dev/AssistedIntelligence/src/flutter_app/test/gemini_api_test.dart":
  Compilation failed for testPath=/Users/adi/dev/AssistedIntelligence/src/flutter_app/test/gemini_api_test.dart: test/gemini_api_test.dart:25:7: Error: The non-abstract class 'FakeStorageRepository' is missing implementations for these members:
   - StorageRepository.clearChatHistory
   - StorageRepository.getAllKnowledge
   - StorageRepository.getChatHistory
   - StorageRepository.saveChatMessage
   - StorageRepository.saveKnowledge
  Try to either
   - provide an implementation,
   - inherit an implementation from a superclass or mixin,
   - mark the class as abstract, or
   - provide a 'noSuchMethod' implementation.
  
  class FakeStorageRepository implements StorageRepository {
        ^^^^^^^^^^^^^^^^^^^^^
  lib/data/repository/storage_repository.dart:21:16: Context: 'StorageRepository.clearChatHistory' is defined here.
    Future<void> clearChatHistory(String mode);
                 ^^^^^^^^^^^^^^^^
  lib/data/repository/storage_repository.dart:25:27: Context: 'StorageRepository.getAllKnowledge' is defined here.
    Future<List<Knowledge>> getAllKnowledge();
                            ^^^^^^^^^^^^^^^
  lib/data/repository/storage_repository.dart:20:29: Context: 'StorageRepository.getChatHistory' is defined here.
    Future<List<ChatMessage>> getChatHistory(String mode);
                              ^^^^^^^^^^^^^^
  lib/data/repository/storage_repository.dart:19:16: Context: 'StorageRepository.saveChatMessage' is defined here.
    Future<void> saveChatMessage(ChatMessage message, String mode);
                 ^^^^^^^^^^^^^^^
  lib/data/repository/storage_repository.dart:24:16: Context: 'StorageRepository.saveKnowledge' is defined here.
    Future<void> saveKnowledge(Knowledge knowledge);
                 ^^^^^^^^^^^^^
  .

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/gemini_api_test.dart -p vm --plain-name 'loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/gemini_api_test.dart'
00:05 +9 -1: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart                                                                                             00:05 +9 -1: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: (setUpAll)                                                                                         00:05 +9 -1: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item                                                                 00:06 +9 -1: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item                                                                 00:06 +9 -1: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item                                                                 
Key event: LogicalKeyboardKey#2604c(keyId: "0x10000000d", keyLabel: "Enter", debugName: "Enter"), AssistantActive: false
[VERIFY_FLOW] Data Update: addProject()
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test:
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveProject (package:flutter_app/data/repository/isar_storage_repository.dart:89:11)
#2      DataService.addProject (package:flutter_app/services/data_service.dart:26:17)
#3      _MyAppState._handleEnterKey.<anonymous closure> (package:flutter_app/app.dart:102:36)
#4      State.setState (package:flutter/src/widgets/framework.dart:1199:30)
#5      _MyAppState._handleEnterKey (package:flutter_app/app.dart:100:5)
#6      _MyAppState._handleKeyEvent (package:flutter_app/app.dart:78:11)
#7      KeyboardListener.build.<anonymous closure> (package:flutter/src/widgets/keyboard_listener.dart:72:21)
#8      _HighlightModeManager.handleKeyMessage (package:flutter/src/widgets/focus_manager.dart:2244:72)
#9      KeyEventManager._dispatchKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1119:34)
#10     KeyEventManager.handleRawKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1195:17)
#11     BasicMessageChannel.setMessageHandler.<anonymous closure> (package:flutter/src/services/platform_channel.dart:259:49)
#12     TestDefaultBinaryMessenger.handlePlatformMessage (package:flutter_test/src/test_default_binary_messenger.dart:99:42)
#13     KeyEventSimulator._simulateKeyEventByRawEvent.<anonymous closure> (package:flutter_test/src/event_simulation.dart:665:79)
#16     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#17     KeyEventSimulator._simulateKeyEventByRawEvent (package:flutter_test/src/event_simulation.dart:663:27)
#18     KeyEventSimulator.simulateKeyDownEvent.simulateByRawEvent (package:flutter_test/src/event_simulation.dart:751:14)
#19     KeyEventSimulator.simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:772:23)
#20     simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:897:48)
#21     WidgetController.sendKeyEvent (package:flutter_test/src/controller.dart:2131:32)
#22     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:19:18)
<asynchronous suspension>
#23     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#24     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from dart:async and package:stack_trace)

The test description was:
  Navigation Right Auto-Creates Item
════════════════════════════════════════════════════════════════════════════════════════════════════
00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item [E]                                                             
  Test failed. See exception logs above.
  The test description was: Navigation Right Auto-Creates Item
  
[VERIFY_FLOW] UI Rebuild: Column Projects items changed from 1 to 2
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveProject (package:flutter_app/data/repository/isar_storage_repository.dart:89:11)
#2      DataService.updateTitle (package:flutter_app/services/data_service.dart:181:21)
#3      _MyAppState.build.<anonymous closure> (package:flutter_app/app.dart:420:33)
#4      _EditableColumnState._addItemInternal.<anonymous closure> (package:flutter_app/ui/widgets/editable_column.dart:73:24)
#5      ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#6      ValueNotifier.value= (package:flutter/src/foundation/change_notifier.dart:559:5)
#7      TextEditingController.value= (package:flutter/src/widgets/editable_text.dart:291:11)
#8      TextEditingController.selection= (package:flutter/src/widgets/editable_text.dart:351:5)
#9      EditableTextState._handleSelectionChanged (package:flutter/src/widgets/editable_text.dart:4282:23)
#10     EditableTextState._handleFocusChanged (package:flutter/src/widgets/editable_text.dart:4720:9)
#11     ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#12     FocusNode._notify (package:flutter/src/widgets/focus_manager.dart:1131:5)
#13     FocusManager.applyFocusChangesIfNeeded (package:flutter/src/widgets/focus_manager.dart:1995:12)
#23     FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:189:18)
#24     FakeAsync.flushMicrotasks (package:fake_async/fake_async.dart:200:32)
#25     AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1337:26)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#30     WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:719:23)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     WidgetTester.pumpAndSettle (package:flutter_test/src/widget_tester.dart:712:27)
#35     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:20:18)
<asynchronous suspension>
#36     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#37     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 14 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
  Test failed. See exception logs above.
  The test description was: Navigation Right Auto-Creates Item
  
00:06 +9 -2: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart                                                                                                    00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: (setUpAll)                                                                                                00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item                                                                 
Key event: LogicalKeyboardKey#857a2(keyId: "0x100000303", keyLabel: "Arrow Right", debugName: "Arrow Right"), AssistantActive: false
[VERIFY_FLOW] Data Update: addTask() to dcbc95f5-8bb6-4863-a0c5-5aad7373fab4
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveTask (package:flutter_app/data/repository/isar_storage_repository.dart:102:11)
#2      DataService.addTask (package:flutter_app/services/data_service.dart:45:19)
#3      _MyAppState._changeColumn.<anonymous closure> (package:flutter_app/app.dart:334:43)
#4      State.setState (package:flutter/src/widgets/framework.dart:1199:30)
#5      _MyAppState._changeColumn (package:flutter_app/app.dart:322:5)
#6      _MyAppState._handleKeyEvent (package:flutter_app/app.dart:72:9)
#7      KeyboardListener.build.<anonymous closure> (package:flutter/src/widgets/keyboard_listener.dart:72:21)
#8      _HighlightModeManager.handleKeyMessage (package:flutter/src/widgets/focus_manager.dart:2244:72)
#9      KeyEventManager._dispatchKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1119:34)
#10     KeyEventManager.handleRawKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1195:17)
#11     BasicMessageChannel.setMessageHandler.<anonymous closure> (package:flutter/src/services/platform_channel.dart:259:49)
#12     TestDefaultBinaryMessenger.handlePlatformMessage (package:flutter_test/src/test_default_binary_messenger.dart:99:42)
#13     KeyEventSimulator._simulateKeyEventByRawEvent.<anonymous closure> (package:flutter_test/src/event_simulation.dart:665:79)
#16     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#17     KeyEventSimulator._simulateKeyEventByRawEvent (package:flutter_test/src/event_simulation.dart:663:27)
#18     KeyEventSimulator.simulateKeyDownEvent.simulateByRawEvent (package:flutter_test/src/event_simulation.dart:751:14)
#19     KeyEventSimulator.simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:772:23)
#20     simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:897:48)
#21     WidgetController.sendKeyEvent (package:flutter_test/src/controller.dart:2131:32)
#22     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:26:18)
<asynchronous suspension>
#23     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#24     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item [E]                                                             
  Test failed. See exception logs above.
  The test description was: Navigation Right Auto-Creates Item
  
00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: (setUpAll)                                                                                                00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode starts in Assistant Mode                                                     00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item                                                                 
[VERIFY_FLOW] UI Rebuild: Column Tasks items changed from 0 to 1
00:06 +9 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode starts in Assistant Mode                                                     
Warning: No API Key provided. Using Mock Mode.
00:06 +10 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode starts in Assistant Mode                                                    00:06 +10 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode toggles to Mentor Mode                                                      00:06 +10 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode toggles to Mentor Mode                                                      
Warning: No API Key provided. Using Mock Mode.
00:06 +11 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode toggles to Mentor Mode                                                      00:06 +11 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode switching modes switches message history                                    00:06 +11 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode switching modes switches message history                                    
Warning: No API Key provided. Using Mock Mode.
[VERIFY_FLOW] Service Receive: Hello Assistant (Mode: Assistant)
00:06 +12 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode switching modes switches message history                                    00:06 +12 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Mock Mentor Mode responds correctly                                         00:06 +12 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Mock Mentor Mode responds correctly                                         
Warning: No API Key provided. Using Mock Mode.
[VERIFY_FLOW] Service Receive: I'm stuck (Mode: Mentor)
00:06 +12 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item                                                                
Key event: LogicalKeyboardKey#857a2(keyId: "0x100000303", keyLabel: "Arrow Right", debugName: "Arrow Right"), AssistantActive: false
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveTask (package:flutter_app/data/repository/isar_storage_repository.dart:102:11)
#2      DataService.addSubtask (package:flutter_app/services/data_service.dart:74:21)
#3      _MyAppState._changeColumn.<anonymous closure> (package:flutter_app/app.dart:345:43)
#4      State.setState (package:flutter/src/widgets/framework.dart:1199:30)
#5      _MyAppState._changeColumn (package:flutter_app/app.dart:322:5)
#6      _MyAppState._handleKeyEvent (package:flutter_app/app.dart:72:9)
#7      KeyboardListener.build.<anonymous closure> (package:flutter/src/widgets/keyboard_listener.dart:72:21)
#8      _HighlightModeManager.handleKeyMessage (package:flutter/src/widgets/focus_manager.dart:2244:72)
#9      KeyEventManager._dispatchKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1119:34)
#10     KeyEventManager.handleRawKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1195:17)
#11     BasicMessageChannel.setMessageHandler.<anonymous closure> (package:flutter/src/services/platform_channel.dart:259:49)
#12     TestDefaultBinaryMessenger.handlePlatformMessage (package:flutter_test/src/test_default_binary_messenger.dart:99:42)
#13     KeyEventSimulator._simulateKeyEventByRawEvent.<anonymous closure> (package:flutter_test/src/event_simulation.dart:665:79)
#16     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#17     KeyEventSimulator._simulateKeyEventByRawEvent (package:flutter_test/src/event_simulation.dart:663:27)
#18     KeyEventSimulator.simulateKeyDownEvent.simulateByRawEvent (package:flutter_test/src/event_simulation.dart:751:14)
#19     KeyEventSimulator.simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:772:23)
#20     simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:897:48)
#21     WidgetController.sendKeyEvent (package:flutter_test/src/controller.dart:2131:32)
#22     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:45:18)
<asynchronous suspension>
#23     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#24     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
00:06 +12 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Navigation Right Auto-Creates Item [E]                                                            
  Test failed. See exception logs above.
  The test description was: Navigation Right Auto-Creates Item
  
[VERIFY_FLOW] UI Rebuild: Column Subtasks items changed from 0 to 1
00:06 +12 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Mock Mentor Mode responds correctly                                         
To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart -p vm --plain-name 'Navigation Right Auto-Creates Item'
00:06 +12 -2: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Cleanup Empty Items on Navigation                                                                 
Key event: LogicalKeyboardKey#2604c(keyId: "0x10000000d", keyLabel: "Enter", debugName: "Enter"), AssistantActive: false
[VERIFY_FLOW] Data Update: addProject()
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test:
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveProject (package:flutter_app/data/repository/isar_storage_repository.dart:89:11)
#2      DataService.addProject (package:flutter_app/services/data_service.dart:26:17)
#3      _MyAppState._handleEnterKey.<anonymous closure> (package:flutter_app/app.dart:102:36)
#4      State.setState (package:flutter/src/widgets/framework.dart:1199:30)
#5      _MyAppState._handleEnterKey (package:flutter_app/app.dart:100:5)
#6      _MyAppState._handleKeyEvent (package:flutter_app/app.dart:78:11)
#7      KeyboardListener.build.<anonymous closure> (package:flutter/src/widgets/keyboard_listener.dart:72:21)
#8      _HighlightModeManager.handleKeyMessage (package:flutter/src/widgets/focus_manager.dart:2244:72)
#9      KeyEventManager._dispatchKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1119:34)
#10     KeyEventManager.handleRawKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1195:17)
#11     BasicMessageChannel.setMessageHandler.<anonymous closure> (package:flutter/src/services/platform_channel.dart:259:49)
#12     TestDefaultBinaryMessenger.handlePlatformMessage (package:flutter_test/src/test_default_binary_messenger.dart:99:42)
#13     KeyEventSimulator._simulateKeyEventByRawEvent.<anonymous closure> (package:flutter_test/src/event_simulation.dart:665:79)
#16     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#17     KeyEventSimulator._simulateKeyEventByRawEvent (package:flutter_test/src/event_simulation.dart:663:27)
#18     KeyEventSimulator.simulateKeyDownEvent.simulateByRawEvent (package:flutter_test/src/event_simulation.dart:751:14)
#19     KeyEventSimulator.simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:772:23)
#20     simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:897:48)
#21     WidgetController.sendKeyEvent (package:flutter_test/src/controller.dart:2131:32)
#22     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:67:18)
<asynchronous suspension>
#23     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#24     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from dart:async and package:stack_trace)

The test description was:
  Cleanup Empty Items on Navigation
════════════════════════════════════════════════════════════════════════════════════════════════════
00:06 +12 -3: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart: Cleanup Empty Items on Navigation [E]                                                             
  Test failed. See exception logs above.
  The test description was: Cleanup Empty Items on Navigation
  
[VERIFY_FLOW] UI Rebuild: Column Projects items changed from 1 to 2
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveProject (package:flutter_app/data/repository/isar_storage_repository.dart:89:11)
#2      DataService.updateTitle (package:flutter_app/services/data_service.dart:181:21)
#3      _MyAppState.build.<anonymous closure> (package:flutter_app/app.dart:420:33)
#4      _EditableColumnState._addItemInternal.<anonymous closure> (package:flutter_app/ui/widgets/editable_column.dart:73:24)
#5      ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#6      ValueNotifier.value= (package:flutter/src/foundation/change_notifier.dart:559:5)
#7      TextEditingController.value= (package:flutter/src/widgets/editable_text.dart:291:11)
#8      TextEditingController.selection= (package:flutter/src/widgets/editable_text.dart:351:5)
#9      EditableTextState._handleSelectionChanged (package:flutter/src/widgets/editable_text.dart:4282:23)
#10     EditableTextState._handleFocusChanged (package:flutter/src/widgets/editable_text.dart:4720:9)
#11     ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#12     FocusNode._notify (package:flutter/src/widgets/focus_manager.dart:1131:5)
#13     FocusManager.applyFocusChangesIfNeeded (package:flutter/src/widgets/focus_manager.dart:1995:12)
#23     FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:189:18)
#24     FakeAsync.flushMicrotasks (package:fake_async/fake_async.dart:200:32)
#25     AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1337:26)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#30     WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:719:23)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     WidgetTester.pumpAndSettle (package:flutter_test/src/widget_tester.dart:712:27)
#35     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:68:18)
<asynchronous suspension>
#36     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#37     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 14 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
  Test failed. See exception logs above.
  The test description was: Cleanup Empty Items on Navigation
  
[VERIFY_FLOW] Data Update: addProject()
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveProject (package:flutter_app/data/repository/isar_storage_repository.dart:89:11)
#2      DataService.addProject (package:flutter_app/services/data_service.dart:26:17)
#3      _MyAppState.build.<anonymous closure> (package:flutter_app/app.dart:409:48)
#4      _EditableColumnState._addNewItem (package:flutter_app/ui/widgets/editable_column.dart:194:17)
#5      _EditableColumnState._addItemInternal.<anonymous closure> (package:flutter_app/ui/widgets/editable_column.dart:95:13)
#6      _HighlightModeManager.handleKeyMessage (package:flutter/src/widgets/focus_manager.dart:2244:72)
#7      KeyEventManager._dispatchKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1119:34)
#8      KeyEventManager.handleRawKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1195:17)
#9      BasicMessageChannel.setMessageHandler.<anonymous closure> (package:flutter/src/services/platform_channel.dart:259:49)
#10     TestDefaultBinaryMessenger.handlePlatformMessage (package:flutter_test/src/test_default_binary_messenger.dart:99:42)
#11     KeyEventSimulator._simulateKeyEventByRawEvent.<anonymous closure> (package:flutter_test/src/event_simulation.dart:665:79)
#14     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#15     KeyEventSimulator._simulateKeyEventByRawEvent (package:flutter_test/src/event_simulation.dart:663:27)
#16     KeyEventSimulator.simulateKeyDownEvent.simulateByRawEvent (package:flutter_test/src/event_simulation.dart:751:14)
#17     KeyEventSimulator.simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:772:23)
#18     simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:897:48)
#19     WidgetController.sendKeyEvent (package:flutter_test/src/controller.dart:2131:32)
#20     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:72:18)
<asynchronous suspension>
#21     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#22     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
  Test failed. See exception logs above.
  The test description was: Cleanup Empty Items on Navigation
  
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveProject (package:flutter_app/data/repository/isar_storage_repository.dart:89:11)
#2      DataService.updateTitle (package:flutter_app/services/data_service.dart:181:21)
#3      _MyAppState.build.<anonymous closure> (package:flutter_app/app.dart:420:33)
#4      _EditableColumnState._addItemInternal.<anonymous closure> (package:flutter_app/ui/widgets/editable_column.dart:73:24)
#5      ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#6      ValueNotifier.value= (package:flutter/src/foundation/change_notifier.dart:559:5)
#7      TextEditingController.value= (package:flutter/src/widgets/editable_text.dart:291:11)
#8      TextEditingController.selection= (package:flutter/src/widgets/editable_text.dart:351:5)
#9      EditableTextState._handleSelectionChanged (package:flutter/src/widgets/editable_text.dart:4282:23)
#10     EditableTextState._handleFocusChanged (package:flutter/src/widgets/editable_text.dart:4720:9)
#11     ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#12     FocusNode._notify (package:flutter/src/widgets/focus_manager.dart:1131:5)
#13     FocusManager.applyFocusChangesIfNeeded (package:flutter/src/widgets/focus_manager.dart:1995:12)
#23     FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:189:18)
#24     FakeAsync.flushMicrotasks (package:fake_async/fake_async.dart:200:32)
#25     AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1337:26)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#30     WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:719:23)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     WidgetTester.pumpAndSettle (package:flutter_test/src/widget_tester.dart:712:27)
#35     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:73:18)
<asynchronous suspension>
#36     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#37     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 14 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
  Test failed. See exception logs above.
  The test description was: Cleanup Empty Items on Navigation
  
Key event: LogicalKeyboardKey#88515(keyId: "0x100000304", keyLabel: "Arrow Up", debugName: "Arrow Up"), AssistantActive: false
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.deleteProject (package:flutter_app/data/repository/isar_storage_repository.dart:132:11)
#2      DataService.deleteItem (package:flutter_app/services/data_service.dart:87:20)
#3      _MyAppState._moveSelection.<anonymous closure> (package:flutter_app/app.dart:192:24)
#4      State.setState (package:flutter/src/widgets/framework.dart:1199:30)
#5      _MyAppState._moveSelection (package:flutter_app/app.dart:185:5)
#6      _MyAppState._handleKeyEvent (package:flutter_app/app.dart:70:9)
#7      KeyboardListener.build.<anonymous closure> (package:flutter/src/widgets/keyboard_listener.dart:72:21)
#8      _HighlightModeManager.handleKeyMessage (package:flutter/src/widgets/focus_manager.dart:2244:72)
#9      KeyEventManager._dispatchKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1119:34)
#10     KeyEventManager.handleRawKeyMessage (package:flutter/src/services/hardware_keyboard.dart:1195:17)
#11     BasicMessageChannel.setMessageHandler.<anonymous closure> (package:flutter/src/services/platform_channel.dart:259:49)
#12     TestDefaultBinaryMessenger.handlePlatformMessage (package:flutter_test/src/test_default_binary_messenger.dart:99:42)
#13     KeyEventSimulator._simulateKeyEventByRawEvent.<anonymous closure> (package:flutter_test/src/event_simulation.dart:665:79)
#16     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#17     KeyEventSimulator._simulateKeyEventByRawEvent (package:flutter_test/src/event_simulation.dart:663:27)
#18     KeyEventSimulator.simulateKeyDownEvent.simulateByRawEvent (package:flutter_test/src/event_simulation.dart:751:14)
#19     KeyEventSimulator.simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:772:23)
#20     simulateKeyDownEvent (package:flutter_test/src/event_simulation.dart:897:48)
#21     WidgetController.sendKeyEvent (package:flutter_test/src/controller.dart:2131:32)
#22     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:88:18)
<asynchronous suspension>
#23     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#24     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
  Test failed. See exception logs above.
  The test description was: Cleanup Empty Items on Navigation
  
[VERIFY_FLOW] UI Rebuild: Column Projects items changed from 3 to 2
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test (but after the test had completed):
LateInitializationError: Field '_isar@157198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.saveProject (package:flutter_app/data/repository/isar_storage_repository.dart:89:11)
#2      DataService.updateTitle (package:flutter_app/services/data_service.dart:181:21)
#3      _MyAppState.build.<anonymous closure> (package:flutter_app/app.dart:420:33)
#4      _EditableColumnState._addItemInternal.<anonymous closure> (package:flutter_app/ui/widgets/editable_column.dart:73:24)
#5      ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#6      ValueNotifier.value= (package:flutter/src/foundation/change_notifier.dart:559:5)
#7      TextEditingController.value= (package:flutter/src/widgets/editable_text.dart:291:11)
#8      TextEditingController.selection= (package:flutter/src/widgets/editable_text.dart:351:5)
#9      EditableTextState._handleSelectionChanged (package:flutter/src/widgets/editable_text.dart:4282:23)
#10     EditableTextState._handleFocusChanged (package:flutter/src/widgets/editable_text.dart:4720:9)
#11     ChangeNotifier.notifyListeners (package:flutter/src/foundation/change_notifier.dart:435:24)
#12     FocusNode._notify (package:flutter/src/widgets/focus_manager.dart:1131:5)
#13     FocusManager.applyFocusChangesIfNeeded (package:flutter/src/widgets/focus_manager.dart:1995:12)
#23     FakeAsync.run.<anonymous closure>.<anonymous closure> (package:fake_async/fake_async.dart:189:18)
#24     FakeAsync.flushMicrotasks (package:fake_async/fake_async.dart:200:32)
#25     AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1337:26)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#30     WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:719:23)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     WidgetTester.pumpAndSettle (package:flutter_test/src/widget_tester.dart:712:27)
#35     main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart:89:18)
<asynchronous suspension>
#36     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#37     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 14 frames from dart:async and package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
  Test failed. See exception logs above.
  The test description was: Cleanup Empty Items on Navigation
  

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/nav_create_cleanup_test.dart -p vm --plain-name 'Cleanup Empty Items on Navigation'
00:07 +12 -3: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Mock Mentor Mode responds correctly                                         00:07 +12 -3: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: Navigation, Typing, and Checkbox Toggle Test                                                             
Key event: LogicalKeyboardKey#80d00(keyId: "0x100000301", keyLabel: "Arrow Down", debugName: "Arrow Down"), AssistantActive: false
00:07 +12 -3: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/widget_test.dart: App smoke test                                                                                                
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test:
The finder "Found 0 widgets with type "TextField" that are ancestors of widgets with text "Inbox":
[]" (used in a call to "tap()") could not find any matching widgets.

When the exception was thrown, this was the stack:
#0      WidgetController._getElementPoint (package:flutter_test/src/controller.dart:2009:7)
#1      WidgetController.getCenter (package:flutter_test/src/controller.dart:1861:12)
#2      WidgetController.tap (package:flutter_test/src/controller.dart:1041:7)
#3      main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/widget_test.dart:18:18)
<asynchronous suspension>
#4      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#5      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

The test description was:
  App smoke test
════════════════════════════════════════════════════════════════════════════════════════════════════
00:07 +12 -4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/widget_test.dart: App smoke test [E]                                                                                            
  Test failed. See exception logs above.
  The test description was: App smoke test
  

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/widget_test.dart -p vm --plain-name 'App smoke test'
00:07 +13 -4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: Navigation, Typing, and Checkbox Toggle Test                                                             00:07 +13 -4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Separate histories                                                          
Warning: No API Key provided. Using Mock Mode.
[VERIFY_FLOW] Service Receive: Assistant Task (Mode: Assistant)
00:07 +13 -4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: Navigation, Typing, and Checkbox Toggle Test                                                             00:07 +13 -4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Modification request adds to pendingActions instead of executing               
Warning: No API Key provided. Using Mock Mode.
[VERIFY_FLOW] Service Receive: create a new project 'Review Me' (Mode: Assistant)
00:07 +13 -4: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: Navigation, Typing, and Checkbox Toggle Test                                                             
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 333 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/lib/ui/assistant_screen.dart:149:14

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#5e20c relayoutBoundary=up13 OVERFLOWING:
  needs compositing
  creator: Row ← Padding ← DecoratedBox ← ConstrainedBox ← Container ← Column ← ColoredBox ← Container
    ← Expanded ← Row ← AssistantScreen ← Expanded ← ⋯
  parentData: offset=Offset(16.0, 0.0) (can use size)
  constraints: BoxConstraints(0.0<=w<=234.2, h=49.8)
  size: Size(234.2, 49.8)
  direction: horizontal
  mainAxisAlignment: spaceBetween
  mainAxisSize: max
  crossAxisAlignment: center
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test:
LateInitializationError: Field '_isar@455198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.getChatHistory (package:flutter_app/data/repository/isar_storage_repository.dart:170:24)
#2      DataService.getChatHistory (package:flutter_app/services/data_service.dart:321:24)
#3      AssistantService._loadHistory (package:flutter_app/services/assistant_service.dart:52:49)
#4      new AssistantService (package:flutter_app/services/assistant_service.dart:44:5)
#5      assistantServiceProvider.<anonymous closure> (package:flutter_app/ui/assistant_screen.dart:12:10)
#6      ChangeNotifierProvider._create (package:flutter_riverpod/src/change_notifier_provider/base.dart:120:21)
#7      ChangeNotifierProviderElement.create.<anonymous closure> (package:flutter_riverpod/src/change_notifier_provider/base.dart:208:64)
#8      Result.guard (package:riverpod/src/result.dart:21:28)
#9      ChangeNotifierProviderElement.create (package:flutter_riverpod/src/change_notifier_provider/base.dart:208:43)
#10     ProviderElementBase.buildState (package:riverpod/src/framework/element.dart:426:7)
#11     ProviderElementBase.mount (package:riverpod/src/framework/element.dart:228:5)
#12     _StateReader._create (package:riverpod/src/framework/container.dart:47:11)
#13     _StateReader.getElement (package:riverpod/src/framework/container.dart:35:52)
#14     ProviderContainer.readProviderElement.<anonymous closure> (package:riverpod/src/framework/container.dart:440:40)
#15     ProviderContainer.readProviderElement (package:riverpod/src/framework/container.dart:475:8)
#16     ProviderBase.addListener (package:riverpod/src/framework/provider_base.dart:79:26)
#17     ProviderContainer.listen (package:riverpod/src/framework/container.dart:280:21)
#18     ConsumerStatefulElement.watch.<anonymous closure> (package:flutter_riverpod/src/consumer.dart:564:25)
#19     _LinkedHashMapMixin.putIfAbsent (dart:_compact_hash:674:23)
#20     ConsumerStatefulElement.watch (package:flutter_riverpod/src/consumer.dart:557:26)
#21     _AssistantScreenState.build (package:flutter_app/ui/assistant_screen.dart:54:27)
#22     StatefulElement.build (package:flutter/src/widgets/framework.dart:5833:27)
#23     ConsumerStatefulElement.build (package:flutter_riverpod/src/consumer.dart:539:20)
#24     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5723:15)
#25     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#26     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#27     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:5705:5)
#28     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5875:11)
#29     ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
#30     Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#31     Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#32     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#33     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#34     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#35     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#36     Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#37     MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#38     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#39     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#40     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#41     StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#42     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#43     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#44     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#45     StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#46     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#47     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#48     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#49     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#50     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#51     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#52     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#53     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#54     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#55     Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#56     MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#57     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#58     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#59     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#60     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#61     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#62     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#63     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#64     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#65     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#66     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#67     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#68     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#69     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#70     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#71     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#72     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#73     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#74     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#75     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#76     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#77     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#78     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#79     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#80     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#81     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#82     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#83     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#84     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#85     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#86     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#87     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#88     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#89     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#90     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#91     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#92     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#93     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#94     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#95     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#96     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#97     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#98     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#99     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#100    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#101    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#102    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#103    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#104    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#105    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#106    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#107    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#108    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#109    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#110    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#111    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#112    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#113    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#114    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#115    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#116    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#117    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#118    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#119    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#120    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#121    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#122    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#123    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#124    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#125    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#126    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#127    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#128    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#129    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#130    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#131    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#132    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#133    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#134    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#135    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#136    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#137    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#138    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#139    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#140    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#141    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#142    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#143    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#144    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#145    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#146    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#147    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#148    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#149    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#150    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#151    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#152    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#153    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#154    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#155    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#156    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#157    Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#158    MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#159    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#160    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#161    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#162    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#163    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#164    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#165    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#166    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#167    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#168    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#169    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#170    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#171    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#172    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#173    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#174    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#175    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#176    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#177    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#178    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#179    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#180    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#181    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#182    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#183    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#184    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#185    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#186    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#187    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#188    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#189    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#190    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#191    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#192    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#193    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#194    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#195    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#196    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#197    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#198    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#199    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#200    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#201    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#202    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#203    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#204    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#205    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#206    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#207    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#208    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#209    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#210    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#211    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#212    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#213    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#214    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#215    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#216    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#217    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#218    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#219    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#220    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#221    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#222    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#223    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#224    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#225    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#226    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#227    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#228    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#229    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#230    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#231    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#232    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#233    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#234    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#235    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#236    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#237    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#238    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#239    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#240    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#241    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#242    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#243    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#244    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#245    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#246    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#247    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#248    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#249    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#250    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#251    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#252    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#253    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#254    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#255    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#256    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#257    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#258    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#259    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#260    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#261    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#262    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#263    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#264    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#265    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#266    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#267    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#268    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#269    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#270    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#271    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#272    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#273    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#274    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#275    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#276    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#277    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#278    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#279    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#280    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#281    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#282    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#283    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#284    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#285    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#286    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#287    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#288    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#289    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#290    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#291    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#292    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#293    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#294    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#295    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#296    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#297    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#300    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#301    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#302    WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:719:23)
#305    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#306    WidgetTester.pumpAndSettle (package:flutter_test/src/widget_tester.dart:712:27)
#307    main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart:30:18)
<asynchronous suspension>
#308    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#309    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

The test description was:
  Navigation, Typing, and Checkbox Toggle Test
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:07 +13 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: Navigation, Typing, and Checkbox Toggle Test [E]                                                         
  Test failed. See exception logs above.
  The test description was: Navigation, Typing, and Checkbox Toggle Test
  
00:08 +13 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Separate histories                                                          00:08 +13 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart: Hierarchical Navigation and Content Update Test                                              
Key event: LogicalKeyboardKey#80d00(keyId: "0x100000301", keyLabel: "Arrow Down", debugName: "Arrow Down"), AssistantActive: false
00:08 +13 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Separate histories                                                          
[VERIFY_FLOW] Service Receive: Mentor Help (Mode: Mentor)
00:08 +13 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Modification request adds to pendingActions instead of executing               
[VERIFY_FLOW] Regex Match: Success for Project
[VERIFY_FLOW] Regex Captured Title: 'Review Me'
[VERIFY_FLOW] Mock Tool Proposed: add_project
00:08 +14 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/mentor_mode_test.dart: AssistantService Mentor Mode Separate histories                                                          00:08 +14 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Accepting action executes and moves to history                                 
Warning: No API Key provided. Using Mock Mode.
[VERIFY_FLOW] Service Receive: create a new project 'Review Me' (Mode: Assistant)
00:08 +14 -5: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart: Hierarchical Navigation and Content Update Test                                              
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 333 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/lib/ui/assistant_screen.dart:149:14

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#2ae01 relayoutBoundary=up13 OVERFLOWING:
  needs compositing
  creator: Row ← Padding ← DecoratedBox ← ConstrainedBox ← Container ← Column ← ColoredBox ← Container
    ← Expanded ← Row ← AssistantScreen ← Expanded ← ⋯
  parentData: offset=Offset(16.0, 0.0) (can use size)
  constraints: BoxConstraints(0.0<=w<=234.2, h=49.8)
  size: Size(234.2, 49.8)
  direction: horizontal
  mainAxisAlignment: spaceBetween
  mainAxisSize: max
  crossAxisAlignment: center
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test:
LateInitializationError: Field '_isar@455198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.getChatHistory (package:flutter_app/data/repository/isar_storage_repository.dart:170:24)
#2      DataService.getChatHistory (package:flutter_app/services/data_service.dart:321:24)
#3      AssistantService._loadHistory (package:flutter_app/services/assistant_service.dart:52:49)
#4      new AssistantService (package:flutter_app/services/assistant_service.dart:44:5)
#5      assistantServiceProvider.<anonymous closure> (package:flutter_app/ui/assistant_screen.dart:12:10)
#6      ChangeNotifierProvider._create (package:flutter_riverpod/src/change_notifier_provider/base.dart:120:21)
#7      ChangeNotifierProviderElement.create.<anonymous closure> (package:flutter_riverpod/src/change_notifier_provider/base.dart:208:64)
#8      Result.guard (package:riverpod/src/result.dart:21:28)
#9      ChangeNotifierProviderElement.create (package:flutter_riverpod/src/change_notifier_provider/base.dart:208:43)
#10     ProviderElementBase.buildState (package:riverpod/src/framework/element.dart:426:7)
#11     ProviderElementBase.mount (package:riverpod/src/framework/element.dart:228:5)
#12     _StateReader._create (package:riverpod/src/framework/container.dart:47:11)
#13     _StateReader.getElement (package:riverpod/src/framework/container.dart:35:52)
#14     ProviderContainer.readProviderElement.<anonymous closure> (package:riverpod/src/framework/container.dart:440:40)
#15     ProviderContainer.readProviderElement (package:riverpod/src/framework/container.dart:475:8)
#16     ProviderBase.addListener (package:riverpod/src/framework/provider_base.dart:79:26)
#17     ProviderContainer.listen (package:riverpod/src/framework/container.dart:280:21)
#18     ConsumerStatefulElement.watch.<anonymous closure> (package:flutter_riverpod/src/consumer.dart:564:25)
#19     _LinkedHashMapMixin.putIfAbsent (dart:_compact_hash:674:23)
#20     ConsumerStatefulElement.watch (package:flutter_riverpod/src/consumer.dart:557:26)
#21     _AssistantScreenState.build (package:flutter_app/ui/assistant_screen.dart:54:27)
#22     StatefulElement.build (package:flutter/src/widgets/framework.dart:5833:27)
#23     ConsumerStatefulElement.build (package:flutter_riverpod/src/consumer.dart:539:20)
#24     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5723:15)
#25     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#26     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#27     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:5705:5)
#28     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5875:11)
#29     ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
#30     Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#31     Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#32     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#33     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#34     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#35     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#36     Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#37     MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#38     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#39     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#40     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#41     StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#42     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#43     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#44     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#45     StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#46     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#47     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#48     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#49     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#50     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#51     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#52     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#53     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#54     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#55     Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#56     MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#57     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#58     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#59     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#60     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#61     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#62     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#63     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#64     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#65     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#66     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#67     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#68     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#69     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#70     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#71     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#72     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#73     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#74     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#75     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#76     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#77     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#78     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#79     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#80     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#81     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#82     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#83     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#84     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#85     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#86     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#87     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#88     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#89     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#90     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#91     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#92     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#93     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#94     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#95     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#96     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#97     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#98     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#99     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#100    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#101    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#102    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#103    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#104    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#105    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#106    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#107    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#108    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#109    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#110    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#111    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#112    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#113    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#114    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#115    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#116    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#117    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#118    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#119    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#120    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#121    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#122    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#123    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#124    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#125    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#126    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#127    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#128    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#129    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#130    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#131    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#132    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#133    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#134    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#135    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#136    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#137    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#138    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#139    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#140    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#141    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#142    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#143    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#144    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#145    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#146    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#147    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#148    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#149    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#150    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#151    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#152    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#153    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#154    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#155    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#156    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#157    Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#158    MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#159    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#160    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#161    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#162    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#163    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#164    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#165    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#166    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#167    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#168    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#169    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#170    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#171    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#172    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#173    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#174    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#175    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#176    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#177    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#178    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#179    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#180    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#181    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#182    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#183    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#184    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#185    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#186    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#187    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#188    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#189    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#190    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#191    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#192    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#193    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#194    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#195    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#196    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#197    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#198    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#199    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#200    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#201    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#202    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#203    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#204    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#205    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#206    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#207    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#208    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#209    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#210    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#211    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#212    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#213    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#214    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#215    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#216    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#217    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#218    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#219    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#220    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#221    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#222    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#223    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#224    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#225    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#226    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#227    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#228    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#229    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#230    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#231    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#232    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#233    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#234    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#235    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#236    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#237    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#238    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#239    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#240    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#241    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#242    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#243    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#244    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#245    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#246    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#247    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#248    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#249    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#250    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#251    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#252    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#253    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#254    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#255    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#256    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#257    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#258    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#259    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#260    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#261    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#262    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#263    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#264    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#265    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#266    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#267    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#268    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#269    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#270    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#271    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#272    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#273    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#274    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#275    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#276    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#277    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#278    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#279    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#280    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#281    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#282    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#283    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#284    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#285    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#286    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#287    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#288    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#289    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#290    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#291    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#292    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#293    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#294    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#295    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#296    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#297    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#300    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#301    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#302    WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:719:23)
#305    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#306    WidgetTester.pumpAndSettle (package:flutter_test/src/widget_tester.dart:712:27)
#307    main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart:28:18)
<asynchronous suspension>
#308    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#309    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

The test description was:
  Hierarchical Navigation and Content Update Test
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:08 +14 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart: Hierarchical Navigation and Content Update Test [E]                                          
  Test failed. See exception logs above.
  The test description was: Hierarchical Navigation and Content Update Test
  
00:09 +15 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Accepting action executes and moves to history                                 00:09 +15 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Accepting action executes and moves to history                                 
[VERIFY_FLOW] Regex Match: Success for Project
[VERIFY_FLOW] Regex Captured Title: 'Review Me'
[VERIFY_FLOW] Mock Tool Proposed: add_project
[VERIFY_FLOW] Tool Execution Start: add_project with args {title: Review Me}
00:09 +16 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Accepting action executes and moves to history                                 00:09 +16 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Declining action removes it without executing                                  00:09 +16 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Declining action removes it without executing                                  
Warning: No API Key provided. Using Mock Mode.
[VERIFY_FLOW] Service Receive: create a new project 'Bad Idea' (Mode: Assistant)
00:10 +16 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: Enter key adds new items in all columns                                                                    
Key event: LogicalKeyboardKey#80d00(keyId: "0x100000301", keyLabel: "Arrow Down", debugName: "Arrow Down"), AssistantActive: false
00:10 +16 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/review_layer_test.dart: Review Layer (Mock Mode) Declining action removes it without executing                                  
[VERIFY_FLOW] Regex Match: Success for Project
[VERIFY_FLOW] Regex Captured Title: 'Bad Idea'
[VERIFY_FLOW] Mock Tool Proposed: add_project
00:10 +17 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: Enter key adds new items in all columns                                                                    00:11 +17 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: Enter key adds new items in all columns                                                                    00:11 +17 -6: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: Enter key adds new items in all columns                                                                    
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 333 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/lib/ui/assistant_screen.dart:149:14

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#9aeb8 relayoutBoundary=up13 OVERFLOWING:
  needs compositing
  creator: Row ← Padding ← DecoratedBox ← ConstrainedBox ← Container ← Column ← ColoredBox ← Container
    ← Expanded ← Row ← AssistantScreen ← Expanded ← ⋯
  parentData: offset=Offset(16.0, 0.0) (can use size)
  constraints: BoxConstraints(0.0<=w<=234.2, h=49.8)
  size: Size(234.2, 49.8)
  direction: horizontal
  mainAxisAlignment: spaceBetween
  mainAxisSize: max
  crossAxisAlignment: center
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following LateError was thrown running a test:
LateInitializationError: Field '_isar@455198116' has not been initialized.

When the exception was thrown, this was the stack:
#0      IsarStorageRepository._isar (package:flutter_app/data/repository/isar_storage_repository.dart)
#1      IsarStorageRepository.getChatHistory (package:flutter_app/data/repository/isar_storage_repository.dart:170:24)
#2      DataService.getChatHistory (package:flutter_app/services/data_service.dart:321:24)
#3      AssistantService._loadHistory (package:flutter_app/services/assistant_service.dart:52:49)
#4      new AssistantService (package:flutter_app/services/assistant_service.dart:44:5)
#5      assistantServiceProvider.<anonymous closure> (package:flutter_app/ui/assistant_screen.dart:12:10)
#6      ChangeNotifierProvider._create (package:flutter_riverpod/src/change_notifier_provider/base.dart:120:21)
#7      ChangeNotifierProviderElement.create.<anonymous closure> (package:flutter_riverpod/src/change_notifier_provider/base.dart:208:64)
#8      Result.guard (package:riverpod/src/result.dart:21:28)
#9      ChangeNotifierProviderElement.create (package:flutter_riverpod/src/change_notifier_provider/base.dart:208:43)
#10     ProviderElementBase.buildState (package:riverpod/src/framework/element.dart:426:7)
#11     ProviderElementBase.mount (package:riverpod/src/framework/element.dart:228:5)
#12     _StateReader._create (package:riverpod/src/framework/container.dart:47:11)
#13     _StateReader.getElement (package:riverpod/src/framework/container.dart:35:52)
#14     ProviderContainer.readProviderElement.<anonymous closure> (package:riverpod/src/framework/container.dart:440:40)
#15     ProviderContainer.readProviderElement (package:riverpod/src/framework/container.dart:475:8)
#16     ProviderBase.addListener (package:riverpod/src/framework/provider_base.dart:79:26)
#17     ProviderContainer.listen (package:riverpod/src/framework/container.dart:280:21)
#18     ConsumerStatefulElement.watch.<anonymous closure> (package:flutter_riverpod/src/consumer.dart:564:25)
#19     _LinkedHashMapMixin.putIfAbsent (dart:_compact_hash:674:23)
#20     ConsumerStatefulElement.watch (package:flutter_riverpod/src/consumer.dart:557:26)
#21     _AssistantScreenState.build (package:flutter_app/ui/assistant_screen.dart:54:27)
#22     StatefulElement.build (package:flutter/src/widgets/framework.dart:5833:27)
#23     ConsumerStatefulElement.build (package:flutter_riverpod/src/consumer.dart:539:20)
#24     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5723:15)
#25     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#26     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#27     ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:5705:5)
#28     StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5875:11)
#29     ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
#30     Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#31     Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#32     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#33     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#34     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#35     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#36     Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#37     MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#38     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#39     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#40     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#41     StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#42     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#43     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#44     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#45     StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#46     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#47     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#48     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#49     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#50     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#51     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#52     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#53     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#54     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#55     Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#56     MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#57     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#58     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#59     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#60     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#61     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#62     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#63     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#64     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#65     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#66     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#67     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#68     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#69     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#70     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#71     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#72     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#73     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#74     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#75     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#76     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#77     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#78     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#79     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#80     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#81     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#82     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#83     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#84     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#85     ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#86     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#87     SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#88     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#89     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#90     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#91     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#92     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#93     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#94     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#95     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#96     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#97     StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#98     Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#99     ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#100    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#101    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#102    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#103    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#104    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#105    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#106    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#107    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#108    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#109    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#110    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#111    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#112    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#113    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#114    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#115    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#116    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#117    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#118    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#119    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#120    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#121    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#122    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#123    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#124    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#125    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#126    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#127    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#128    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#129    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#130    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#131    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#132    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#133    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#134    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#135    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#136    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#137    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#138    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#139    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#140    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#141    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#142    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#143    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#144    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#145    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#146    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#147    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#148    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#149    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#150    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#151    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#152    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#153    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#154    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#155    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#156    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#157    Element.updateChildren (package:flutter/src/widgets/framework.dart:4139:32)
#158    MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#159    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#160    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#161    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#162    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#163    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#164    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#165    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#166    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#167    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#168    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#169    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#170    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#171    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#172    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#173    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#174    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#175    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#176    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#177    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#178    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#179    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#180    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#181    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#182    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#183    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#184    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#185    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#186    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#187    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#188    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#189    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#190    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#191    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#192    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#193    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#194    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#195    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#196    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#197    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#198    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#199    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#200    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#201    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#202    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#203    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#204    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#205    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#206    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#207    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#208    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#209    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#210    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#211    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#212    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#213    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#214    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#215    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#216    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#217    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#218    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#219    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#220    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#221    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#222    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#223    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#224    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#225    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#226    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#227    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#228    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#229    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#230    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#231    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#232    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#233    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#234    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#235    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#236    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#237    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#238    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#239    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#240    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#241    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#242    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#243    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#244    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#245    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#246    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#247    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#248    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#249    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#250    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#251    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#252    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#253    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#254    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#255    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#256    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#257    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#258    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#259    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#260    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#261    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#262    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#263    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#264    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#265    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#266    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#267    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#268    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#269    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#270    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#271    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#272    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#273    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#274    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#275    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#276    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#277    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#278    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#279    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#280    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#281    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#282    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#283    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#284    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#285    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#286    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#287    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#288    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#289    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#290    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#291    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#292    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#293    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#294    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#295    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#296    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#297    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#300    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#301    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#302    WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:719:23)
#305    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#306    WidgetTester.pumpAndSettle (package:flutter_test/src/widget_tester.dart:712:27)
#307    main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart:22:18)
<asynchronous suspension>
#308    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#309    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

The test description was:
  Enter key adds new items in all columns
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:11 +17 -7: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: Enter key adds new items in all columns [E]                                                                
  Test failed. See exception logs above.
  The test description was: Enter key adds new items in all columns
  
00:11 +17 -7: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/deletion_test.dart                                                                                                      00:11 +17 -7: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/deletion_test.dart: Deletion Test                                                                                               00:12 +17 -7: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/deletion_test.dart: Deletion Test                                                                                               00:12 +17 -7: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/deletion_test.dart: Deletion Test                                                                                               
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test:
The finder "Found 0 widgets with type "TextField" that are ancestors of widgets with text "Inbox":
[]" (used in a call to "tap()") could not find any matching widgets.

When the exception was thrown, this was the stack:
#0      WidgetController._getElementPoint (package:flutter_test/src/controller.dart:2009:7)
#1      WidgetController.getCenter (package:flutter_test/src/controller.dart:1861:12)
#2      WidgetController.tap (package:flutter_test/src/controller.dart:1041:7)
#3      main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/deletion_test.dart:15:18)
<asynchronous suspension>
#4      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#5      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

The test description was:
  Deletion Test
════════════════════════════════════════════════════════════════════════════════════════════════════
00:12 +17 -8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/deletion_test.dart: Deletion Test [E]                                                                                           
  Test failed. See exception logs above.
  The test description was: Deletion Test
  

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/deletion_test.dart -p vm --plain-name 'Deletion Test'
00:12 +17 -8: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart                                                                                           00:12 +17 -8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: Navigation, Typing, and Checkbox Toggle Test                                                             
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test (but after the test had completed):
pumpAndSettle timed out

When the exception was thrown, this was the stack:
#0      WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:717:11)
<asynchronous suspension>
#1      TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#2      main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart:30:5)
<asynchronous suspension>
#3      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#4      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
00:12 +17 -8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: Navigation, Typing, and Checkbox Toggle Test [E]                                                         
  Test failed. See exception logs above.
  The test description was: Navigation, Typing, and Checkbox Toggle Test
  

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart -p vm --plain-name 'Navigation, Typing, and Checkbox Toggle Test'
00:12 +17 -8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/interaction_test.dart: (tearDownAll)                                                                                            00:12 +17 -8: loading /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart                                                                                           00:12 +17 -8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart: Checked state persistence test                                                                   00:13 +17 -8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart: Checked state persistence test                                                                   00:13 +17 -8: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart: Checked state persistence test                                                                   
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test:
The finder "Found 0 widgets with text "Inbox": []" (used in a call to "tap()") could not find any
matching widgets.

When the exception was thrown, this was the stack:
#0      WidgetController._getElementPoint (package:flutter_test/src/controller.dart:2009:7)
#1      WidgetController.getCenter (package:flutter_test/src/controller.dart:1861:12)
#2      WidgetController.tap (package:flutter_test/src/controller.dart:1041:7)
#3      main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart:16:18)
<asynchronous suspension>
#4      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#5      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

The test description was:
  Checked state persistence test
════════════════════════════════════════════════════════════════════════════════════════════════════
00:13 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart: Checked state persistence test [E]                                                               
  Test failed. See exception logs above.
  The test description was: Checked state persistence test
  

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/checked_persistence_test.dart -p vm --plain-name 'Checked state persistence test'
00:14 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart: Hierarchical Navigation and Content Update Test                                              
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test (but after the test had completed):
pumpAndSettle timed out

When the exception was thrown, this was the stack:
#0      WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:717:11)
<asynchronous suspension>
#1      TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#2      main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart:28:5)
<asynchronous suspension>
#3      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#4      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
00:14 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart: Hierarchical Navigation and Content Update Test [E]                                          
  Test failed. See exception logs above.
  The test description was: Hierarchical Navigation and Content Update Test
  

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart -p vm --plain-name 'Hierarchical Navigation and Content Update Test'
00:14 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart: (tearDownAll)                                                                                00:15 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/hierarchical_navigation_test.dart: (tearDownAll)                                                                                00:15 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: Enter key adds new items in all columns                                                                    
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test (but after the test had completed):
pumpAndSettle timed out

When the exception was thrown, this was the stack:
#0      WidgetTester.pumpAndSettle.<anonymous closure> (package:flutter_test/src/widget_tester.dart:717:11)
<asynchronous suspension>
#1      TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#2      main.<anonymous closure> (file:///Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart:22:5)
<asynchronous suspension>
#3      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#4      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)
════════════════════════════════════════════════════════════════════════════════════════════════════
00:15 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: Enter key adds new items in all columns [E]                                                                
  Test failed. See exception logs above.
  The test description was: Enter key adds new items in all columns
  

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart -p vm --plain-name 'Enter key adds new items in all columns'
00:15 +17 -9: /Users/adi/dev/AssistedIntelligence/src/flutter_app/test/enter_add_test.dart: (tearDownAll)                                                                                              00:15 +17 -9: Some tests failed.                                                                                                                                                                       

```

## Errors
```
test/gemini_api_test.dart:25:7: Error: The non-abstract class 'FakeStorageRepository' is missing implementations for these members:
 - StorageRepository.clearChatHistory
 - StorageRepository.getAllKnowledge
 - StorageRepository.getChatHistory
 - StorageRepository.saveChatMessage
 - StorageRepository.saveKnowledge
Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.

class FakeStorageRepository implements StorageRepository {
      ^^^^^^^^^^^^^^^^^^^^^
lib/data/repository/storage_repository.dart:21:16: Context: 'StorageRepository.clearChatHistory' is defined here.
  Future<void> clearChatHistory(String mode);
               ^^^^^^^^^^^^^^^^
lib/data/repository/storage_repository.dart:25:27: Context: 'StorageRepository.getAllKnowledge' is defined here.
  Future<List<Knowledge>> getAllKnowledge();
                          ^^^^^^^^^^^^^^^
lib/data/repository/storage_repository.dart:20:29: Context: 'StorageRepository.getChatHistory' is defined here.
  Future<List<ChatMessage>> getChatHistory(String mode);
                            ^^^^^^^^^^^^^^
lib/data/repository/storage_repository.dart:19:16: Context: 'StorageRepository.saveChatMessage' is defined here.
  Future<void> saveChatMessage(ChatMessage message, String mode);
               ^^^^^^^^^^^^^^^
lib/data/repository/storage_repository.dart:24:16: Context: 'StorageRepository.saveKnowledge' is defined here.
  Future<void> saveKnowledge(Knowledge knowledge);
               ^^^^^^^^^^^^^

```
