#!/usr/bin/env bash
set -euo pipefail

JIRA_BASE_URL="${JIRA_URL:-}"
JIRA_EMAIL="${JIRA_EMAIL:-}"
JIRA_API_TOKEN="${JIRA_API_TOKEN:-}"

[[ -z "$JIRA_BASE_URL" ]] && read -rp "Jira base URL: " JIRA_BASE_URL
[[ -z "$JIRA_EMAIL" ]] && read -rp "Jira email: " JIRA_EMAIL
[[ -z "$JIRA_API_TOKEN" ]] && { read -rsp "Jira API token: " JIRA_API_TOKEN; echo; }

ISSUE_KEY="${1:?Usage: jira-md.sh <ISSUE-KEY>}"

curl -sf \
  -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  -H "Accept: application/json" \
  "${JIRA_BASE_URL}/rest/api/3/issue/${ISSUE_KEY}?fields=description" \
  | python3 -c "
import json, sys

def md(node, depth=0):
    if node is None: return ''
    t = node.get('type','')
    c = node.get('content',[])
    a = node.get('attrs',{})

    if t == 'doc':          return '\n'.join(md(n) for n in c).strip()
    if t == 'hardBreak':    return '\n'
    if t == 'rule':         return '---\n'
    if t == 'text':
        s = node.get('text','')
        for m in node.get('marks',[]):
            mt = m['type']
            if mt == 'strong':  s = f'**{s}**'
            elif mt == 'em':    s = f'*{s}*'
            elif mt == 'code':  s = f'\`{s}\`'
            elif mt == 'strike': s = f'~~{s}~~'
            elif mt == 'link':  s = f'[{s}]({m[\"attrs\"][\"href\"]})'
        return s
    if t == 'paragraph':    return ''.join(md(n) for n in c) + '\n'
    if t == 'heading':      return '#'*a.get('level',1) + ' ' + ''.join(md(n) for n in c) + '\n'
    if t == 'blockquote':   return '\n'.join('> '+l for l in ''.join(md(n) for n in c).splitlines()) + '\n'
    if t == 'codeBlock':    return f\"\`\`\`{a.get('language','')}\n{''.join(md(n) for n in c)}\n\`\`\`\n\"
    if t == 'bulletList':
        return '\n'.join('  '*depth + '- ' + ''.join(md(n,depth+1) for n in i.get('content',[])).strip() for i in c) + '\n'
    if t == 'orderedList':
        return '\n'.join('  '*depth + f'{j+1}. ' + ''.join(md(n,depth+1) for n in i.get('content',[])).strip() for j,i in enumerate(c)) + '\n'
    return ''.join(md(n,depth) for n in c)

print(md(json.load(sys.stdin)['fields']['description']))
"
