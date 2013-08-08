import wx
import sys
import os
import subprocess
import re
from threading import Thread
import webbrowser
from win32api import ShellExecute

from urllib import urlencode
from httplib import HTTPConnection
from base64 import encodestring
from ConfigParser import ConfigParser

__dir__ = os.path.dirname(__file__)

# Event definitions
ID_STOP_EVT = wx.NewId()
ID_OPEN_EVT = wx.NewId()
ID_HELP_EVT = wx.NewId()
ID_TOGGLELOG_EVT = wx.NewId()

ID_LOG_EVT = wx.NewId()
ID_CHILD_EVT = wx.NewId()

def stopZope(port, auth):

    params = urlencode({'manage_shutdown:action': 'Shutdown'})
    headers = {
            'Content-Type': 'Application/x-www-form-urlencoded',
            'Accept': 'text/plain',
            'Authorization': 'Basic %s' % encodestring(auth)
            }
    conn = HTTPConnection('127.0.0.1:8080')
    conn.request('POST', '/Control_Panel', params, headers)

    # Throw the response away
    conn.getresponse().read()
    conn.close()

def imageFromFilename(filename):
    f = open(filename, 'rb')
    img = wx.ImageFromStream(f)
    f.close()
    return wx.BitmapFromImage(img)

# Log output from zope's stdout is sent to the controller process using
# LogEvent's
class LogEvent(wx.PyEvent):
    def __init__(self, data):
        wx.PyEvent.__init__(self)
        self.SetEventType(ID_LOG_EVT)
        self.data = data

# Other events are sent using ChildEvent's
class ChildEvent(wx.PyEvent):
    def __init__(self, event):
        wx.PyEvent.__init__(self)
        self.SetEventType(ID_CHILD_EVT)
        self.event = event

class LogUpdateThread(Thread):
    def __init__(self, notify, stdin):
        self._notify = notify
        self._stdin = stdin
        Thread.__init__(self)

    def run(self):
        try:
            line = self._stdin.readline()
            while line:
                wx.PostEvent(self._notify, LogEvent(line))
                line = self._stdin.readline()
        except ValueError:
            # Someone closed us the file!  We are on the way to destruction!
            pass

        # If we are here, we dropped out of the while loop above and the
        # child process is very likely dead. Let someone know...
        # Just pass 0 as the event since its the only one we care about right
        # now.
        wx.PostEvent(self._notify, ChildEvent(0))

