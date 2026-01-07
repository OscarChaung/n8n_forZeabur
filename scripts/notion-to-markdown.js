/**
 * n8n Code Node: Notion Page to Markdown
 * 
 * Inputs:
 *   - $('content').first().json.page_id -> Notion Page ID
 *   - $('content').first().json.token   -> Notion integration token (secret_...)
 * 
 * Requires: @notionhq/client (已在 Docker 映像安裝並允許 external)
 */

const { Client } = require('@notionhq/client');

function txt(rich) {
  if (!rich || !Array.isArray(rich)) return '';
  return rich.map(t => {
    let s = t.plain_text || '';
    const a = t.annotations || {};
    if (a.bold) s = `**${s}**`;
    if (a.italic) s = `*${s}*`;
    if (a.strikethrough) s = `~~${s}~~`;
    if (a.underline) s = `<u>${s}</u>`;
    if (a.code) s = `\`${s}\``;
    if (t.href) s = `[${s}](${t.href})`;
    return s;
  }).join('');
}

function indent(level) { return '  '.repeat(level); }

async function fetchChildren(notion, blockId) {
  const out = [];
  let cursor;
  do {
    const res = await notion.blocks.children.list({ block_id: blockId, start_cursor: cursor, page_size: 100 });
    out.push(...res.results);
    cursor = res.has_more ? res.next_cursor : undefined;
  } while (cursor);
  return out;
}

async function blocksToMd(notion, blocks, level = 0) {
  const lines = [];
  for (const b of blocks) {
    const { type } = b;
    const v = b[type];

    if (type === 'heading_1') lines.push(`# ${txt(v.rich_text)}`);
    else if (type === 'heading_2') lines.push(`## ${txt(v.rich_text)}`);
    else if (type === 'heading_3') lines.push(`### ${txt(v.rich_text)}`);
    else if (type === 'paragraph') {
      const content = txt(v.rich_text);
      lines.push(content.trim().length ? content : '');
    }
    else if (type === 'bulleted_list_item' || type === 'numbered_list_item') {
      const marker = type === 'bulleted_list_item' ? '-' : '1.';
      lines.push(`${indent(level)}${marker} ${txt(v.rich_text)}`);
      if (b.has_children) {
        const children = await fetchChildren(notion, b.id);
        lines.push(...await blocksToMd(notion, children, level + 1));
      }
      continue;
    }
    else if (type === 'to_do') {
      const check = v.checked ? 'x' : ' ';
      lines.push(`- [${check}] ${txt(v.rich_text)}`);
      if (b.has_children) {
        const children = await fetchChildren(notion, b.id);
        lines.push(...await blocksToMd(notion, children, level + 1));
      }
      continue;
    }
    else if (type === 'quote') {
      lines.push(txt(v.rich_text).split('\n').map(l => `> ${l}`).join('\n'));
    }
    else if (type === 'code') {
      const lang = v.language || '';
      lines.push('```' + lang);
      lines.push((v.rich_text || []).map(t => t.plain_text || '').join(''));
      lines.push('```');
    }
    else if (type === 'divider') lines.push('---');
    else if (type === 'callout') {
      const icon = v.icon?.emoji || '💡';
      lines.push(`> ${icon} ${txt(v.rich_text)}`);
    }
    else if (type === 'toggle') {
      const summary = txt(v.rich_text) || 'Details';
      lines.push(`<details><summary>${summary}</summary>`);
      if (b.has_children) {
        const children = await fetchChildren(notion, b.id);
        const md = await blocksToMd(notion, children, level);
        lines.push(md.join('\n'));
      }
      lines.push(`</details>`);
    }
    else if (type === 'link_to_page') {
      const t = v.type;
      const ref = v[t]?.id || '';
      lines.push(`[Link to ${t}](${ref})`);
    }
    else if (type === 'bookmark') {
      if (v.url) lines.push(`<${v.url}>`);
    }
    else if (type === 'image' || type === 'file') {
      const url = v?.[v.type]?.url || v?.external?.url || '';
      if (url) lines.push(type === 'image' ? `![](${url})` : `[file](${url})`);
    }
    else if (type === 'table') {
      const rows = await fetchChildren(notion, b.id);
      const mdRows = [];
      for (const r of rows) {
        if (r.type !== 'table_row') continue;
        const cells = r.table_row.cells || [];
        const vals = cells.map(cell => txt(cell));
        mdRows.push(`| ${vals.join(' | ')} |`);
      }
      if (mdRows.length) {
        const cols = (rows[0]?.table_row?.cells || []).length;
        const sep = `| ${Array(cols).fill('---').join(' | ')} |`;
        if (mdRows.length >= 1) mdRows.splice(1, 0, sep);
        lines.push(...mdRows);
      }
    } else {
      const plain = v?.rich_text ? txt(v.rich_text) : '';
      if (plain) lines.push(plain);
    }

    if (b.has_children && !['bulleted_list_item', 'numbered_list_item', 'to_do', 'toggle', 'table'].includes(type)) {
      const children = await fetchChildren(notion, b.id);
      lines.push(...await blocksToMd(notion, children, level));
    }
    if (!['numbered_list_item', 'bulleted_list_item', 'to_do'].includes(type)) lines.push('');
  }
  return lines;
}

try {
  const pageId = ($('content').first().json.page_id || '').trim();
  const token = ($('content').first().json.token || '').trim();
  if (!pageId) throw new Error('缺少 pageId（items[0].json.id）');
  if (!token) throw new Error('缺少 token（items[0].json.token）');

  const notion = new Client({ auth: token });
  const rootBlocks = await fetchChildren(notion, pageId);
  const mdLines = await blocksToMd(notion, rootBlocks, 0);
  const md = mdLines.join('\n').replace(/\n{3,}/g, '\n\n');

  // 可選：附上檔名資訊（仍回傳字串）
  let title = null;
  try {
    const page = await notion.pages.retrieve({ page_id: pageId });
    const titleProp = Object.values(page.properties || {}).find(p => p.type === 'title');
    title = titleProp?.title?.map(t => t.plain_text).join('') || null;
  } catch {}

  return [{
    json: {
      ok: true,
      pageId,
      title,
      md,          // << 你的 Markdown 字串在這裡
      length: md.length
    }
  }];

} catch (e) {
  return [{ json: { ok: false, error: String(e) } }];
}
