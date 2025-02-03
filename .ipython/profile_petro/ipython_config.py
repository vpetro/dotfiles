# Configuration file for ipython.
import os.path

c = get_config()

c.TerminalIPythonApp.profile = u'sh'
c.TerminalIPythonApp.display_banner = False
c.TerminalInteractiveShell.editor = u'vim'
c.TerminalInteractiveShell.editing_mode = u'vi'
c.TerminalInteractiveShell.term_title = True
c.TerminalInteractiveShell.cache_size = 1000
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.pdb = False

c.InteractiveShell.colors = 'NoColor'

c.TerminalIPythonApp.exec_files = [
    os.path.join(
        os.path.expanduser('~'), '.ipython/profile_petro/code.py'
    ),
]
