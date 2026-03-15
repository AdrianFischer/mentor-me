const { execSync } = require('child_process');

function runGhCommandRaw(command) {
  try {
    return execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'], maxBuffer: 1024 * 1024 * 50 });
  } catch (error) {
    if (error.stdout) return error.stdout.toString();
    return null;
  }
}

function runGhCommand(command) {
  const output = runGhCommandRaw(command);
  if (!output) return null;
  try {
    return JSON.parse(output);
  } catch (e) {
    return null;
  }
}

function extractFailedTests(logString) {
  if (!logString) return [];
  const lines = logString.split('\n');
  const failedTests = new Set();
  let inSummary = false;

  for (let line of lines) {
    if (line.includes('short test summary info')) {
      inSummary = true;
      continue;
    }
    if (inSummary) {
      if (line.includes('===')) inSummary = false; 
      const match = line.match(/(?:FAILED|ERROR)\s+(.*\.py::[^\s]+)/);
      if (match) {
        let testName = match[1];
        testName = testName.split('[')[0];
        failedTests.add(testName);
      }
    }
  }
  return Array.from(failedTests);
}

async function analyzePr(prNumber) {
  const repo = 'noyes-tech/nys_monorepo';
  console.log('Fetching details for PR #' + prNumber + ' in ' + repo + '...');

  const prInfo = runGhCommand('gh pr view ' + prNumber + ' -R ' + repo + ' --json headRefName,title');
  if (!prInfo) {
    console.log('❌ Could not fetch PR #' + prNumber);
    return;
  }
  const branchName = prInfo.headRefName;

  const prRuns = runGhCommand('gh run list -R ' + repo + ' -b ' + branchName + ' -s failure --limit 1 --json databaseId,createdAt');
  if (!prRuns || prRuns.length === 0) {
    console.log('✅ No recent failed runs found for PR #' + prNumber + ' (branch: ' + branchName + ').');
    return;
  }
  const prRunId = prRuns[0].databaseId;
  console.log('Fetching logs for PR run ' + prRunId + '...');

  const prLogs = runGhCommandRaw('gh run view ' + prRunId + ' -R ' + repo + ' --log-failed');
  const prFailedTests = extractFailedTests(prLogs);

  if (prFailedTests.length === 0) {
    console.log('⚠️ Run ' + prRunId + ' failed, but could not extract specific pytest failures.');
    return;
  }

  console.log('Found ' + prFailedTests.length + ' failing tests on PR. Checking develop branch...');

  const devRuns = runGhCommand('gh run list -R ' + repo + ' -b develop -s failure --limit 10 --json databaseId,createdAt');
  const developFailures = {};

  if (devRuns) {
    for (const run of devRuns) {
      const logs = runGhCommandRaw('gh run view ' + run.databaseId + ' -R ' + repo + ' --log-failed');
      const devFailedTests = extractFailedTests(logs);
      
      for (const test of devFailedTests) {
        if (!developFailures[test] || new Date(run.createdAt) < new Date(developFailures[test])) {
          developFailures[test] = run.createdAt;
        }
      }
    }
  }

  let output = 'I just checked PR #' + prNumber + ' ("' + prInfo.title + '").\n\n**These tests had failures:**\n';
  
  for (const test of prFailedTests) {
    output += '• ' + test + '\n';
    if (developFailures[test]) {
      const date = new Date(developFailures[test]).toISOString().split('T')[0];
      output += '   ⚠️ _Note: This test is also failing on `develop` (since at least ' + date + ')._\n';
    } else {
      output += '   🔴 _This appears to be a new failure introduced in this PR._\n';
    }
  }

  console.log('\n======================================\n');
  console.log(output);
  console.log('======================================\n');
}

const args = process.argv.slice(2);
if (args.length < 1) {
  console.log('Usage: node analyze_pr_tests.js <pr_number>');
  process.exit(1);
}

analyzePr(args[0]);
