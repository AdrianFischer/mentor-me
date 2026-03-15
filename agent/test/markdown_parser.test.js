import { describe, it, expect } from 'vitest';
import { parseProject, toMarkdown } from '../data/markdown_parser.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const todosDir = path.resolve(__dirname, '../../data/todos');

describe('MarkdownParser', () => {
  describe('parseProject', () => {
    it('parses basic project with frontmatter', () => {
      const content = `---
id: abc-123
version: 1
---

# My Project

- [ ] Task one <!-- id: t1 -->
- [x] Task two <!-- id: t2 -->
`;
      const project = parseProject(content);
      expect(project.id).toBe('abc-123');
      expect(project.title).toBe('My Project');
      expect(project.isCompleted).toBe(false);
      expect(project.tasks).toHaveLength(2);
      expect(project.tasks[0].title).toBe('Task one');
      expect(project.tasks[0].isCompleted).toBe(false);
      expect(project.tasks[0].id).toBe('t1');
      expect(project.tasks[1].title).toBe('Task two');
      expect(project.tasks[1].isCompleted).toBe(true);
      expect(project.tasks[1].id).toBe('t2');
    });

    it('parses completed project', () => {
      const content = `---
id: abc-123
is_completed: true
version: 1
---

# Done Project

- [x] Only task <!-- id: t1 -->
`;
      const project = parseProject(content);
      expect(project.isCompleted).toBe(true);
    });

    it('parses subtasks', () => {
      const content = `---
id: abc-123
version: 1
---

# Project

- [ ] Parent task <!-- id: t1 -->
  - [x] Subtask A <!-- id: s1 -->
  - [ ] Subtask B <!-- id: s2 -->
`;
      const project = parseProject(content);
      expect(project.tasks).toHaveLength(1);
      expect(project.tasks[0].subtasks).toHaveLength(2);
      expect(project.tasks[0].subtasks[0].title).toBe('Subtask A');
      expect(project.tasks[0].subtasks[0].isCompleted).toBe(true);
      expect(project.tasks[0].subtasks[1].title).toBe('Subtask B');
      expect(project.tasks[0].subtasks[1].isCompleted).toBe(false);
    });

    it('parses task notes', () => {
      const content = `---
id: abc-123
version: 1
---

# Project

- [ ] Task with notes <!-- id: t1 -->
  This is a note for the task.
  It spans multiple lines.
`;
      const project = parseProject(content);
      expect(project.tasks[0].notes).toBe('This is a note for the task.\nIt spans multiple lines.');
    });

    it('parses subtask notes', () => {
      const content = `---
id: abc-123
version: 1
---

# Project

- [ ] Parent <!-- id: t1 -->
  - [ ] Sub <!-- id: s1 -->
    This is a subtask note.
`;
      const project = parseProject(content);
      expect(project.tasks[0].subtasks[0].notes).toBe('This is a subtask note.');
    });

    it('parses tags from frontmatter', () => {
      const content = `---
id: abc-123
tags: [work, urgent]
version: 1
---

# Tagged Project
`;
      const project = parseProject(content);
      expect(project.tags).toEqual(['work', 'urgent']);
    });

    it('generates UUID when no id in frontmatter', () => {
      const content = `# No Frontmatter Project

- [ ] A task
`;
      const project = parseProject(content);
      expect(project.id).toBeTruthy();
      expect(project.title).toBe('No Frontmatter Project');
      expect(project.tasks).toHaveLength(1);
      // Task gets a generated UUID too
      expect(project.tasks[0].id).toBeTruthy();
    });

    it('parses project notes before tasks', () => {
      const content = `---
id: abc-123
version: 1
---

# Project

Some project-level notes here.

- [ ] First task <!-- id: t1 -->
`;
      const project = parseProject(content);
      expect(project.notes).toBe('Some project-level notes here.');
    });

    it('handles empty project', () => {
      const content = `---
id: abc-123
version: 1
---

# Empty Project
`;
      const project = parseProject(content);
      expect(project.title).toBe('Empty Project');
      expect(project.tasks).toHaveLength(0);
    });

    it('handles --- in body content', () => {
      const content = `---
id: abc-123
version: 1
---

# Project

- [ ] Task with --- in notes <!-- id: t1 -->
  Some text --- with dashes
`;
      const project = parseProject(content);
      expect(project.tasks[0].title).toBe('Task with --- in notes');
      expect(project.tasks[0].notes).toContain('with dashes');
    });
  });

  describe('toMarkdown', () => {
    it('serializes a basic project', () => {
      const project = {
        id: 'abc-123',
        title: 'My Project',
        isCompleted: false,
        tags: [],
        notes: null,
        tasks: [
          {
            id: 't1',
            title: 'Task one',
            isCompleted: false,
            projectId: 'abc-123',
            notes: null,
            subtasks: [],
          },
        ],
      };
      const md = toMarkdown(project);
      expect(md).toContain('id: abc-123');
      expect(md).toContain('# My Project');
      expect(md).toContain('- [ ] Task one <!-- id: t1 -->');
      expect(md).not.toContain('is_completed');
    });

    it('serializes completed project', () => {
      const project = {
        id: 'abc-123',
        title: 'Done',
        isCompleted: true,
        tags: [],
        notes: null,
        tasks: [],
      };
      const md = toMarkdown(project);
      expect(md).toContain('is_completed: true');
    });

    it('serializes tags', () => {
      const project = {
        id: 'abc-123',
        title: 'Tagged',
        isCompleted: false,
        tags: ['work', 'urgent'],
        notes: null,
        tasks: [],
      };
      const md = toMarkdown(project);
      expect(md).toContain('tags: [work, urgent]');
    });

    it('serializes subtasks', () => {
      const project = {
        id: 'abc-123',
        title: 'Project',
        isCompleted: false,
        tags: [],
        notes: null,
        tasks: [
          {
            id: 't1',
            title: 'Parent',
            isCompleted: false,
            projectId: 'abc-123',
            notes: null,
            subtasks: [
              { id: 's1', title: 'Sub A', isCompleted: true, notes: null },
              { id: 's2', title: 'Sub B', isCompleted: false, notes: null },
            ],
          },
        ],
      };
      const md = toMarkdown(project);
      expect(md).toContain('  - [x] Sub A <!-- id: s1 -->');
      expect(md).toContain('  - [ ] Sub B <!-- id: s2 -->');
    });

    it('serializes task and subtask notes', () => {
      const project = {
        id: 'abc-123',
        title: 'Project',
        isCompleted: false,
        tags: [],
        notes: null,
        tasks: [
          {
            id: 't1',
            title: 'Task',
            isCompleted: false,
            projectId: 'abc-123',
            notes: 'Task note line 1\nTask note line 2',
            subtasks: [
              { id: 's1', title: 'Sub', isCompleted: false, notes: 'Sub note' },
            ],
          },
        ],
      };
      const md = toMarkdown(project);
      expect(md).toContain('  Task note line 1');
      expect(md).toContain('  Task note line 2');
      expect(md).toContain('    Sub note');
    });
  });

  describe('round-trip', () => {
    it('parse -> serialize -> parse produces same data', () => {
      const content = `---
id: round-trip-test
version: 1
---

# Round Trip

- [ ] Task A <!-- id: ta -->
  Note for A
  - [x] Sub 1 <!-- id: s1 -->
  - [ ] Sub 2 <!-- id: s2 -->
    Sub 2 note
- [x] Task B <!-- id: tb -->

`;
      const parsed1 = parseProject(content);
      const serialized = toMarkdown(parsed1);
      const parsed2 = parseProject(serialized);

      expect(parsed2.id).toBe(parsed1.id);
      expect(parsed2.title).toBe(parsed1.title);
      expect(parsed2.tasks).toHaveLength(parsed1.tasks.length);
      for (let i = 0; i < parsed1.tasks.length; i++) {
        expect(parsed2.tasks[i].id).toBe(parsed1.tasks[i].id);
        expect(parsed2.tasks[i].title).toBe(parsed1.tasks[i].title);
        expect(parsed2.tasks[i].isCompleted).toBe(parsed1.tasks[i].isCompleted);
        expect(parsed2.tasks[i].notes).toBe(parsed1.tasks[i].notes);
        expect(parsed2.tasks[i].subtasks).toHaveLength(parsed1.tasks[i].subtasks.length);
        for (let j = 0; j < parsed1.tasks[i].subtasks.length; j++) {
          expect(parsed2.tasks[i].subtasks[j].id).toBe(parsed1.tasks[i].subtasks[j].id);
          expect(parsed2.tasks[i].subtasks[j].title).toBe(parsed1.tasks[i].subtasks[j].title);
          expect(parsed2.tasks[i].subtasks[j].isCompleted).toBe(parsed1.tasks[i].subtasks[j].isCompleted);
          expect(parsed2.tasks[i].subtasks[j].notes).toBe(parsed1.tasks[i].subtasks[j].notes);
        }
      }
    });

    // Round-trip test against all real files in data/todos/
    if (fs.existsSync(todosDir)) {
      const walkDir = (dir) => {
        const files = [];
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
          const fullPath = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            files.push(...walkDir(fullPath));
          } else if (entry.name.endsWith('.md') && entry.name !== 'README.md') {
            files.push(fullPath);
          }
        }
        return files;
      };

      const mdFiles = walkDir(todosDir);
      for (const filePath of mdFiles) {
        const relPath = path.relative(todosDir, filePath);
        it(`round-trips real file: ${relPath}`, () => {
          const content = fs.readFileSync(filePath, 'utf-8');
          const parsed1 = parseProject(content);
          const serialized = toMarkdown(parsed1);
          const parsed2 = parseProject(serialized);

          // Semantic comparison (not byte-identical, since hand-edited files may vary)
          expect(parsed2.id).toBe(parsed1.id);
          expect(parsed2.title).toBe(parsed1.title);
          expect(parsed2.isCompleted).toBe(parsed1.isCompleted);
          expect(parsed2.tasks).toHaveLength(parsed1.tasks.length);
          for (let i = 0; i < parsed1.tasks.length; i++) {
            expect(parsed2.tasks[i].id).toBe(parsed1.tasks[i].id);
            expect(parsed2.tasks[i].title).toBe(parsed1.tasks[i].title);
            expect(parsed2.tasks[i].isCompleted).toBe(parsed1.tasks[i].isCompleted);
            expect(parsed2.tasks[i].subtasks).toHaveLength(parsed1.tasks[i].subtasks.length);
          }
        });
      }
    }
  });
});
