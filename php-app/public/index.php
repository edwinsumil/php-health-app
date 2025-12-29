<?php

// 1. Basic Routing
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// 2. Log to Stdout
// (Only logging the essential info for production logs)
$logEntry = sprintf(
    "[%s] %s %s - %s\n",
    date('c'),
    $_SERVER['REQUEST_METHOD'],
    $uri,
    $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
);
file_put_contents('php://stdout', $logEntry);

// 3. Health Endpoint
if ($uri === '/health') {
    // Set headers and status strictly
    header('Content-Type: application/json');
    http_response_code(200);
    
    // JSON response
    echo json_encode(['status' => 'healthy']);
    exit;
}

// 4. 404 Handler
http_response_code(404);
echo "Not Found";