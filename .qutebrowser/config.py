import os


os.environ["PATH"] += ":/usr/local/bin"

# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103

config.load_autoconfig()

c.colors.webpage.darkmode.enabled = True

c.fonts.completion.entry = "Bold 12px VictorMono Nerd Font"
c.fonts.completion.category = "Bold 12px VictorMono Nerd Font"
c.fonts.debug_console = "Bold 12px VictorMono Nerd Font"
c.fonts.downloads = "Bold 12px VictorMono Nerd Font"
c.fonts.hints = "Bold 12px VictorMono Nerd Font"
c.fonts.keyhint = "Bold 12px VictorMono Nerd Font"
c.fonts.messages.info = "Bold 12px VictorMono Nerd Font"
c.fonts.messages.error = "Bold 12px VictorMono Nerd Font"
c.fonts.prompts = "Bold 12px VictorMono Nerd Font"
c.fonts.statusbar = "Bold 12px VictorMono Nerd Font"
c.fonts.tabs.selected = "Bold 13px VictorMono Nerd Font"
c.fonts.tabs.unselected = "Bold 13px VictorMono Nerd Font"

c.tabs.position = "left"

c.hints.mode = 'number'

config.bind('E', 'config-edit')
config.bind('R', 'config-source ;; message-info config-reloaded')

c.content.headers.user_agent = "Mozilla/5.0 (X11; Linux i686; rv:79.0) Gecko/20100101 Firefox/79.0"
c.content.webrtc_ip_handling_policy = "disable-non-proxied-udp"
c.content.webgl = False
c.qt.args = ['disable-logging', 'disable-reading-from-canvas']


config.bind('o', 'cmd-set-text -s :open -t')
config.bind('j', 'scroll-px 0 200')
config.bind('k', 'scroll-px 0 -200')
config.bind('h', 'back')
config.bind('l', 'forward')

# tab movement
config.bind('<Meta-[>', 'tab-prev')
config.bind('<Meta-]>', 'tab-next')

config.bind('<Meta-1>', 'tab-focus 1')
config.bind('<Meta-2>', 'tab-focus 2')
config.bind('<Meta-3>', 'tab-focus 3')
config.bind('<Meta-4>', 'tab-focus 4')
config.bind('<Meta-5>', 'tab-focus 5')
config.bind('<Meta-6>', 'tab-focus 6')
config.bind('<Meta-7>', 'tab-focus 7')
config.bind('<Meta-8>', 'tab-focus 8')
config.bind('<Meta-9>', 'tab-focus 9')

config.set('tabs.title.format', '{audio}{index}: {host} - {current_title}')

config.bind('gi', 'hint inputs --first')

# spawnning
mpv_path = "/opt/homebrew/bin/mpv"
config.bind(';m', 'hint links spawn ' + mpv_path + ' "{hint-url}"')
config.bind('M', 'spawn ' + mpv_path + ' "{url}"')

config.bind(';e', 'hint inputs ;; later 1000 edit-text')

config.bind("V", 'open --private about:blank')
config.bind("<Meta-q>", "close")

qsites = {
    't': 'translate.google.com',
    'y': 'youtube.com',
    # 'rr': 'old.reddit.com',
    'rv': 'old.reddit.com/r/neovim/new',
    # 'rs': 'old.reddit.com/r/scala/new',
    # 'rh': 'old.reddit.com/r/haskell/new',
    'gt': 'github.com',
}

for k, v in qsites.items():
    config.bind("gn" + k, 'open -t ' + v)


c.downloads.location.directory = "~/Downloads"

c.editor.command = ["/opt/homebrew/bin/alacritty", "-e", "/opt/homebrew/bin/nvim", "{file}", "-c", "normal {line}G{column0}l"]

config.set('hints.selectors', {'preview': ['.expando-button']}, pattern='*://*.reddit.com/*')


c.hints.next_regexes = ["\\b[^.]next[^.]\\b", "\\bmore\\b", "\\bnewer\\b", "\\b[>\u2192\u226b]\\b", "\\b(>>|\u00bb)\\b", "\\bcontinue\\b", "\u00bb"]
c.hints.prev_regexes = ["\\bprev(ious)?\\b", "\\bback\\b", "\\bolder\\b", "\\b[<\u2190\u226a]\\b", "\\b(<<|\u00ab)\\b", "\u00ab"]


c.url.default_page = 'about:blank'
c.url.start_pages = ['about:blank']

c.url.searchengines = {
    'DEFAULT': 'https://www.duckduckgo.com?q={}',
    'st': 'https://www.startpage.com/do/search?query={}',
    'gh': 'https://github.com/search?q={}',
    'gg': 'https://encrypted.google.com/search?q={}',
    'gd': 'https://www.goodreads.com/search?q={}',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'fc': 'https://www.vatefaireconjuguer.com/search?verb={}',
    'ft': 'https://context.reverso.net/translation/french-english/{}',
    'sr': 'https://old.reddit.com/r/{}'
}

config.bind(',', 'enter-mode passthrough', mode='normal')
config.bind('<Escape>', 'leave-mode', mode='passthrough')

config.bind("xx", "jseval --quiet --file ~/.qutebrowser/data/js/no-floating.js")

config.set('content.blocking.method', 'both')
config.set(
    'content.blocking.hosts.lists',
    [
        'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
    ]
)

# block javascript on the following sites

javascript_blacklist = [
    'vatefaireconjuguer.com',
]

fmt = '*://*.{}'
for domain in javascript_blacklist:
    pattern = fmt.format(domain)
    config.set('content.javascript.enabled', False, pattern)


config.set(
    'content.blocking.whitelist',
    [
        'https://rockthejvm.com/*',
        'https://pipedream.wistia.com/*',
        'https://distillery.wistia.com'
    ]
)

# rewrite requests to the following links
import qutebrowser.api.interceptor

def rewrite(request: qutebrowser.api.interceptor.Request):
    if request.request_url.host() == 'www.reddit.com':
        request.request_url.setHost('old.reddit.com')
        try:
            request.redirect(request.request_url)
        except:
            pass

qutebrowser.api.interceptor.register(rewrite)
