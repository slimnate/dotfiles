function defaultConfig() {
  return {
    defaultEditor: 'cursor',
    showStatus: true,
    showActivity: true,
    showTags: true,
    baseDirs: ['~/Documents/dev'],
    projects: [
      { label: 'Custom Dotfiles', path: '~/.dotfiles' },
      { label: 'Omarchy Config', path: '/usr/share/omarchy' },
      { label: 'OpenClaw Config', path: '~/.openclaw' }
    ],
    editors: [
      {
        id: 'cursor',
        name: 'Cursor',
        command: ['/usr/bin/cursor', '-n', '--classic'],
        class: 'cursor',
        kind: 'gui'
      },
      {
        id: 'nvim',
        name: 'Neovim',
        command: ['nvim'],
        kind: 'tui'
      }
    ]
  }
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function cloneConfig(config) {
  try {
    return JSON.parse(JSON.stringify(isPlainObject(config) ? config : defaultConfig()))
  } catch (e) {
    return defaultConfig()
  }
}

function serializeConfig(config) {
  var parsed = cloneConfig(config)
  var payload = {
    defaultEditor: String(parsed.defaultEditor || 'cursor'),
    showStatus: parsed.showStatus !== false,
    showActivity: parsed.showActivity !== false,
    showTags: parsed.showTags !== false,
    baseDirs: [],
    projects: [],
    editors: Array.isArray(parsed.editors) ? parsed.editors : defaultConfig().editors
  }

  var dirs = Array.isArray(parsed.baseDirs) ? parsed.baseDirs : []
  for (var i = 0; i < dirs.length; i++) {
    var dir = String(dirs[i] || '').trim()
    if (dir) payload.baseDirs.push(dir)
  }

  var projects = Array.isArray(parsed.projects) ? parsed.projects : []
  for (var j = 0; j < projects.length; j++) {
    var row = projects[j]
    if (!isPlainObject(row)) continue
    var path = String(row.path || '').trim()
    if (!path) continue
    var entry = { path: path }
    var label = String(row.label || '').trim()
    if (label) entry.label = label
    var editor = String(row.editor || '').trim()
    if (editor) entry.editor = editor
    payload.projects.push(entry)
  }

  return JSON.stringify(payload, null, 2) + '\n'
}

function parseConfig(raw) {
  var defaults = defaultConfig()
  var parsed
  try {
    parsed = JSON.parse(String(raw || '{}'))
  } catch (e) {
    return defaults
  }
  if (!isPlainObject(parsed)) return defaults

  var config = {
    defaultEditor: defaults.defaultEditor,
    showStatus: defaults.showStatus,
    showActivity: defaults.showActivity,
    showTags: defaults.showTags,
    baseDirs: defaults.baseDirs,
    projects: defaults.projects,
    editors: defaults.editors
  }
  if (typeof parsed.defaultEditor === 'string' && parsed.defaultEditor)
    config.defaultEditor = parsed.defaultEditor
  if (parsed.showStatus !== undefined) config.showStatus = parsed.showStatus !== false
  if (parsed.showActivity !== undefined) config.showActivity = parsed.showActivity !== false
  if (parsed.showTags !== undefined) config.showTags = parsed.showTags !== false
  if (Array.isArray(parsed.baseDirs)) config.baseDirs = parsed.baseDirs
  if (Array.isArray(parsed.projects)) config.projects = parsed.projects
  if (Array.isArray(parsed.editors) && parsed.editors.length > 0)
    config.editors = parsed.editors
  return config
}

function parseProjects(raw) {
  var parsed
  try {
    parsed = JSON.parse(String(raw || '[]'))
  } catch (e) {
    return []
  }
  if (!Array.isArray(parsed)) return []

  var out = []
  for (var i = 0; i < parsed.length; i++) {
    var row = parsed[i]
    if (!isPlainObject(row) || !row.path) continue
    out.push({
      ts: Number(row.ts) || 0,
      name: String(row.name || ''),
      path: String(row.path || ''),
      branch: String(row.branch || '-'),
      dirty: Number(row.dirty) || 0,
      ahead: Number(row.ahead) || 0,
      behind: Number(row.behind) || 0,
      activity: String(row.activity || ''),
      tags: String(row.tags || ''),
      editor: String(row.editor || '')
    })
  }
  return out
}

function filterProjects(projects, filterText) {
  var list = Array.isArray(projects) ? projects : []
  var query = String(filterText || '').trim().toLowerCase()
  if (!query) return list

  var out = []
  for (var i = 0; i < list.length; i++) {
    var row = list[i]
    var hay = [row.name, row.path, row.branch, row.tags, row.activity].join(' ').toLowerCase()
    if (hay.indexOf(query) !== -1) out.push(row)
  }
  return out
}

function splitTags(tags) {
  var text = String(tags || '').trim()
  if (!text) return []
  return text.split(/\s+/).filter(function(tag) { return tag.length > 0 })
}

function editorBinary(editor) {
  if (!isPlainObject(editor)) return ''
  if (String(editor.id || '') === 'omarchy') return 'omarchy-launch-editor'
  if (Array.isArray(editor.command) && editor.command.length > 0)
    return String(editor.command[0] || '')
  return String(editor.id || '')
}

function normalizeEditor(editor) {
  if (!isPlainObject(editor)) return null
  var id = String(editor.id || '')
  if (!id) return null
  var command = []
  if (Array.isArray(editor.command)) {
    for (var i = 0; i < editor.command.length; i++)
      command.push(String(editor.command[i]))
  }
  if (command.length === 0 && id !== 'omarchy') command = [id]
  var kind = String(editor.kind || '')
  if (kind !== 'tui' && kind !== 'omarchy') kind = 'gui'
  if (id === 'omarchy') kind = 'omarchy'
  return {
    id: id,
    name: String(editor.name || id),
    command: command,
    class: String(editor.class || ''),
    kind: kind
  }
}

function visibleEditors(editors, availableIds, defaultEditor) {
  var list = Array.isArray(editors) ? editors : []
  var available = {}
  if (Array.isArray(availableIds)) {
    for (var i = 0; i < availableIds.length; i++)
      available[String(availableIds[i])] = true
  }

  var wanted = String(defaultEditor || '')
  var out = []
  var fallback = []
  for (var j = 0; j < list.length; j++) {
    var editor = normalizeEditor(list[j])
    if (!editor) continue
    if (availableIds && availableIds.length > 0 && !available[editor.id]) continue
    if (editor.id === wanted) out.push(editor)
    else fallback.push(editor)
  }
  return out.concat(fallback)
}

function resolveEditor(editors, editorId, defaultEditor, projectEditor) {
  var list = visibleEditors(editors, null, defaultEditor)
  var wanted = String(projectEditor || editorId || defaultEditor || '')
  var i
  if (wanted) {
    for (i = 0; i < list.length; i++) {
      if (list[i].id === wanted) return list[i]
    }
  }
  return list.length > 0 ? list[0] : null
}

function listMeta(row, showStatus, showActivity) {
  if (!row) return ''
  var parts = []
  if (showStatus !== false) {
    var branch = row.branch && row.branch !== '-' ? row.branch : ''
    if (branch) parts.push(branch)
    var dirty = Number(row.dirty) || 0
    if (dirty > 0) parts.push(dirty + ' dirty')
    else if (branch) parts.push('clean')
  }
  if (showActivity !== false && row.activity && row.activity !== '-')
    parts.push(row.activity)
  return parts.join(' · ')
}

function gitSummary(row) {
  if (!row) return ''
  if (!row.branch || row.branch === '-') return 'Not a git repository'
  var parts = [row.branch]
  var dirty = Number(row.dirty) || 0
  parts.push(dirty > 0 ? dirty + ' dirty' : 'clean')
  var ahead = Number(row.ahead) || 0
  var behind = Number(row.behind) || 0
  if (ahead > 0) parts.push(ahead + ' ahead')
  if (behind > 0) parts.push(behind + ' behind')
  if (ahead === 0 && behind === 0) parts.push('up to date')
  return parts.join(' · ')
}

function parseListing(raw) {
  var parsed
  try {
    parsed = JSON.parse(String(raw || '[]'))
  } catch (e) {
    return []
  }
  if (!Array.isArray(parsed)) return []

  var out = []
  for (var i = 0; i < parsed.length; i++) {
    var row = parsed[i]
    if (!row || typeof row !== 'object' || !row.name) continue
    out.push({
      name: String(row.name || ''),
      dir: row.dir === true,
      link: row.link === true,
      hidden: row.hidden === true
    })
  }
  return out
}

function parseTomlColor(raw, key, fallback) {
  var pattern = new RegExp('^\\s*' + key + '\\s*=\\s*["\']?(#[0-9A-Fa-f]{6})', 'm')
  var match = String(raw || '').match(pattern)
  return match ? match[1] : fallback
}

function shortenHome(path, home) {
  var value = String(path || '')
  var prefix = String(home || '')
  if (prefix && value.indexOf(prefix) === 0)
    return '~' + value.slice(prefix.length)
  return value
}
