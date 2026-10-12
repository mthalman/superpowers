(function (global) {
  'use strict';

  function parseJsonl(text) {
    if (!text) return [];
    if (text.charCodeAt(0) === 0xFEFF) text = text.slice(1);
    const rows = [];
    for (const line of text.split(/\r?\n/)) {
      if (!line.trim()) continue;
      try {
        rows.push(JSON.parse(line));
      } catch (error) {
        console.warn('Skipping unparseable JSONL line:', error.message);
      }
    }
    return rows;
  }

  function passRate(row) {
    const value = row && row.status === 'ok' && row.metrics
      ? row.metrics.pass_rate
      : null;
    return typeof value === 'number' ? value : null;
  }

  function computeBiggestDrop(rows, windowSize) {
    const okRows = (rows || []).filter(function (row) {
      return passRate(row) !== null;
    });
    if (okRows.length < 2) return null;
    const transitions = [];
    for (let i = 1; i < okRows.length; i++) {
      const current = okRows[i];
      transitions.push({
        from: passRate(okRows[i - 1]),
        to: passRate(current),
        delta: Math.round((passRate(current) - passRate(okRows[i - 1])) * 10000) / 10000,
        commit: current.commit,
        short_sha: current.short_sha,
        timestamp: current.timestamp,
      });
    }
    const recent = transitions.slice(-Math.max(1, windowSize || 10));
    return recent.filter(function (item) { return item.delta < 0; })
      .sort(function (a, b) { return a.delta - b.delta; })[0] || null;
  }

  function buildCommitUrl(repository, sha) {
    return repository && sha
      ? 'https://github.com/' + repository + '/commit/' + sha
      : null;
  }

  function buildRunUrl(repository, runId) {
    return repository && /^\d+$/.test(String(runId || ''))
      ? 'https://github.com/' + repository + '/actions/runs/' + runId
      : null;
  }

  function validateSkillName(name, allowlist) {
    if (!name || typeof name !== 'string' || !/^[A-Za-z0-9_-]+$/.test(name)) {
      return false;
    }
    return !Array.isArray(allowlist) || allowlist.length === 0 || allowlist.includes(name);
  }

  function formatPercent(value) {
    return typeof value === 'number' ? (value * 100).toFixed(1) + '%' : '—';
  }

  function formatDelta(value) {
    if (typeof value !== 'number') return '';
    if (value === 0) return '=';
    return (value > 0 ? '▲ +' : '▼ ') + (value * 100).toFixed(1) + ' pp';
  }

  function deltaClass(value) {
    if (value > 0) return 'delta-up';
    if (value < 0) return 'delta-down';
    return 'delta-flat';
  }

  function statusClass(value) {
    if (value === 'improvement') return 'status-clean';
    return value === 'clean' || value === 'inconclusive' || value === 'regression'
      ? 'status-' + value
      : '';
  }

  function relativeTime(iso) {
    const parsed = Date.parse(iso);
    if (!iso || Number.isNaN(parsed)) return '';
    const seconds = Math.round((Date.now() - parsed) / 1000);
    if (seconds < 60) return seconds + 's ago';
    const minutes = Math.round(seconds / 60);
    if (minutes < 60) return minutes + 'm ago';
    const hours = Math.round(minutes / 60);
    if (hours < 48) return hours + 'h ago';
    const days = Math.round(hours / 24);
    return days < 30 ? days + 'd ago' : Math.round(days / 30) + 'mo ago';
  }

  function buildSparklinePath(values, width, height) {
    if (!Array.isArray(values) || !values.some(function (value) {
      return typeof value === 'number';
    })) return null;
    const numeric = values.filter(function (value) { return typeof value === 'number'; });
    const min = Math.min.apply(null, numeric);
    const max = Math.max.apply(null, numeric);
    const range = max - min || 1;
    const w = width || 200;
    const h = height || 36;
    let path = '';
    let active = false;
    let lastPoint = null;
    values.forEach(function (value, index) {
      if (typeof value !== 'number') {
        active = false;
        return;
      }
      const x = values.length === 1 ? w : index / (values.length - 1) * w;
      const y = h - 2 - (value - min) / range * (h - 4);
      path += (active ? ' L' : 'M') + x.toFixed(2) + ',' + y.toFixed(2);
      active = true;
      lastPoint = { x: x, y: y };
    });
    return { path: path, lastPoint: lastPoint };
  }

  function el(tag, attrs, text) {
    const node = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (key) {
      if (attrs[key] !== null && attrs[key] !== undefined) {
        node.setAttribute(key === 'class' ? 'class' : key, attrs[key]);
      }
    });
    if (text !== undefined) node.textContent = String(text);
    return node;
  }

  function fetchJson(url) {
    return fetch(url, { cache: 'no-cache' }).then(function (response) {
      if (!response.ok) throw new Error('HTTP ' + response.status + ' fetching ' + url);
      return response.json();
    });
  }

  function fetchText(url) {
    return fetch(url, { cache: 'no-cache' }).then(function (response) {
      if (!response.ok) throw new Error('HTTP ' + response.status + ' fetching ' + url);
      return response.text();
    });
  }

  function showError(message) {
    const panel = document.getElementById('error-panel');
    panel.hidden = false;
    panel.textContent = message;
  }

  function renderSparkline(skill) {
    const data = buildSparklinePath((skill.sparkline || []).map(function (point) {
      return point.pass_rate;
    }), 200, 36);
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 200 36');
    svg.setAttribute('class', 'sparkline');
    if (!data) return svg;
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', data.path);
    path.setAttribute('class', 'line');
    svg.appendChild(path);
    if (data.lastPoint) {
      const dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      dot.setAttribute('cx', data.lastPoint.x.toFixed(2));
      dot.setAttribute('cy', data.lastPoint.y.toFixed(2));
      dot.setAttribute('r', '2.5');
      dot.setAttribute('class', 'last');
      svg.appendChild(dot);
    }
    return svg;
  }

  function renderCard(skill) {
    const latest = skill.latest || {};
    const delta = latest.delta_from_previous;
    const card = el('a', {
      class: 'card' + (typeof delta === 'number' && delta <= -0.1 ? ' regression' : ''),
      href: 'skill.html?name=' + encodeURIComponent(skill.name),
    });
    card.appendChild(el('h2', null, skill.name));
    const score = el('div', { class: 'score-line' });
    score.appendChild(el('span', { class: 'score' }, formatPercent(passRate(latest))));
    score.appendChild(el('span', { class: deltaClass(delta) }, formatDelta(delta)));
    card.appendChild(score);
    const submetrics = el('div', { class: 'submetrics' });
    submetrics.appendChild(el('span', null, 'mean ' + formatPercent(latest.metrics && latest.metrics.mean_score)));
    submetrics.appendChild(el('span', null, 'pass@k ' + formatPercent(latest.metrics && latest.metrics.pass_at_k)));
    if (latest.metrics && typeof latest.metrics.uplift === 'number') {
      submetrics.appendChild(el('span', null, 'uplift ' + formatDelta(latest.metrics.uplift)));
    }
    card.appendChild(submetrics);
    card.appendChild(renderSparkline(skill));
    const meta = el('div', { class: 'meta' });
    meta.appendChild(el('span', null, relativeTime(latest.timestamp) || 'never'));
    meta.appendChild(el('code', null, latest.short_sha || ''));
    card.appendChild(meta);
    return card;
  }

  function initLanding() {
    fetchJson('data/manifest.json').then(function (manifest) {
      document.getElementById('generated-at').textContent =
        manifest.generated_at ? 'Updated ' + relativeTime(manifest.generated_at) : '';
      const skills = manifest.skills || [];
      if (!skills.length) {
        document.getElementById('empty-state').hidden = false;
        return;
      }
      if (manifest.worst_recent_drop) {
        const drop = manifest.worst_recent_drop;
        const callout = document.getElementById('callout');
        callout.hidden = false;
        callout.textContent = drop.skill + ' had the largest recent pass-rate drop: ' +
          formatDelta(drop.delta);
      }
      skills.slice().sort(function (a, b) {
        return a.name.localeCompare(b.name);
      }).forEach(function (skill) {
        document.getElementById('grid').appendChild(renderCard(skill));
      });
      if (manifest.nightly_index) {
        fetchJson(manifest.nightly_index).then(function (index) {
          if (!index.runs || !index.runs.length) return;
          const latest = index.runs[0];
          const section = document.getElementById('latest-nightly');
          section.hidden = false;
          const detail = document.getElementById('latest-nightly-detail');
          detail.textContent = '';
          detail.appendChild(el('span', { class: statusClass(latest.status) }, latest.status));
          detail.appendChild(document.createTextNode(
            ' · ' + relativeTime(latest.timestamp) +
            ' · ' + latest.short_sha +
            ' · ' + latest.flaky_count + ' flaky'
          ));
        }).catch(function (error) {
          console.warn('Could not load nightly index:', error.message);
        });
      }
    }).catch(function (error) {
      showError('Could not load dashboard data: ' + error.message);
    });
  }

  function metricCard(label, value) {
    const card = el('dl');
    card.appendChild(el('dt', null, label));
    card.appendChild(el('dd', null, value));
    return card;
  }

  function renderLatest(detail) {
    const container = document.getElementById('latest-detail');
    container.textContent = '';
    const metrics = detail.metrics || {};
    const grid = el('div', { class: 'metrics-grid' });
    grid.appendChild(metricCard('Pass rate', formatPercent(metrics.pass_rate)));
    grid.appendChild(metricCard('Mean score', formatPercent(metrics.mean_score)));
    grid.appendChild(metricCard('pass@k', formatPercent(metrics.pass_at_k)));
    grid.appendChild(metricCard('pass^k', formatPercent(metrics.pass_to_k)));
    grid.appendChild(metricCard('Flaky stimuli', metrics.flaky_count || 0));
    grid.appendChild(metricCard('Tokens', metrics.tokens || 0));
    grid.appendChild(metricCard('Tool calls', metrics.tool_calls || 0));
    grid.appendChild(metricCard('Wall time', Math.round((metrics.wall_time_ms || 0) / 1000) + 's'));
    container.appendChild(grid);

    const table = el('table');
    const head = el('tr');
    ['Stimulus', 'Score', 'pass@k', 'Flaky'].forEach(function (label) {
      head.appendChild(el('th', null, label));
    });
    const thead = el('thead');
    thead.appendChild(head);
    table.appendChild(thead);
    const body = el('tbody');
    (detail.stimuli || []).forEach(function (stimulus) {
      const row = el('tr');
      row.appendChild(el('td', null, stimulus.name));
      row.appendChild(el('td', null, formatPercent(stimulus.score && stimulus.score.aggregateScore)));
      row.appendChild(el('td', null, formatPercent(stimulus.score && stimulus.score.multiTrial.passAtK)));
      row.appendChild(el('td', null, stimulus.score && stimulus.score.flaky ? 'yes' : 'no'));
      body.appendChild(row);
    });
    table.appendChild(body);
    container.appendChild(table);
  }

  function renderChart(rows, repository) {
    if (typeof Chart === 'undefined') return;
    const validRows = rows.filter(function (row) { return passRate(row) !== null; });
    const labels = validRows.map(function (row) { return row.short_sha; });
    const nightlyData = validRows.map(function (row) {
      return row.run_kind === 'nightly' ? passRate(row) * 100 : null;
    });
    const mainData = validRows.map(function (row) {
      return row.run_kind === 'main' ? passRate(row) * 100 : null;
    });
    new Chart(document.getElementById('history-chart').getContext('2d'), {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Canonical nightly',
            data: nightlyData,
            borderColor: '#1f6feb',
            pointBackgroundColor: '#1f6feb',
            pointRadius: 4,
            pointStyle: 'circle',
            spanGaps: true,
          },
          {
            label: 'Changed-skill main',
            data: mainData,
            borderColor: '#8c959f',
            pointBackgroundColor: '#8c959f',
            borderDash: [5, 4],
            pointRadius: 4,
            pointStyle: 'rectRot',
            spanGaps: true,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { beginAtZero: true, max: 100, title: { display: true, text: 'Pass rate (%)' } },
        },
        plugins: { legend: { display: true } },
        onClick: function (_event, elements) {
          if (!elements.length) return;
          const url = buildCommitUrl(repository, validRows[elements[0].index].commit);
          if (url) window.open(url, '_blank', 'noopener');
        },
      },
    });
  }

  function renderHistory(rows, manifest, skill) {
    const body = document.querySelector('#history-table tbody');
    rows.slice().reverse().forEach(function (row) {
      const tr = el('tr', { class: row.status === 'error' ? 'error' : '' });
      tr.appendChild(el('td', null, relativeTime(row.timestamp)));
      const commit = el('td');
      const commitUrl = buildCommitUrl(manifest.repository, row.commit);
      const commitText = el('code', null, row.short_sha || '');
      if (commitUrl) {
        const link = el('a', { href: commitUrl, target: '_blank', rel: 'noopener' });
        link.appendChild(commitText);
        commit.appendChild(link);
      } else {
        commit.appendChild(commitText);
      }
      tr.appendChild(commit);
      tr.appendChild(el('td', null, formatPercent(passRate(row))));
      tr.appendChild(el('td', null, formatPercent(row.metrics && row.metrics.mean_score)));
      tr.appendChild(el('td', null, row.run_kind || 'legacy'));
      tr.appendChild(el('td', null, row.status || ''));
      const runCell = el('td');
      const runUrl = row.workflow_run_url || buildRunUrl(manifest.repository, row.run_id);
      if (runUrl) runCell.appendChild(el('a', { href: runUrl, target: '_blank', rel: 'noopener' }, 'artifact'));
      tr.appendChild(runCell);
      tr.appendChild(el('td', null, /^\d+$/.test(String(row.run_id || ''))
        ? '.\\scripts\\Start-EvalDashboard.ps1 -RunId ' + row.run_id
        : 'summary published from local run'));
      body.appendChild(tr);
    });
    document.getElementById('local-command').textContent =
      rows.length && /^\d+$/.test(String(rows[rows.length - 1].run_id || ''))
      ? '.\\scripts\\Start-EvalDashboard.ps1 -RunId ' + rows[rows.length - 1].run_id
      : 'Full trajectories for locally published runs remain on the machine that ran the evaluation.';
  }

  function comparisonText(comparison) {
    if (!comparison) return '—';
    return comparison.mean_score.toFixed(3) + ' (' +
      comparison.ci_low.toFixed(3) + ' to ' +
      comparison.ci_high.toFixed(3) + ')';
  }

  function renderUpliftChart(rows) {
    if (typeof Chart === 'undefined') return;
    new Chart(document.getElementById('uplift-chart').getContext('2d'), {
      type: 'line',
      data: {
        labels: rows.map(function (row) { return row.run_id; }),
        datasets: [{
          label: 'Mean signed uplift',
          data: rows.map(function (row) { return row.overall.mean_score; }),
          borderColor: '#8250df',
          pointBackgroundColor: rows.map(function (row) {
            return row.overall.verdict === 'regression' ? '#cf222e' :
              row.overall.verdict === 'improvement' ? '#1a7f37' : '#9a6700';
          }),
          pointRadius: 4,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { min: -1, max: 1, title: { display: true, text: 'Mean signed score' } },
        },
      },
    });
  }

  function renderLatestUplift(row) {
    const container = document.getElementById('uplift-latest');
    container.textContent = '';
    container.appendChild(el('h3', null, 'Latest uplift'));
    container.appendChild(el('p', { class: statusClass(row.overall.verdict) },
      comparisonText(row.overall) + ' · ' + row.overall.verdict));
    const table = el('table');
    const head = el('tr');
    ['Skill', 'Mean and 95% CI', 'Verdict', 'Model'].forEach(function (label) {
      head.appendChild(el('th', null, label));
    });
    const thead = el('thead');
    thead.appendChild(head);
    table.appendChild(thead);
    const body = el('tbody');
    (row.skills || []).forEach(function (skill) {
      const tr = el('tr');
      tr.appendChild(el('td', null, skill.skill));
      tr.appendChild(el('td', null, comparisonText(skill)));
      tr.appendChild(el('td', { class: statusClass(skill.verdict) }, skill.verdict));
      tr.appendChild(el('td', null,
        (skill.baseline_model || 'default') + ' → ' +
        (skill.treatment_model || 'default')));
      body.appendChild(tr);
    });
    table.appendChild(body);
    container.appendChild(table);
  }

  function renderNightlyRows(index) {
    const body = document.querySelector('#nightly-table tbody');
    return Promise.all((index.runs || []).map(function (run) {
      return fetchJson(run.summary_file);
    })).then(function (summaries) {
      summaries.forEach(function (summary, summaryIndex) {
        const run = index.runs[summaryIndex];
        const tr = el('tr');
        tr.appendChild(el('td', null, relativeTime(run.timestamp)));
        tr.appendChild(el('td', { class: statusClass(run.status) }, run.status));
        const commit = el('td');
        const link = el('a', {
          href: buildCommitUrl(index.repository, run.commit),
          target: '_blank',
          rel: 'noopener',
        }, run.short_sha);
        commit.appendChild(link);
        tr.appendChild(commit);
        tr.appendChild(el('td', null, run.flaky_count));
        const details = el('td');
        summary.skills.forEach(function (skill, skillIndex) {
          if (skillIndex) details.appendChild(document.createTextNode(' · '));
          details.appendChild(el('a', { href: skill.detail_file }, skill.skill));
        });
        tr.appendChild(details);
        const uplift = el('td');
        uplift.appendChild(el('a', { href: summary.uplift.comparison_file }, 'comparison JSONL'));
        tr.appendChild(uplift);
        body.appendChild(tr);
      });
    });
  }

  function initNightlyPage() {
    Promise.all([
      fetchJson('data/manifest.json'),
      fetchJson('data/nightly-runs/index.json'),
      fetchText('data/uplift/history.jsonl'),
    ]).then(function (results) {
      const manifest = results[0];
      const index = results[1];
      index.repository = manifest.repository;
      const upliftRows = parseJsonl(results[2]);
      if (!index.runs.length || !upliftRows.length) {
        throw new Error('No canonical nightly runs have been published.');
      }
      renderUpliftChart(upliftRows);
      renderLatestUplift(upliftRows[upliftRows.length - 1]);
      return renderNightlyRows(index);
    }).catch(function (error) {
      showError(error.message);
    });
  }

  function initSkillPage() {
    const requested = new URLSearchParams(window.location.search).get('name');
    fetchJson('data/manifest.json').then(function (manifest) {
      const allowlist = (manifest.skills || []).map(function (skill) { return skill.name; });
      if (!validateSkillName(requested, allowlist)) throw new Error('Unknown skill: ' + requested);
      document.getElementById('skill-name').textContent = requested;
      document.getElementById('raw-history').href =
        'data/' + encodeURIComponent(requested) + '/history.jsonl';
      return fetchText('data/' + encodeURIComponent(requested) + '/history.jsonl')
        .then(function (text) {
          const rows = parseJsonl(text);
          if (!rows.length) throw new Error('No history has been published.');
          renderChart(rows, manifest.repository);
          renderHistory(rows, manifest, requested);
          const latest = rows.slice().reverse().find(function (row) {
            return row.status === 'ok' && row.detail_file;
          });
          if (!latest) return;
          const url = 'data/' + encodeURIComponent(requested) + '/' + latest.detail_file;
          document.getElementById('raw-run').href = url;
          return fetchJson(url).then(renderLatest);
        });
    }).catch(function (error) {
      showError(error.message);
    });
  }

  global.SuperpowersDashboard = {
    parseJsonl: parseJsonl,
    passRate: passRate,
    computeBiggestDrop: computeBiggestDrop,
    buildCommitUrl: buildCommitUrl,
    buildRunUrl: buildRunUrl,
    validateSkillName: validateSkillName,
    formatPercent: formatPercent,
    formatDelta: formatDelta,
    deltaClass: deltaClass,
    statusClass: statusClass,
    relativeTime: relativeTime,
    buildSparklinePath: buildSparklinePath,
    initLanding: initLanding,
    initSkillPage: initSkillPage,
    initNightlyPage: initNightlyPage,
  };
})(typeof window !== 'undefined' ? window : globalThis);
