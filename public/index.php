<?php
// Test file to verify PHP setup is working

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Development Environment</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .status {
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
        }
        .success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .info {
            background: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 20px 0;
        }
        .card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #007bff;
        }
        .card h3 {
            margin-top: 0;
        }
        code {
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'SFMono-Regular', Menlo, Monaco, Consolas, monospace;
        }
        .links {
            margin-top: 30px;
        }
        .links a {
            display: inline-block;
            margin-right: 15px;
            color: #007bff;
            text-decoration: none;
            padding: 8px 16px;
            border: 1px solid #007bff;
            border-radius: 4px;
            transition: all 0.2s;
        }
        .links a:hover {
            background: #007bff;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Docker Development Environment</h1>
        
        <div class="status success">
            <strong>✅ PHP is working!</strong> Your development environment is up and running.
        </div>

        <div class="grid">
            <div class="card">
                <h3>🐘 PHP Information</h3>
                <p><strong>Version:</strong> <?php echo PHP_VERSION; ?></p>
                <p><strong>SAPI:</strong> <?php echo php_sapi_name(); ?></p>
                <p><strong>Server:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></p>
            </div>

            <div class="card">
                <h3>🌐 Server Information</h3>
                <p><strong>Host:</strong> <?php echo $_SERVER['HTTP_HOST'] ?? 'localhost'; ?></p>
                <p><strong>Port:</strong> <?php echo $_SERVER['SERVER_PORT'] ?? '80'; ?></p>
                <p><strong>Protocol:</strong> <?php echo isset($_SERVER['HTTPS']) ? 'HTTPS' : 'HTTP'; ?></p>
            </div>

            <div class="card">
                <h3>📁 Environment</h3>
                <p><strong>Document Root:</strong> <code><?php echo $_SERVER['DOCUMENT_ROOT']; ?></code></p>
                <p><strong>Script Name:</strong> <code><?php echo $_SERVER['SCRIPT_NAME']; ?></code></p>
                <p><strong>Working Directory:</strong> <code><?php echo getcwd(); ?></code></p>
            </div>

            <div class="card">
                <h3>🔧 PHP Extensions</h3>
                <?php
                $extensions = ['pdo_mysql', 'zip', 'gd', 'mbstring', 'xml', 'curl'];
                foreach ($extensions as $ext): ?>
                    <p><strong><?php echo $ext; ?>:</strong> 
                        <?php if (extension_loaded($ext)): ?>
                            <span style="color: #28a745;">✅ Loaded</span>
                        <?php else: ?>
                            <span style="color: #dc3545;">❌ Not loaded</span>
                        <?php endif; ?>
                    </p>
                <?php endforeach; ?>
            </div>
        </div>

        <div class="status info">
            <strong>💡 Next Steps:</strong>
            <ul>
                <li>Test database connection: <a href="db.php">db.php</a></li>
                <li>Run <code>make composer install</code> if you have a composer.json</li>
                <li>Generate SSL certificates: <code>make certs</code></li>
                <li>Check available commands: <code>make help</code></li>
            </ul>
        </div>

        <div class="links">
            <a href="db.php">Test Database</a>
            <a href="<?php echo 'http://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') . ':' . ($_SERVER['SERVER_PORT'] ?? '80') . '/?phpinfo=1'; ?>">PHP Info</a>
        </div>

        <?php if (isset($_GET['phpinfo']) && $_GET['phpinfo'] == '1'): ?>
            <div style="margin-top: 30px;">
                <h2>PHP Configuration</h2>
                <?php phpinfo(); ?>
            </div>
        <?php endif; ?>
    </div>
</body>
</html>