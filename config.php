<?php
// This variable is for high-load panels whose response time is long and the bot cannot communicate with the online panel.
// null means default PHP/network timeout settings.
$request_exec_timeout = getenv('REQUEST_EXEC_TIMEOUT') !== false && getenv('REQUEST_EXEC_TIMEOUT') !== ''
    ? (int) getenv('REQUEST_EXEC_TIMEOUT')
    : null;

$databaseUrl = getenv('DATABASE_URL') ?: getenv('MYSQL_URL') ?: '';
$databaseParts = $databaseUrl ? parse_url($databaseUrl) : [];

$dbhost = getenv('DB_HOST') ?: getenv('MYSQLHOST') ?: ($databaseParts['host'] ?? '{database_url}');
$dbport = getenv('DB_PORT') ?: getenv('MYSQLPORT') ?: ($databaseParts['port'] ?? 3306);
$dbname = getenv('DB_NAME') ?: getenv('MYSQLDATABASE') ?: (isset($databaseParts['path']) ? ltrim($databaseParts['path'], '/') : '{database_name}');
$usernamedb = getenv('DB_USER') ?: getenv('MYSQLUSER') ?: ($databaseParts['user'] ?? '{username_db}');
$passworddb = getenv('DB_PASSWORD') ?: getenv('MYSQLPASSWORD') ?: ($databaseParts['pass'] ?? '{password_db}');

$APIKEY = getenv('API_KEY') ?: getenv('BOT_TOKEN') ?: '{API_KEY}';
$adminnumber = getenv('ADMIN_NUMBER') ?: getenv('ADMIN_CHAT_ID') ?: '{admin_number}';
$domainhosts = getenv('DOMAIN_HOSTS') ?: getenv('DOMAIN_NAME') ?: getenv('RAILWAY_PUBLIC_DOMAIN') ?: '{domain_name}';
$usernamebot = getenv('USERNAME_BOT') ?: getenv('BOT_USERNAME') ?: '{username_bot}';

$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
];
$dsn = "mysql:host=$dbhost;port=$dbport;dbname=$dbname;charset=utf8mb4";
try {
    $pdo = new PDO($dsn, $usernamedb, $passworddb, $options);
} catch (\PDOException $e) {
    error_log("Database connection failed: " . $e->getMessage());
    if (getenv('MIRZABOT_DB_PROBE') === '1') {
        exit(1);
    }
    die("error: database connection failed");
}
?>
