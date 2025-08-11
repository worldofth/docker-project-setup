<?php
// Database connection test

// Database configuration from environment
$dbHost = $_ENV['DB_HOST'] ?? 'mysql';
$dbPort = $_ENV['DB_PORT'] ?? '3306';
$dbName = $_ENV['DB_DATABASE'] ?? 'laravel';
$dbUser = $_ENV['DB_USERNAME'] ?? 'laravel';
$dbPass = $_ENV['DB_PASSWORD'] ?? 'laravel';

$connectionStatus = [];
$mysqlVersion = null;
$tables = [];
$error = null;

try {
    // Test MySQL connection
    $dsn = "mysql:host={$dbHost};port={$dbPort};dbname={$dbName};charset=utf8mb4";
    $pdo = new PDO($dsn, $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    
    $connectionStatus['mysql'] = true;
    
    // Get MySQL version
    $stmt = $pdo->query('SELECT VERSION() as version');
    $result = $stmt->fetch();
    $mysqlVersion = $result['version'];
    
    // Get list of tables
    $stmt = $pdo->query('SHOW TABLES');
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
} catch (PDOException $e) {
    $connectionStatus['mysql'] = false;
    $error = $e->getMessage();
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Connection Test</title>
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
        .error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
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
        .command {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            border-left: 4px solid #6c757d;
            margin: 10px 0;
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
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        th, td {
            padding: 8px 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #f8f9fa;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🗄️ Database Connection Test</h1>
        
        <?php if ($connectionStatus['mysql']): ?>
            <div class="status success">
                <strong>✅ Database connection successful!</strong> MySQL is running and accessible.
            </div>
        <?php else: ?>
            <div class="status error">
                <strong>❌ Database connection failed!</strong><br>
                Error: <?php echo htmlspecialchars($error); ?>
            </div>
        <?php endif; ?>

        <div class="grid">
            <div class="card">
                <h3>🔗 Connection Details</h3>
                <p><strong>Host:</strong> <?php echo htmlspecialchars($dbHost); ?></p>
                <p><strong>Port:</strong> <?php echo htmlspecialchars($dbPort); ?></p>
                <p><strong>Database:</strong> <?php echo htmlspecialchars($dbName); ?></p>
                <p><strong>Username:</strong> <?php echo htmlspecialchars($dbUser); ?></p>
            </div>

            <?php if ($connectionStatus['mysql']): ?>
                <div class="card">
                    <h3>🐬 MySQL Information</h3>
                    <p><strong>Version:</strong> <?php echo htmlspecialchars($mysqlVersion); ?></p>
                    <p><strong>Tables:</strong> <?php echo count($tables); ?></p>
                    <p><strong>Status:</strong> <span style="color: #28a745;">Connected</span></p>
                </div>
            <?php else: ?>
                <div class="card">
                    <h3>🔧 Troubleshooting</h3>
                    <p>If you're seeing connection errors:</p>
                    <ul>
                        <li>Check if MySQL container is running</li>
                        <li>Verify .env database settings</li>
                        <li>Wait a moment for MySQL to fully start</li>
                    </ul>
                </div>
            <?php endif; ?>
        </div>

        <?php if ($connectionStatus['mysql'] && !empty($tables)): ?>
            <div class="card">
                <h3>📋 Database Tables</h3>
                <table>
                    <thead>
                        <tr>
                            <th>Table Name</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($tables as $table): ?>
                            <tr>
                                <td><code><?php echo htmlspecialchars($table); ?></code></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php elseif ($connectionStatus['mysql']): ?>
            <div class="status info">
                <strong>💡 Database is empty</strong><br>
                The database connection works, but no tables exist yet. This is normal for a fresh setup.
            </div>
        <?php endif; ?>

        <div class="status info">
            <strong>🛠️ Useful Commands:</strong>
            <div class="command">make db-cli</div>
            <p>Access the MySQL command line interface</p>
            
            <div class="command">make db-dump</div>
            <p>Create a backup of your database</p>
            
            <div class="command">make db-import FILE=backup.sql</div>
            <p>Import a SQL file into the database</p>
            
            <div class="command">make db-reset</div>
            <p>Drop and recreate the database (careful!)</p>
        </div>

        <div class="links">
            <a href="index.php">← Back to Home</a>
            <?php if ($connectionStatus['mysql']): ?>
                <a href="?refresh=1">🔄 Refresh</a>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>