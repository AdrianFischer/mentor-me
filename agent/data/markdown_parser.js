import yaml from 'js-yaml';
import { v4 as uuidv4 } from 'uuid';

/**
 * Parses a Markdown file with YAML frontmatter into a project object.
 * Direct port of app/lib/utils/markdown_parser.dart
 */
export function parseProject(content) {
  // 1. Split Frontmatter
  const parts = content.split('---');
  let frontmatter = {};
  let body = content;

  if (content.trimStart().startsWith('---') && parts.length >= 3) {
    const yamlStr = parts[1];
    try {
      const parsed = yaml.load(yamlStr);
      if (parsed && typeof parsed === 'object') {
        frontmatter = parsed;
      }
    } catch (e) {
      console.error('Error parsing YAML:', e);
    }
    // Re-join the rest in case "---" appears in the body
    body = parts.slice(2).join('---').trim();
  }

  // 2. Parse Body (Title, Notes, Tasks)
  let title = 'Untitled';
  const tasks = [];
  const projectNotesLines = [];

  let currentTask = null;
  let currentSubtask = null;
  let titleFound = false;

  const lines = body.split('\n');

  for (const line of lines) {
    if (!titleFound && line.trim() === '') continue;

    if (!titleFound && line.trim().startsWith('# ')) {
      title = line.trim().substring(2).trim();
      titleFound = true;
      continue;
    }

    // Check for Task
    const trimmed = line.trim();
    const isTaskLine = trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ');

    if (isTaskLine) {
      const isCompleted = trimmed.startsWith('- [x] ');
      let rawTitle = trimmed.substring(6).trim();

      // Extract ID if present
      let id = uuidv4();
      const idMatch = rawTitle.match(/<!-- id: ([a-zA-Z0-9-]+) -->$/);
      if (idMatch) {
        id = idMatch[1];
        rawTitle = rawTitle.substring(0, idMatch.index).trim();
      }

      // Determine level based on indentation
      const indentLevel = line.indexOf('-');

      if (indentLevel >= 2 && currentTask) {
        // It is a subtask
        const subtask = { id, title: rawTitle, isCompleted, notes: null };
        currentTask.subtasks.push(subtask);
        currentSubtask = subtask;
      } else {
        // It is a root task
        const task = { id, title: rawTitle, isCompleted, notes: null, subtasks: [] };
        tasks.push(task);
        currentTask = task;
        currentSubtask = null;
      }
    } else {
      // It is Content/Notes or Empty Line
      if (titleFound) {
        if (currentSubtask != null && (line.startsWith('    ') || line.trim() === '')) {
          // Subtask Note (4 spaces)
          if (currentSubtask.notes == null) currentSubtask.notes = '';
          currentSubtask.notes = (currentSubtask.notes + '\n' + line.trim()).trim();
        } else if (currentTask != null && (line.startsWith('  ') || line.trim() === '')) {
          // Task Note (2 spaces)
          if (currentTask.notes == null) currentTask.notes = '';
          currentTask.notes = (currentTask.notes + '\n' + line.trim()).trim();
        } else {
          // Project Note
          projectNotesLines.push(line);
        }
      }
    }
  }

  // 3. Construct Project
  const projectId = frontmatter.id?.toString() ?? uuidv4();
  const isCompleted = frontmatter.is_completed === true || frontmatter.isCompleted === true;
  const tags = Array.isArray(frontmatter.tags) ? frontmatter.tags.map(String) : [];
  const projectNotes = projectNotesLines.length > 0 ? projectNotesLines.join('\n').trim() : null;

  return {
    id: projectId,
    title,
    isCompleted,
    tags,
    notes: projectNotes || null,
    tasks: tasks.map(t => ({
      ...t,
      projectId,
    })),
  };
}

/**
 * Serializes a project object back to Markdown with YAML frontmatter.
 * Replicates the exact output format of the Dart toMarkdown() method,
 * including the double-newline quirk from writeln('---\n').
 */
export function toMarkdown(project) {
  const lines = [];

  // 1. Frontmatter
  lines.push('---\n');
  lines.push(`id: ${project.id}\n`);
  if (project.tags && project.tags.length > 0) {
    lines.push(`tags: [${project.tags.join(', ')}]\n`);
  }
  if (project.isCompleted) {
    lines.push('is_completed: true\n');
  }
  lines.push('version: 1\n');
  lines.push('---\n');
  lines.push('');

  // 2. Title
  lines.push(`# ${project.title}\n`);
  lines.push('');

  // 3. Notes
  if (project.notes) {
    lines.push(project.notes);
    lines.push('');
  }

  // 4. Tasks
  for (const task of project.tasks || []) {
    const checkbox = task.isCompleted ? '[x]' : '[ ]';
    lines.push(`- ${checkbox} ${task.title} <!-- id: ${task.id} -->`);

    if (task.notes) {
      const notesLines = task.notes.split('\n');
      for (const noteLine of notesLines) {
        lines.push(`  ${noteLine}`);
      }
    }

    if (task.subtasks && task.subtasks.length > 0) {
      for (const sub of task.subtasks) {
        const subCheckbox = sub.isCompleted ? '[x]' : '[ ]';
        lines.push(`  - ${subCheckbox} ${sub.title} <!-- id: ${sub.id} -->`);

        if (sub.notes) {
          const subNotesLines = sub.notes.split('\n');
          for (const noteLine of subNotesLines) {
            lines.push(`    ${noteLine}`);
          }
        }
      }
    }
    lines.push(''); // Add newline after task block
  }

  return lines.join('\n') + '\n';
}
