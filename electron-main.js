const { app, BrowserWindow, Menu } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow;
let serverProcess;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1200,
        height: 800,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true
        },
        icon: path.join(__dirname, 'assets', 'icon.png'),
        title: 'MCP Server Manager'
    });

    // Start the Express server
    serverProcess = spawn('node', [path.join(__dirname, 'server.js')], {
        env: { ...process.env, ELECTRON_APP: 'true' }
    });

    serverProcess.stdout.on('data', (data) => {
        console.log(`Server: ${data}`);
    });

    serverProcess.stderr.on('data', (data) => {
        console.error(`Server Error: ${data}`);
    });

    // Wait a moment for server to start, then load the URL
    setTimeout(() => {
        mainWindow.loadURL('http://localhost:3000');
    }, 1500);

    // Create application menu
    const template = [
        {
            label: 'MCP Manager',
            submenu: [
                { label: 'About MCP Manager', role: 'about' },
                { type: 'separator' },
                { label: 'Quit', accelerator: 'Command+Q', click: () => app.quit() }
            ]
        },
        {
            label: 'Edit',
            submenu: [
                { label: 'Undo', accelerator: 'Command+Z', role: 'undo' },
                { label: 'Redo', accelerator: 'Shift+Command+Z', role: 'redo' },
                { type: 'separator' },
                { label: 'Cut', accelerator: 'Command+X', role: 'cut' },
                { label: 'Copy', accelerator: 'Command+C', role: 'copy' },
                { label: 'Paste', accelerator: 'Command+V', role: 'paste' },
                { label: 'Select All', accelerator: 'Command+A', role: 'selectall' }
            ]
        },
        {
            label: 'View',
            submenu: [
                { label: 'Reload', accelerator: 'Command+R', click: () => mainWindow.reload() },
                { label: 'Toggle Developer Tools', accelerator: 'Alt+Command+I', click: () => mainWindow.webContents.toggleDevTools() }
            ]
        }
    ];

    const menu = Menu.buildFromTemplate(template);
    Menu.setApplicationMenu(menu);

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
    if (serverProcess) {
        serverProcess.kill();
    }
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (mainWindow === null) {
        createWindow();
    }
});

// Clean up server process on quit
app.on('before-quit', () => {
    if (serverProcess) {
        serverProcess.kill();
    }
});