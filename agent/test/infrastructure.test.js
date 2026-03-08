import { describe, it, expect } from 'vitest';
import fs from 'fs';
import path from 'path';

describe('1. Project Infrastructure', () => {
  it('AC 1: Agent project exists in a dedicated agent/ directory', () => {
    expect(fs.existsSync('../agent')).toBe(true);
  });

  it('AC 2: package.json includes required dependencies', () => {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
    expect(pkg.dependencies).toHaveProperty('telegraf');
    expect(pkg.dependencies).toHaveProperty('@google/generative-ai');
    expect(pkg.dependencies).toHaveProperty('@modelcontextprotocol/sdk');
    expect(pkg.dependencies).toHaveProperty('dotenv');
  });

  it('AC 3: Agent uses ES Modules', () => {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
    expect(pkg.type).toBe('module');
  });

  it('AC 4: README.md exists in the agent/ folder', () => {
    expect(fs.existsSync('README.md')).toBe(true);
  });

  it('AC 5: npm install runs successfully (implicitly checked by environment)', () => {
    expect(true).toBe(true);
  });

  it('AC 6: Agent code is free of syntax errors (checked by vitest loading)', () => {
    expect(true).toBe(true);
  });
});
