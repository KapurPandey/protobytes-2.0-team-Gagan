<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json');

// --- 1. DB connection ---
// Step 1: Connect to the database
// --- 1. DB connection ---
// Step 1: Connect to the database
include 'db_config.php';

if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'error' => 'DB connection failed']);
    exit();
}
$conn->set_charset('utf8mb4');

// --- 2. Get and sanitize POST data ---
$username = isset($_POST['username']) ? trim($_POST['username']) : '';
$device_id = isset($_POST['device_id']) ? trim($_POST['device_id']) : '';
$name = isset($_POST['name']) ? trim($_POST['name']) : null;
$public_key = isset($_POST['public_key']) ? trim($_POST['public_key']) : '';


// --- 3. Validate required fields ---
if ($username === '' || $device_id === '' || $public_key === '') {
    echo json_encode([
        'status' => 'error',
        'error' => 'username, device_id, and public_key are required'
    ]);
    exit();
}

// --- 4. Check if username already exists ---
$check_stmt = $conn->prepare("SELECT id FROM user_info WHERE username = ?");
$check_stmt->bind_param("s", $username);
$check_stmt->execute();
$check_stmt->store_result();
if ($check_stmt->num_rows > 0) {
    echo json_encode(['status' => 'error', 'error' => 'Username already exists']);
    $check_stmt->close();
    $conn->close();
    exit();
}
$check_stmt->close();

// --- 5. Insert user ---
$insert_stmt = $conn->prepare("INSERT INTO user_info (username, device_id, name, public_key, public_key_created_at) VALUES (?, ?, ?, ?, NOW())");
$insert_stmt->bind_param("ssss", $username, $device_id, $name, $public_key);

if ($insert_stmt->execute()) {
    echo json_encode([
        'status' => 'success',
        'message' => 'User registered successfully!'
    ]);
} else {
    echo json_encode(['status' => 'error', 'error' => 'Insert failed: ' . $insert_stmt->error]);
}

$insert_stmt->close();
$conn->close();
?>