class LogApp(wx.App):

    def __init__(self, nestedapp, port, auth):
        self._nestedapp = nestedapp
        self._port = port
        self._auth = auth
        wx.App.__init__(self, redirect=False)

        # Logs are checked for these regexes, and the relevant handler is called
        self._logEvents = (
            (re.compile('Zope Ready to handle requests'), self.onZopeReady),
        )

    def OnInit(self):
        self.frame = wx.Frame(None, -1, title='TARMII Controller',
            size=(650, 360),
            style=wx.DEFAULT_FRAME_STYLE)

        # Set the window icon
        icon = wx.EmptyIcon()
        icon.LoadFile(os.path.join(__dir__, 'icon.ico'), wx.BITMAP_TYPE_ICO)
        self.frame.SetIcon(icon)

        panel = wx.Panel(self.frame, -1)

        self.statusbar = self.frame.CreateStatusBar()
        self.setStatus('STARTING UP', 'YELLOW')

        splash = imageFromFilename(os.path.join(__dir__, 'logo.png'))
        self.splash = wx.StaticBitmap(panel, -1, bitmap=splash,
                                      size=(610, 220), pos=(20,20),
                                      style=wx.SUNKEN_BORDER)

        self.log = wx.TextCtrl(panel, -1, size=(610, 220),
            pos=(20, 20),
            style = wx.TE_MULTILINE|wx.TE_READONLY|wx.HSCROLL)

        self.stopButton = wx.Button(panel, ID_STOP_EVT, 'Stop TARMII Server', pos=(20, 260))
        self.stopButton.Disable()
        self.Bind(wx.EVT_BUTTON, self.onStop, id=ID_STOP_EVT)

        self.openButton = wx.Button(panel, ID_OPEN_EVT, 'Open TARMII', pos=(140, 260))
        self.openButton.Disable()
        self.Bind(wx.EVT_BUTTON, self.onOpen, id=ID_OPEN_EVT)

        self.toggleLogButton = wx.Button(panel, ID_TOGGLELOG_EVT, 'Show Log',
                                         pos=(260, 260))
        self.Bind(wx.EVT_BUTTON, self.onToggleLog, id=ID_TOGGLELOG_EVT)

        self.pdfButton = wx.Button(panel, ID_HELP_EVT, 'Help', pos=(380, 260))
        self.Bind(wx.EVT_BUTTON, self.onHelp, id=ID_HELP_EVT)

        # Connect events to their handlers
        self.Connect(-1, -1, ID_LOG_EVT, self.onLogUpdate)
        self.Connect(-1, -1, ID_CHILD_EVT, self.onChildEvent)

        # Call onClose if the frame is closed
        self.frame.Bind(wx.EVT_CLOSE, self.onClose)

        self.hide()
        self.frame.Show()

        # Start log updater thread
        logthread = LogUpdateThread(self, self._nestedapp.stdout)
        logthread.start()
        return True

    def show(self):
        self.showLog = True
        self.splash.Hide()
        self.log.Show()
        self.toggleLogButton.SetLabel('Hide Log')

    def hide(self):
        self.showLog = False
        self.log.Hide()
        self.splash.Show()
        self.toggleLogButton.SetLabel('Show Log')

    def setStatus(self, text, colour):
        self.statusbar.SetStatusText(text)
        self.statusbar.SetBackgroundColour(colour)
        self.statusbar.Refresh()

    def onStop(self, event):
        self.setStatus('SHUTTING DOWN', 'YELLOW')
        self.openButton.Disable()
        self.stopButton.Disable()
        stopZope(self._port, self._auth)

    def onOpen(self, event):
	# This depeneds on a VHM mapping of localhost:8080 /tarmii in the root
	# of the zope instance!
	# This is also why the url to stop tarmii has to be 127.0.0.1:8080
        webbrowser.open('http://localhost:8080')

    def onHelp(self, event):
	ShellExecute(
	    0,
	    'open',
	    'docs\\help.pdf',
	    None,
	    '.',
	    1)

    def onToggleLog(self, event):
        if self.showLog:
            self.hide()
        else:
            self.show()

    def onLogUpdate(self, event):
        self.log.WriteText(event.data)
        for li in self._logEvents:
            r = li[0]
            fn = li[1]
            if r.search(event.data) is not None:
                fn()

    def onClose(self, event):
        # Initiate a graceful stop
        self.onStop(None)
        # Tell the upper layers that we won't be closing shop just yet
        if event.CanVeto():
            event.Veto(True)

    def onChildEvent(self, event):
        # Your child is dead. Follow suit.
        self.Exit()

    def onZopeReady(self):
        self.setStatus('READY', 'GREEN')
        self.openButton.Enable()
        self.stopButton.Enable()

def main():
    # First argument is path to our buildout
    configfile = os.path.join(sys.argv[1], '.installed.cfg')
    config = ConfigParser()

    config.read([configfile])
    instance = config.get('instance', 'location')
    bindir = config.get('instance', 'bin-directory')
    auth = config.get('instance', 'user')
    port = config.get('instance', 'http-address')

    # Specifically use the same interpreter as the one we were called with.
    # On windows where we might be called as pythonw. Calling runzope directly
    # on windows calls runzope-script.py with straight python, causing an
    # irritating dos box.
    args = [sys.executable]

    # Special workaround for windows
    w32_runzope = os.path.join(bindir, 'run-instance-script.py')
    if os.path.exists(w32_runzope):
        args.append(w32_runzope)
    else:
        args.append(os.path.join(bindir, 'runzope'))

    args.extend(['-C', os.path.join(instance, 'etc', 'zope.conf')])

    # Run the nested application
    nested = subprocess.Popen(args,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT)
    nested.stdin.close()
    app = LogApp(nested, port, auth)
    app.MainLoop()

if __name__ =="__main__":
    main()
