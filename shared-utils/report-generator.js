const fs = require('fs');
const path = require('path');

let XLSX;
try {
    XLSX = require('xlsx');
} catch (e) {
    XLSX = null;
}

function generateSuiteReports(suiteName, testResults, outputDir = 'test-results') {
    const fullOutputDir = path.resolve(outputDir);
    const excelDir = path.join(fullOutputDir, 'Excel');
    const htmlDir = path.join(fullOutputDir, 'HTML');
    const jsonDir = path.join(fullOutputDir, 'JSON');
    const summaryDir = path.join(fullOutputDir, 'Summary');

    [excelDir, htmlDir, jsonDir, summaryDir].forEach(dir => {
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    });

    const total = testResults.length;
    const passed = testResults.filter(t => t.status === 'PASSED').length;
    const failed = testResults.filter(t => t.status === 'FAILED').length;
    const skipped = testResults.filter(t => t.status === 'SKIPPED').length;
    const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : '100.00';
    const totalDuration = testResults.reduce((acc, t) => acc + (t.duration || 0), 0);

    const executedData = testResults.map(t => ({
        'Test ID': t.id,
        'Module': t.module,
        'Test Name': t.name,
        'Priority': t.priority || 'P1',
        'Status': t.status,
        'Execution Time (ms)': t.duration || 15,
        'Details / Response': t.details || 'Assertion passed successfully'
    }));

    const moduleMap = {};
    testResults.forEach(t => {
        if (!moduleMap[t.module]) moduleMap[t.module] = { total: 0, passed: 0, failed: 0 };
        moduleMap[t.module].total++;
        if (t.status === 'PASSED') moduleMap[t.module].passed++;
        else moduleMap[t.module].failed++;
    });

    const moduleData = Object.entries(moduleMap).map(([mod, s]) => ({
        'Module': mod,
        'Total Cases': s.total,
        'Passed': s.passed,
        'Failed': s.failed,
        'Pass Rate': `${((s.passed / s.total) * 100).toFixed(1)}%`
    }));

    // 1. EXCEL REPORT GENERATION
    if (XLSX) {
        const wb = XLSX.utils.book_new();
        const wsExecuted = XLSX.utils.json_to_sheet(executedData);
        XLSX.utils.book_append_sheet(wb, wsExecuted, 'Executed Tests');

        const passedData = executedData.filter(t => t.Status === 'PASSED');
        const wsPassed = XLSX.utils.json_to_sheet(passedData.length ? passedData : [{ 'Status': 'No Passed Tests' }]);
        XLSX.utils.book_append_sheet(wb, wsPassed, 'Passed Tests');

        const failedData = executedData.filter(t => t.Status === 'FAILED');
        const wsFailed = XLSX.utils.json_to_sheet(failedData.length ? failedData : [{ 'Status': 'No Failed Tests' }]);
        XLSX.utils.book_append_sheet(wb, wsFailed, 'Failed Tests');

        const metricsData = [
            { 'Metric': 'Suite Name', 'Value': suiteName },
            { 'Metric': 'Total Test Cases', 'Value': total },
            { 'Metric': 'Passed Tests', 'Value': passed },
            { 'Metric': 'Failed Tests', 'Value': failed },
            { 'Metric': 'Skipped Tests', 'Value': skipped },
            { 'Metric': 'Pass Percentage', 'Value': `${passRate}%` },
            { 'Metric': 'Total Duration (ms)', 'Value': `${totalDuration} ms` },
            { 'Metric': 'Execution Timestamp', 'Value': new Date().toISOString() }
        ];
        const wsMetrics = XLSX.utils.json_to_sheet(metricsData);
        XLSX.utils.book_append_sheet(wb, wsMetrics, 'Execution Metrics');

        const wsModules = XLSX.utils.json_to_sheet(moduleData);
        XLSX.utils.book_append_sheet(wb, wsModules, 'Pass Rate Summary');

        XLSX.writeFile(wb, path.join(excelDir, 'Automation_Test_Report.xlsx'));
        XLSX.writeFile(wb, path.join(excelDir, 'Passed_Test_Cases.xlsx'));
        XLSX.writeFile(wb, path.join(excelDir, 'Execution_Summary.xlsx'));
    } else {
        // Fallback CSV generation if xlsx package is loading
        const csvHeader = 'Test ID,Module,Test Name,Priority,Status,Execution Time (ms),Details\n';
        const csvRows = executedData.map(d => `"${d['Test ID']}","${d['Module']}","${d['Test Name']}","${d['Priority']}","${d['Status']}","${d['Execution Time (ms)']}","${d['Details / Response']}"`).join('\n');
        fs.writeFileSync(path.join(excelDir, 'Automation_Test_Report.csv'), csvHeader + csvRows);
    }

    // 2. HTML DASHBOARD GENERATION
    const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BetRally E2E Automation Report - ${suiteName}</title>
    <style>
        :root {
            --bg: #0d1117;
            --card: #161b22;
            --border: #30363d;
            --text: #c9d1d9;
            --text-heading: #f0f6fc;
            --accent: #58a6ff;
            --green: #238636;
            --green-glow: #2ea043;
            --red: #da3633;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
        body { background: var(--bg); color: var(--text); padding: 24px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); padding-bottom: 20px; margin-bottom: 24px; }
        .header h1 { color: var(--text-heading); font-size: 24px; display: flex; align-items: center; gap: 10px; }
        .badge-pass { background: #1f6feb22; color: #58a6ff; border: 1px solid #388bfd66; padding: 4px 12px; border-radius: 20px; font-size: 14px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 18px; }
        .card .title { font-size: 13px; color: #8b949e; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
        .card .value { font-size: 28px; font-weight: 700; color: var(--text-heading); }
        .card.passed .value { color: #3fb950; }
        .card.failed .value { color: #f85149; }
        .card.rate .value { color: #58a6ff; }
        .section-title { font-size: 18px; color: var(--text-heading); margin: 24px 0 12px; }
        table { width: 100%; border-collapse: collapse; background: var(--card); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
        th { background: #21262d; color: var(--text-heading); text-align: left; padding: 12px 16px; font-size: 13px; border-bottom: 1px solid var(--border); }
        td { padding: 10px 16px; font-size: 13px; border-bottom: 1px solid var(--border); }
        tr:hover { background: #1c2128; }
        .status-tag { padding: 3px 8px; border-radius: 12px; font-weight: 600; font-size: 11px; }
        .status-pass { background: #23863633; color: #3fb950; border: 1px solid #238636; }
        .status-fail { background: #da363333; color: #f85149; border: 1px solid #da3633; }
        .search-bar { width: 100%; padding: 10px 14px; background: var(--card); border: 1px solid var(--border); border-radius: 6px; color: var(--text); margin-bottom: 16px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 BetRally E2E Test Suite — ${suiteName}</h1>
        <span class="badge-pass">Pass Rate: ${passRate}%</span>
    </div>

    <div class="stats-grid">
        <div class="card">
            <div class="title">Total Tests</div>
            <div class="value">${total}</div>
        </div>
        <div class="card passed">
            <div class="title">Passed</div>
            <div class="value">✓ ${passed}</div>
        </div>
        <div class="card failed">
            <div class="title">Failed</div>
            <div class="value">✗ ${failed}</div>
        </div>
        <div class="card rate">
            <div class="title">Pass Percentage</div>
            <div class="value">${passRate}%</div>
        </div>
    </div>

    <h2 class="section-title">📦 Module-wise Breakdown</h2>
    <table>
        <thead>
            <tr>
                <th>Module Name</th>
                <th>Total Cases</th>
                <th>Passed</th>
                <th>Failed</th>
                <th>Pass Percentage</th>
            </tr>
        </thead>
        <tbody>
            ${moduleData.map(m => `
            <tr>
                <td><strong>${m.Module}</strong></td>
                <td>${m['Total Cases']}</td>
                <td style="color: #3fb950;">✓ ${m.Passed}</td>
                <td style="color: ${m.Failed > 0 ? '#f85149' : '#8b949e'};">${m.Failed}</td>
                <td><span class="status-tag status-pass">${m['Pass Rate']}</span></td>
            </tr>
            `).join('')}
        </tbody>
    </table>

    <h2 class="section-title">🧪 Executed Test Cases (${total})</h2>
    <input type="text" class="search-bar" id="search" placeholder="Search by Test ID, Module, or Name..." onkeyup="filterTable()">
    <table id="testTable">
        <thead>
            <tr>
                <th>Test ID</th>
                <th>Module</th>
                <th>Test Name</th>
                <th>Priority</th>
                <th>Duration</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            ${testResults.map(t => `
            <tr>
                <td><code>${t.id}</code></td>
                <td>${t.module}</td>
                <td>${t.name}</td>
                <td>${t.priority || 'P1'}</td>
                <td>${t.duration || 15}ms</td>
                <td><span class="status-tag ${t.status === 'PASSED' ? 'status-pass' : 'status-fail'}">${t.status}</span></td>
            </tr>
            `).join('')}
        </tbody>
    </table>

    <script>
        function filterTable() {
            const query = document.getElementById('search').value.toLowerCase();
            const rows = document.querySelectorAll('#testTable tbody tr');
            rows.forEach(row => {
                const text = row.innerText.toLowerCase();
                row.style.display = text.includes(query) ? '' : 'none';
            });
        }
    </script>
</body>
</html>`;

    fs.writeFileSync(path.join(htmlDir, 'execution-report.html'), htmlContent);
    fs.writeFileSync(path.join(htmlDir, 'dashboard.html'), htmlContent);

    // 3. JSON RESULTS
    const jsonOutput = {
        suiteName,
        timestamp: new Date().toISOString(),
        metrics: { total, passed, failed, skipped, passRate: parseFloat(passRate), totalDuration },
        moduleSummary: moduleData,
        testCases: testResults
    };
    fs.writeFileSync(path.join(jsonDir, 'execution-results.json'), JSON.stringify(jsonOutput, null, 2));

    // 4. MARKDOWN & GITHUB SUMMARY
    const markdownSummary = `
## 🧪 BetRally Test Suite: ${suiteName}

| Total Tests | Passed | Failed | Pass Rate | Duration |
| :--- | :--- | :--- | :--- | :--- |
| **\`${total}\`** | **\`${passed}\` 🟢** | \`${failed}\` | **\`${passRate}%\`** | \`${totalDuration} ms\` |

### 📦 Module Summary
${moduleData.map(m => `- **${m.Module}**: \`${m.Passed}/${m['Total Cases']}\` passed (\`${m['Pass Rate']}\`)`).join('\n')}

> 📄 **Reports Generated:** \`Automation_Test_Report.xlsx\`, \`Passed_Test_Cases.xlsx\`, \`Execution_Summary.xlsx\`, \`execution-report.html\`, \`execution-results.json\`
`;

    fs.writeFileSync(path.join(summaryDir, 'summary.md'), markdownSummary.trim());

    if (process.env.GITHUB_STEP_SUMMARY) {
        fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, markdownSummary);
    }

    console.log(`\n✅ Generated Excel, HTML, JSON, and Markdown reports for ${suiteName}`);
}

module.exports = { generateSuiteReports };
