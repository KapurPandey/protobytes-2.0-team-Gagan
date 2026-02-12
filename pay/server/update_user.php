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
$public_key = isset($_POST['public_key']) ? trim($_POST['public_key']) : '';


// --- 3. Validate required fields ---
if ($username === '' || $device_id === '' || $public_key === '') {
    echo json_encode([
        'status' => 'error',
        'error' => 'username, device_id, and public_key are required'
    ]);
    exit();
}

// --- 4. Ensure username exists ---
$check_stmt = $conn->prepare("SELECT id FROM user_info WHERE username = ?");
$check_stmt->bind_param("s", $username);
$check_stmt->execute();
$check_stmt->store_result();
if ($check_stmt->num_rows === 0) {
    // User does not exist; error
    $check_stmt->close();
    $conn->close();
    echo json_encode(['status' => 'error', 'error' => 'User does not exist']);
    exit();
}
$check_stmt->close();

// --- 5. User exists: perform UPDATE (but do NOT register new users) ---
$update_stmt = $conn->prepare(
    "UPDATE user_info SET device_id = ?, public_key = ?, public_key_created_at = NOW() WHERE username = ?"
);
if (!$update_stmt) {
    echo json_encode(['status' => 'error', 'error' => 'Update prepare failed: ' . $conn->error]);
    $conn->close();
    exit();
}
$update_stmt->bind_param("sss", $device_id, $public_key, $username);
if ($update_stmt->execute()) {
    echo json_encode([
        'status' => 'success',
        'message' => 'User updated successfully!'
    ]);
} else {
    echo json_encode(['status' => 'error', 'error' => 'Update failed: ' . $update_stmt->error]);
}

$update_stmt->close();
$conn->close();
?>
