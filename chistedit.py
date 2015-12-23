# chistedit.py
#
# Copyright 2014 Facebook, Inc.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.
"""
An interactive ncurses interface to histedit

This extensions allows you to interactively move around changesets
or change the action to perform while keeping track of possible
conflicts.

Use up/down or j/k to move up and down. Select a commit via space and move
it around. You can use d/e/f/m/r to change the action of a commit. You
can cycle through available commands with left/h or right/l.

The diff for the current commit can be viewed by pressing v. To apply
the commands press C, which will call histedit.

The current conflict deteciton mechanism is based on a per-file
comparision. Reordered changesets that touch the sames files are
considered a "potential conflict".  Please note that Mercurial's merge
algorithm might still be able to merge these files without conflict.
"""

from __future__ import print_function
from hgext import histedit
from mercurial import cmdutil
from mercurial import extensions
from mercurial import node
from mercurial import scmutil
from mercurial import error
from mercurial import util
from mercurial.i18n import _
from hgext import color

import functools
import os
import sys

try:
    import curses
except ImportError:
    print("Python curses library required", file=sys.stderr)

KEY_NEXT_ACTION = ['h', 'KEY_RIGHT']
KEY_PREV_ACTION = ['l', 'KEY_LEFT']
KEY_DOWN = ['j', 'KEY_DOWN']
KEY_UP = ['k', 'KEY_UP']
KEY_SEL = [' ']
KEY_QUIT = ['q']
KEY_HISTEDIT = ['C']
KEY_SHOWPATCH = ['v']
KEY_HELP = ['?']
KEY_ACTION = {
        'd': 'drop',
        'e': 'edit',
        'f': 'fold',
        'm': 'mess',
        'p': 'pick',
        'r': 'roll',
    }
KEY_LIST = ['pick', 'edit', 'fold', 'drop', 'mess', 'roll']

COLOR_HELP, COLOR_SELECTED, COLOR_OK, COLOR_WARN  = 1, 2, 3, 4

E_QUIT, E_HISTEDIT = 1, 2
MODE_PATCH, MODE_RULES, MODE_HELP = 1, 2, 3

class histeditrule(object):
    def __init__(self, ctx, pos, action='pick'):
        self.ctx = ctx
        self.action = action
        self.origpos = pos
        self.pos = pos
        self.conflicts = []

    def __str__(self):
        action = self.action
        h = self.ctx.hex()[0:12]
        r = self.ctx.rev()
        desc = self.ctx.description().splitlines()[0].strip()
        return "#{0:<2} {1}   {2}:{3}   {4}".format(
                self.origpos, action, r, h, desc)

    def checkconflicts(self, other):
        if other.pos > self.pos and other.origpos <= self.origpos:
            if set(other.ctx.files()) & set(self.ctx.files()) != set():
                self.conflicts.append(other)
                return self.conflicts

        if other in self.conflicts:
            self.conflicts.remove(other)
        return self.conflicts

# ============ EVENTS ===============
def movecursor(state, oldpos, newpos):
    state['pos'] = newpos

def makeselection(state, pos):
    state['selected'] = pos

def swap(state, oldpos, newpos):
    """Swap two positions and calculate necessary conflicts in
    O(|newpos-oldpos|) time"""

    rules = state['rules']
    assert 0 <= oldpos < len(rules) and 0 <= newpos < len(rules)

    rules[oldpos], rules[newpos] = rules[newpos], rules[oldpos]

    # TODO: swap should not know about histeditrule's internals
    rules[newpos].pos = newpos
    rules[oldpos].pos = oldpos

    start = min(oldpos, newpos)
    end = max(oldpos, newpos)
    for r in xrange(start, end + 1):
        rules[newpos].checkconflicts(rules[r])
        rules[oldpos].checkconflicts(rules[r])

    makeselection(state, newpos)

def changeaction(state, pos, action):
    """Change the action state on the given position to the new action"""
    rules = state['rules']
    assert 0 <= pos < len(rules)
    rules[pos].action = action

def cycleaction(state, pos, next=False):
    """Changes the action state the next or the previous action from
    the action list"""
    rules = state['rules']
    assert 0 <= pos < len(rules)
    current = rules[pos].action

    assert current in KEY_ACTION.values()
    assert current in KEY_LIST

    index = KEY_LIST.index(current)
    if next:
        index += 1
    else:
        index -= 1
    changeaction(state, pos, KEY_LIST[index % len(KEY_LIST)])

