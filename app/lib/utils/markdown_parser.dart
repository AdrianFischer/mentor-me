import 'package:yaml/yaml.dart';
import 'package:uuid/uuid.dart';
import '../models/node.dart';

class MarkdownParser {
  static const _uuid = Uuid();
  static final _idRegex = RegExp(r'<!-- id: ([a-zA-Z0-9-]+) -->$');

  // ─── Node-based parsing (arbitrary depth) ───

  static Node parseNode(String content) {
    // 1. Split Frontmatter
    final parts = content.split('---');
    Map<String, dynamic> frontmatter = {};
    String body = content;

    if (content.trimLeft().startsWith('---') && parts.length >= 3) {
      final yamlStr = parts[1];
      try {
        final yaml = loadYaml(yamlStr);
        if (yaml is Map) {
          frontmatter = Map<String, dynamic>.from(yaml);
        }
      } catch (e) {
        print('Error parsing YAML: $e');
      }
      body = parts.sublist(2).join('---').trim();
    }

    // 2. Parse Body
    String title = 'Untitled';
    StringBuffer rootNotesBuffer = StringBuffer();
    bool titleFound = false;

    // Stack of (node, depth) for tracking current nesting context
    final List<_MutableNode> rootChildren = [];
    final List<(_MutableNode, int)> nodeStack = [];

    final lines = body.split('\n');

    for (var line in lines) {
      if (!titleFound && line.trim().isEmpty) continue;

      if (!titleFound && line.trim().startsWith('# ')) {
        title = line.trim().substring(2).trim();
        titleFound = true;
        continue;
      }

      final trimmed = line.trim();
      final isItemLine = trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ');

      if (isItemLine) {
        final isCompleted = trimmed.startsWith('- [x] ');
        var rawTitle = trimmed.substring(6).trim();

        String id = _uuid.v4();
        final match = _idRegex.firstMatch(rawTitle);
        if (match != null) {
          id = match.group(1)!;
          rawTitle = rawTitle.substring(0, match.start).trim();
        }

        // Depth based on indentation (2 spaces per level)
        final indentLevel = line.indexOf('-');
        final depth = indentLevel ~/ 2; // 0 = top-level child, 1 = grandchild, etc.

        final node = _MutableNode(id, rawTitle, isCompleted);

        // Pop stack until we find a parent at depth-1
        while (nodeStack.isNotEmpty && nodeStack.last.$2 >= depth) {
          nodeStack.removeLast();
        }

        if (nodeStack.isEmpty) {
          // Top-level child of root
          rootChildren.add(node);
        } else {
          // Child of the node at the top of the stack
          nodeStack.last.$1.children.add(node);
        }

        nodeStack.add((node, depth));
      } else {
        // Notes/content line
        if (titleFound) {
          if (nodeStack.isNotEmpty) {
            // Determine which node this note belongs to based on indentation
            final lineIndent = line.length - line.trimLeft().length;
            final currentNode = nodeStack.last.$1;
            final currentDepth = nodeStack.last.$2;
            final expectedNoteIndent = (currentDepth + 1) * 2;

            if (lineIndent >= expectedNoteIndent || line.trim().isEmpty) {
              currentNode.notes ??= "";
              currentNode.notes = ("${currentNode.notes!}\n${line.trim()}").trim();
            } else {
              // Less indented — might belong to a parent node or root
              // Walk up the stack to find the right owner
              bool assigned = false;
              for (int i = nodeStack.length - 1; i >= 0; i--) {
                final (stackNode, stackDepth) = nodeStack[i];
                final requiredIndent = (stackDepth + 1) * 2;
                if (lineIndent >= requiredIndent) {
                  stackNode.notes ??= "";
                  stackNode.notes = ("${stackNode.notes!}\n${line.trim()}").trim();
                  assigned = true;
                  break;
                }
              }
              if (!assigned) {
                rootNotesBuffer.writeln(line);
              }
            }
          } else {
            // No items yet — root notes
            rootNotesBuffer.writeln(line);
          }
        }
      }
    }

    // 3. Construct root Node
    final rootId = frontmatter['id']?.toString() ?? _uuid.v4();
    final isCompleted = frontmatter['is_completed'] == true || frontmatter['isCompleted'] == true;
    final tags = (frontmatter['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rootNotes = rootNotesBuffer.isNotEmpty ? rootNotesBuffer.toString().trim() : null;

    return Node(
      id: rootId,
      title: title,
      isCompleted: isCompleted,
      tags: tags,
      notes: rootNotes,
      children: rootChildren.map((m) => m.toNode(rootId)).toList(),
    );
  }

  static String nodeToMarkdown(Node node) {
    final buffer = StringBuffer();

    // 1. Frontmatter
    buffer.writeln('---');
    buffer.writeln('id: ${node.id}');
    if (node.tags.isNotEmpty) {
      final quotedTags = node.tags.map((t) => '"$t"').join(', ');
      buffer.writeln('tags: [$quotedTags]');
    }
    if (node.isCompleted) {
      buffer.writeln('is_completed: true');
    }
    buffer.writeln('version: 1');
    buffer.writeln('---');
    buffer.writeln();

    // 2. Title
    buffer.writeln('# ${node.title}');
    buffer.writeln();

    // 3. Root Notes
    if (node.notes != null && node.notes!.isNotEmpty) {
      buffer.writeln(node.notes);
      buffer.writeln();
    }

    // 4. Children (recursive)
    for (var child in node.children) {
      _writeNode(buffer, child, 0);
      buffer.writeln(); // blank line between top-level items
    }

    return buffer.toString();
  }

  static void _writeNode(StringBuffer buffer, Node node, int depth) {
    final indent = '  ' * depth;
    final checkbox = node.isCompleted ? '[x]' : '[ ]';
    buffer.writeln('$indent- $checkbox ${node.title} <!-- id: ${node.id} -->');

    // Notes
    if (node.notes != null && node.notes!.isNotEmpty) {
      final noteIndent = '  ' * (depth + 1);
      for (var line in node.notes!.split('\n')) {
        buffer.writeln('$noteIndent$line');
      }
    }

    // Recursive children
    for (var child in node.children) {
      _writeNode(buffer, child, depth + 1);
    }
  }
}

/// Mutable node for parsing — supports arbitrary depth.
class _MutableNode {
  String id;
  String title;
  bool isCompleted;
  String? notes;
  List<_MutableNode> children = [];

  _MutableNode(this.id, this.title, this.isCompleted);

  Node toNode(String parentId) {
    return Node(
      id: id,
      title: title,
      isCompleted: isCompleted,
      notes: notes?.trim(),
      parentId: parentId,
      children: children.map((c) => c.toNode(id)).toList(),
    );
  }
}
