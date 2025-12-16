# Service Layer

This layer contains the business logic of the application.

## DataService
The `DataService` is the central brain of the app. It manages the state of Projects, Tasks, and Subtasks.
-   It extends `ChangeNotifier` (consumed by Riverpod).
-   It provides methods that return UUIDs, making it easy for the AI to know what it just created.
-   It operates on UUIDs, not list indices, ensuring robustness against concurrent changes.