def event(state, ch):
    """Change state based on the current character input

    This takes the current state and based on the current charcter input from
    the user we change the state.
    """
    selected = state['selected']
    oldpos = state['pos']
    rules = state['rules']
    if ch in KEY_DOWN:
        newpos = min(oldpos + 1, len(rules) - 1)
        movecursor(state, oldpos, newpos)
        if selected is not None:
            swap(state, oldpos, newpos)
    if ch in KEY_UP:
        newpos = max(0, oldpos - 1)
        movecursor(state, oldpos, newpos)
        if selected is not None:
            swap(state, oldpos, newpos)
    if ch in KEY_NEXT_ACTION:
        cycleaction(state, oldpos, next=True)
    if ch in KEY_PREV_ACTION:
        cycleaction(state, oldpos, next=False)
    if ch in KEY_SEL:
        selected = oldpos if selected is None else None
        makeselection(state, selected)
    if '0' <= ch <= '9' and int(ch) < len(rules):
        newrule = next((r for r in rules if r.origpos == int(ch)))
        movecursor(state, oldpos, newrule.pos)
        if selected is not None:
            swap(state, oldpos, newrule.pos)
    if ch in KEY_ACTION:
        changeaction(state, oldpos, KEY_ACTION[ch])
    if ch in KEY_SHOWPATCH:
        cur, prev = state['mode']
        if cur == MODE_PATCH:
            state['mode'] = (MODE_RULES, cur)
        else:
            state['mode'] = (MODE_PATCH, cur)
    if ch in KEY_HELP:
        cur, prev = state['mode']
        if cur == MODE_HELP:
            state['mode'] = (MODE_RULES, cur)
        else:
            state['mode'] = (MODE_HELP, cur)
    if ch in KEY_QUIT:
        return E_QUIT
    if ch in KEY_HISTEDIT:
        return E_HISTEDIT

def makecommands(rules):
    """Returns a list of commands consumable by histedit --commands based on
    our list of rules"""
    commands = []
    for rules in rules:
        commands.append("{0} {1}\n".format(rules.action, rules.ctx))
    return commands

def addln(win, y, x, line, color=None):
    """Add a line to the given window left padding but 100% filled with
    whitespace characters, so that the color appears on the whole line"""
    maxy, maxx = win.getmaxyx()
    length = maxx - 1 - x
    line = ("{0:<%d}" % length).format(str(line).strip())[:length]
    if y < 0:
        y = maxy + y
    if x < 0:
        x = maxx + x
    if color:
        win.addstr(y, x, line, color)
    else:
        win.addstr(y, x, line)

def main(repo, rules, stdscr):
    # initialize color pattern
    curses.init_pair(COLOR_HELP, curses.COLOR_WHITE, curses.COLOR_BLUE)
    curses.init_pair(COLOR_SELECTED, curses.COLOR_BLACK, curses.COLOR_WHITE)
    curses.init_pair(COLOR_WARN, curses.COLOR_BLACK, curses.COLOR_YELLOW)
    curses.init_pair(COLOR_OK, curses.COLOR_BLACK, curses.COLOR_GREEN)

    # don't display the cursor
    try:
        curses.curs_set(0)
    except curses.error:
        pass

    def rendercommit(win, state):
        """Renders the commit window that shows the log of the current selected
        commit"""
        pos = state['pos']
        rules = state['rules']
        rule = rules[pos]

        ctx = rule.ctx
        win.box(0, 0)

        maxy, maxx = win.getmaxyx()
        length = maxx - 3

        line = "changeset: {0}:{1:<12}".format(ctx.rev(), ctx)
        win.addstr(1, 1, line[:length])

        line = "user:      {0}".format(util.shortuser(ctx.user()))
        win.addstr(2, 1, line[:length])

        bms = repo.nodebookmarks(ctx.node())
        line = "bookmark:  {0}".format(' '.join(bms))
        win.addstr(3, 1, line[:length])

        line = "files:     {0}".format(','.join(ctx.files()))
        win.addstr(4, 1, line[:length])

        line = "summary:   {0}".format(ctx.description().splitlines()[0])
        win.addstr(5, 1, line[:length])

        conflicts = rule.conflicts
        if len(conflicts) > 0:
            conflictstr = ','.join(map(lambda r: str(r.ctx), conflicts))
            conflictstr = "changed files overlap with {0}".format(conflictstr)
        else:
            conflictstr = 'no overlap'

        win.addstr(6, 1, conflictstr[:length])
        win.noutrefresh()

    def renderhelp(win, state):
        help = """
?: help, up/k: move up, down/j: move down, space: select, v: view patch
d/e/f/m/p/r: change action, C: invoke histedit, q: abort
"""
        maxy, maxx = win.getmaxyx()
        for y, line in enumerate(help.splitlines()[1:3]):
            if y > maxy:
                break
            addln(win, y, 0, line, curses.color_pair(COLOR_HELP))
        win.noutrefresh()

    def renderrules(rulesscr, state):
        rules = state['rules']
        pos = state['pos']
        selected = state['selected']

        conflicts = [r.ctx for r in rules if r.conflicts]
        if len(conflicts) > 0:
            line = "potential conflict in %s" % ','.join(map(str, conflicts))
            addln(rulesscr, -1, 0, line, curses.color_pair(COLOR_WARN))

        for y, rule in enumerate(rules):
            if len(rule.conflicts) > 0:
                rulesscr.addstr(y, 0, " ", curses.color_pair(COLOR_WARN))
            else:
                rulesscr.addstr(y, 0, " ", curses.COLOR_BLACK)
            if y == selected:
                addln(rulesscr, y, 2, rule, curses.color_pair(COLOR_SELECTED))
            elif y == pos:
                addln(rulesscr, y, 2, rule, curses.A_BOLD)
            else:
                addln(rulesscr, y, 2, rule)
        rulesscr.noutrefresh()

    def renderstring(win, state, output):
        maxy, maxx = win.getmaxyx()
        length = min(maxy, len(output))
        for y in range(0, length):
            win.addstr(y, 0, output[y])
        win.noutrefresh()

    def renderpatch(win, state):
        pos = state['pos']
        rules = state['rules']
        rule = rules[pos]

        displayer = cmdutil.show_changeset(repo.ui, repo, {
            'patch': True, 'verbose': True},
            buffered=True)
        displayer.show(rule.ctx)
        displayer.close()
        output = displayer.hunk[rule.ctx.rev()].splitlines()

        renderstring(win, state, output)

    state = {
        'pos': 0,
        'rules': rules,
        'selected': None,
        'mode': (MODE_RULES, MODE_RULES),
    }

    # eventloop
    ch = None
    stdscr.clear()
    stdscr.refresh()
    while True:
        try:
            e = event(state, ch)
            if e == E_QUIT:
                return False
            if e == E_HISTEDIT:
                return state['rules']
            else:
                maxy, maxx = stdscr.getmaxyx()
                commitwin = curses.newwin(8, maxx, maxy - 8, 0)
                helpwin = curses.newwin(2, maxx, 0, 0)
                editwin = curses.newwin(maxy - 2 - 8, maxx, 2, 0)
                # start rendering
                commitwin.erase()
                helpwin.erase()
                editwin.erase()
                curmode, _ = state['mode']
                if curmode == MODE_PATCH:
                    renderpatch(editwin, state)
                elif curmode == MODE_HELP:
                    renderstring(editwin, state, __doc__.strip().splitlines())
                else:
                    renderrules(editwin, state)
                    rendercommit(commitwin, state)
                renderhelp(helpwin, state)
                curses.doupdate()
                # done rendering
                ch = stdscr.getkey()
        except curses.error:
            pass

