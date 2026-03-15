import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/node.dart';
import '../data/repository/storage_repository.dart';

const _uuid = Uuid();

class TaggedItem {
  final String id;
  final String title;
  final String type;
  final Node node;

  TaggedItem(this.id, this.title, this.type, this.node);
}

class NodeService extends ChangeNotifier {
  final StorageRepository _repository;
  List<Node> _rootNodes = [];
  final Map<String, Timer> _debounceTimers = {};
  bool _isInitialized = false;
  StreamSubscription? _dataSubscription;

  NodeService(this._repository);

  List<Node> get rootNodes => _rootNodes;

  Future<void> initData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _repository.init();

    _dataSubscription = _repository.onDataChanged.listen((_) {
      print("Data change detected. Reloading...");
      _reloadNodes();
    });

    await _reloadNodes();
  }

  Future<void> _reloadNodes() async {
    final nodes = await _repository.getAllNodes();
    _rootNodes = List.from(nodes)..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  // ─── Read Operations ───

  /// Find any node by ID anywhere in the tree.
  Node? findNode(String id) {
    for (final root in _rootNodes) {
      final found = root.findById(id);
      if (found != null) return found;
    }
    return null;
  }

  /// Get the children of a node (or root nodes if parentId is null).
  List<Node> getChildren(String? parentId) {
    if (parentId == null) return _rootNodes;
    final parent = findNode(parentId);
    return parent?.children ?? [];
  }

  /// Returns the full path of IDs from root to target.
  List<String>? pathToNode(String targetId) {
    for (final root in _rootNodes) {
      final path = root.pathTo(targetId);
      if (path != null) return path;
    }
    return null;
  }

  /// Get all tags across all nodes (recursive).
  List<String> get allTags {
    final tags = <String>{};
    void collectTags(Node node) {
      tags.addAll(node.tags);
      for (final child in node.children) {
        collectTags(child);
      }
    }
    for (final root in _rootNodes) {
      collectTags(root);
    }
    return tags.toList()..sort();
  }

  /// Get items matching a tag (recursive).
  List<TaggedItem> getItemsWithTag(String tag) {
    final items = <TaggedItem>[];
    void collect(Node node, int depth) {
      if (node.tags.contains(tag)) {
        final type = depth == 0 ? 'project' : 'node';
        items.add(TaggedItem(node.id, node.title, type, node));
      }
      for (final child in node.children) {
        collect(child, depth + 1);
      }
    }
    for (final root in _rootNodes) {
      collect(root, 0);
    }
    return items;
  }

  // ─── Write Operations ───

  /// Find the root node that contains a given node ID.
  Node? _findRootContaining(String nodeId) {
    for (final root in _rootNodes) {
      if (root.findById(nodeId) != null) return root;
    }
    return null;
  }

  /// Immutable update at any depth in the tree.
  /// Returns the updated root node.
  Node _updateInTree(Node root, String targetId, Node Function(Node) updater) {
    if (root.id == targetId) return updater(root);
    final newChildren = root.children.map((child) {
      if (child.findById(targetId) != null) {
        return _updateInTree(child, targetId, updater);
      }
      return child;
    }).toList();
    return root.copyWith(children: newChildren);
  }

  /// Save a root node (persists to repository).
  Future<void> _saveRoot(Node root) async {
    final idx = _rootNodes.indexWhere((n) => n.id == root.id);
    if (idx != -1) {
      _rootNodes = List.from(_rootNodes)..[idx] = root;
    }
    notifyListeners();
    await _repository.saveNode(root);
  }

  /// Debounced save for a root node.
  void _debounceSaveRoot(Node root) {
    _cancelDebounce(root.id);
    _debounceTimers[root.id] = Timer(const Duration(milliseconds: 1000), () {
      _repository.saveNode(root);
      _debounceTimers.remove(root.id);
    });
  }

  void _cancelDebounce(String id) {
    if (_debounceTimers.containsKey(id)) {
      _debounceTimers[id]!.cancel();
      _debounceTimers.remove(id);
    }
  }

  /// Add a child node to a parent (or as root if parentId is null).
  Future<String?> addChild(String? parentId, String title) async {
    if (parentId == null) {
      return _addRootNode(title, _rootNodes.length);
    }
    final root = _findRootContaining(parentId);
    if (root == null) return null;
    return _addChildToNode(root, parentId, title);
  }

  /// Insert a child at a specific index.
  Future<String?> insertChild(String? parentId, String title, int index) async {
    if (parentId == null) {
      return _addRootNode(title, index);
    }
    final root = _findRootContaining(parentId);
    if (root == null) return null;
    return _addChildToNode(root, parentId, title, index: index);
  }

  Future<String> _addRootNode(String title, int index) async {
    final tags = title.extractTags();
    final node = Node(id: _uuid.v4(), title: title, order: index.toDouble(), tags: tags);

    final newList = List<Node>.from(_rootNodes);
    if (index >= newList.length) {
      newList.add(node);
    } else {
      newList.insert(index, node);
    }
    _rootNodes = newList;
    notifyListeners();
    await _persistRootList();
    return node.id;
  }

  Future<String> _addChildToNode(Node root, String parentId, String title, {int? index}) async {
    final childId = _uuid.v4();
    final tags = title.extractTags();
    final newChild = Node(id: childId, title: title, parentId: parentId, tags: tags);

    final updatedRoot = _updateInTree(root, parentId, (parent) {
      final children = List<Node>.from(parent.children);
      final insertAt = index ?? children.length;
      if (insertAt >= children.length) {
        children.add(newChild);
      } else {
        children.insert(insertAt, newChild);
      }
      // Re-order
      for (int i = 0; i < children.length; i++) {
        children[i] = children[i].copyWith(order: i.toDouble());
      }
      return parent.copyWith(children: children);
    });

    _cancelDebounce(root.id);
    await _saveRoot(updatedRoot);
    return childId;
  }

  Future<void> _persistRootList() async {
    final updatedRoots = List<Node>.from(_rootNodes);
    for (int i = 0; i < updatedRoots.length; i++) {
      final n = updatedRoots[i].copyWith(order: i.toDouble());
      await _repository.saveNode(n);
    }
  }

  /// Delete any node by ID.
  void deleteNode(String id) {
    // Check if it's a root node
    final rootIndex = _rootNodes.indexWhere((n) => n.id == id);
    if (rootIndex != -1) {
      _cancelDebounce(id);
      _rootNodes = List.from(_rootNodes)..removeAt(rootIndex);
      _repository.deleteNode(id);
      notifyListeners();
      return;
    }

    // It's a nested node — find the root and update
    final root = _findRootContaining(id);
    if (root == null) return;

    _cancelDebounce(root.id);
    final updatedRoot = _removeFromTree(root, id);
    final idx = _rootNodes.indexWhere((n) => n.id == root.id);
    if (idx != -1) {
      _rootNodes = List.from(_rootNodes)..[idx] = updatedRoot;
    }
    notifyListeners();
    _repository.saveNode(updatedRoot);
  }

  Node _removeFromTree(Node node, String targetId) {
    final newChildren = <Node>[];
    for (final child in node.children) {
      if (child.id == targetId) continue;
      newChildren.add(_removeFromTree(child, targetId));
    }
    return node.copyWith(children: newChildren);
  }

  /// Update title of any node.
  void updateTitle(String id, String newTitle) {
    final tags = newTitle.extractTags();

    // Root node?
    final rootIdx = _rootNodes.indexWhere((n) => n.id == id);
    if (rootIdx != -1) {
      final updatedRoot = _rootNodes[rootIdx].copyWith(title: newTitle, tags: tags);
      _rootNodes = List.from(_rootNodes)..[rootIdx] = updatedRoot;
      notifyListeners();
      _debounceSaveRoot(updatedRoot);
      return;
    }

    // Nested node
    final root = _findRootContaining(id);
    if (root == null) return;

    final updatedRoot = _updateInTree(root, id, (node) =>
        node.copyWith(title: newTitle, tags: tags));
    final idx = _rootNodes.indexWhere((n) => n.id == root.id);
    if (idx != -1) {
      _rootNodes = List.from(_rootNodes)..[idx] = updatedRoot;
    }
    notifyListeners();
    _debounceSaveRoot(updatedRoot);
  }

  /// Update notes of any node.
  void updateNotes(String id, String newNotes) {
    final rootIdx = _rootNodes.indexWhere((n) => n.id == id);
    if (rootIdx != -1) {
      final updatedRoot = _rootNodes[rootIdx].copyWith(notes: newNotes);
      _rootNodes = List.from(_rootNodes)..[rootIdx] = updatedRoot;
      notifyListeners();
      _debounceSaveRoot(updatedRoot);
      return;
    }

    final root = _findRootContaining(id);
    if (root == null) return;

    final updatedRoot = _updateInTree(root, id, (node) =>
        node.copyWith(notes: newNotes));
    final idx = _rootNodes.indexWhere((n) => n.id == root.id);
    if (idx != -1) {
      _rootNodes = List.from(_rootNodes)..[idx] = updatedRoot;
    }
    notifyListeners();
    _debounceSaveRoot(updatedRoot);
  }

  /// Set completion status of any node.
  Future<void> setNodeStatus(String id, bool isCompleted) async {
    _cancelDebounce(id);
    final rootIdx = _rootNodes.indexWhere((n) => n.id == id);
    if (rootIdx != -1) {
      final updatedRoot = _rootNodes[rootIdx].copyWith(isCompleted: isCompleted);
      _rootNodes = List.from(_rootNodes)..[rootIdx] = updatedRoot;
      notifyListeners();
      _repository.saveNode(updatedRoot);
      return;
    }

    final root = _findRootContaining(id);
    if (root == null) return;

    _cancelDebounce(root.id);
    final updatedRoot = _updateInTree(root, id, (node) =>
        node.copyWith(isCompleted: isCompleted));
    await _saveRoot(updatedRoot);
  }

  /// Set AI status of any node.
  Future<void> setAiStatus(String id, AiStatus status) async {
    _cancelDebounce(id);
    final shouldComplete = status == AiStatus.done;

    final root = _findRootContaining(id);
    if (root == null) return;

    _cancelDebounce(root.id);
    final updatedRoot = _updateInTree(root, id, (node) =>
        node.copyWith(
          aiStatus: status,
          isCompleted: shouldComplete ? true : node.isCompleted,
        ));
    await _saveRoot(updatedRoot);
  }

  /// Reorder children of a parent.
  void reorderChildren(String? parentId, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (parentId == null) {
      // Reorder root nodes
      final newList = List<Node>.from(_rootNodes);
      final item = newList.removeAt(oldIndex);
      newList.insert(newIndex, item);
      for (int i = 0; i < newList.length; i++) {
        newList[i] = newList[i].copyWith(order: i.toDouble());
        _repository.saveNode(newList[i]);
      }
      _rootNodes = newList;
      notifyListeners();
      return;
    }

    // Reorder children of a node
    final root = _findRootContaining(parentId);
    if (root == null) return;

    final updatedRoot = _updateInTree(root, parentId, (parent) {
      final children = List<Node>.from(parent.children);
      final item = children.removeAt(oldIndex);
      children.insert(newIndex, item);
      for (int i = 0; i < children.length; i++) {
        children[i] = children[i].copyWith(order: i.toDouble());
      }
      return parent.copyWith(children: children);
    });

    final idx = _rootNodes.indexWhere((n) => n.id == root.id);
    if (idx != -1) {
      _rootNodes = List.from(_rootNodes)..[idx] = updatedRoot;
    }
    notifyListeners();
    _repository.saveNode(updatedRoot);
  }

  /// Set a goal on a node.
  void setGoal(String nodeId, TaskGoal goal) {
    final root = _findRootContaining(nodeId);
    if (root == null) return;

    final updatedRoot = _updateInTree(root, nodeId, (node) =>
        node.copyWith(goal: goal));
    final idx = _rootNodes.indexWhere((n) => n.id == root.id);
    if (idx != -1) {
      _rootNodes = List.from(_rootNodes)..[idx] = updatedRoot;
    }
    notifyListeners();
    _repository.saveNode(updatedRoot);
  }

  /// Record progress on a goal.
  void recordGoalProgress(String nodeId, {double? amount, bool? isSuccess, String? note}) {
    final node = findNode(nodeId);
    if (node == null || node.goal == null) return;

    TaskGoal? newGoal;
    node.goal!.map(
      numeric: (n) {
        if (amount == null) return;
        final newCurrent = n.current + amount;
        final transaction = GoalTransaction(
          id: _uuid.v4(),
          amount: amount,
          date: DateTime.now(),
          note: note,
        );
        newGoal = n.copyWith(
          current: newCurrent,
          history: [...n.history, transaction],
        );
      },
      habit: (h) {
        if (isSuccess == null) return;
        final entry = HabitRecord(
          date: DateTime.now(),
          isSuccess: isSuccess,
          note: note,
        );
        newGoal = h.copyWith(
          history: [...h.history, entry],
        );
      },
    );

    if (newGoal != null) {
      final root = _findRootContaining(nodeId);
      if (root == null) return;

      final updatedRoot = _updateInTree(root, nodeId, (n) =>
          n.copyWith(goal: newGoal));
      final idx = _rootNodes.indexWhere((n) => n.id == root.id);
      if (idx != -1) {
        _rootNodes = List.from(_rootNodes)..[idx] = updatedRoot;
      }
      notifyListeners();
      _repository.saveNode(updatedRoot);
    }
  }

  /// Add image path to a node.
  Future<void> addLocalImagePath(String nodeId, String path) async {
    final node = findNode(nodeId);
    if (node == null || node.localImagePaths.contains(path)) return;

    final root = _findRootContaining(nodeId);
    if (root == null) return;

    final updatedRoot = _updateInTree(root, nodeId, (n) =>
        n.copyWith(localImagePaths: [...n.localImagePaths, path]));
    await _saveRoot(updatedRoot);
  }

  /// Remove image path from a node.
  Future<void> removeLocalImagePath(String nodeId, String path) async {
    final node = findNode(nodeId);
    if (node == null) return;

    final newPaths = List<String>.from(node.localImagePaths)..remove(path);
    if (newPaths.length == node.localImagePaths.length) return;

    final root = _findRootContaining(nodeId);
    if (root == null) return;

    final updatedRoot = _updateInTree(root, nodeId, (n) =>
        n.copyWith(localImagePaths: newPaths));
    await _saveRoot(updatedRoot);
  }

  // ─── Lifecycle ───

  void clear() {
    _rootNodes = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