cmdtable = {}
command = cmdutil.command(cmdtable)

testedwith = 'internal'

@command('chistedit', [
     ('k', 'keep', False,
      _("don't strip old nodes after edit is complete")),
    ('r', 'rev', [], _('first revision to be edited'))],
    _("ANCESTOR"))
def chistedit(ui, repo, *freeargs, **opts):
    """Provides a ncurses interface to histedit. Press ? in chistedit mode
    to see an extensive help. Requires python-curses to be installed."""
    def nocolor(orig, text, effects):
        return text

    # disable coloring only if we call histedit
    import hgext.color
    extensions.wrapfunction(hgext.color, 'render_effects', nocolor)
    color.render_effect = lambda text, effects: text

    try:
        keep = opts.get('keep')
        revs = opts.get('rev', [])[:]
        cmdutil.checkunfinished(repo)
        cmdutil.bailifchanged(repo)

        if os.path.exists(os.path.join(repo.path, 'histedit-state')):
            raise error.Abort(_('history edit already in progress, try '
                               '--continue or --abort'))
        revs.extend(freeargs)
        if len(revs) != 1:
            raise error.Abort(
                _('histedit requires exactly one ancestor revision'))

        rr = list(repo.set('roots(%ld)', scmutil.revrange(repo, revs)))
        if len(rr) != 1:
            raise error.Abort(_('The specified revisions must have '
                'exactly one common root'))
        root = rr[0].node()

        topmost, empty = repo.dirstate.parents()
        revs = histedit.between(repo, root, topmost, keep)
        if not revs:
            raise error.Abort(_('%s is not an ancestor of working directory') %
                             node.short(root))

        ctxs = []
        for i, r in enumerate(revs):
            ctxs.append(histeditrule(repo[r], i))
        rc = curses.wrapper(functools.partial(main, repo, ctxs))
        curses.echo()
        curses.endwin()
        if rc is False:
            ui.write(_("chistedit aborted\n"))
            return 0
        if type(rc) is list:
            ui.status(_("running histedit\n"))
            rules = makecommands(rc)
            filename = repo.join('chistedit')
            with open(filename, 'w+') as fp:
                for r in rules:
                    fp.write(r)
            opts['commands'] = filename
            return histedit.histedit(ui, repo, *freeargs, **opts)
    except KeyboardInterrupt:
        pass
    return -1
