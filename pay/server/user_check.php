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

// --- 2. Get username from POST ---
$username = isset($_POST['username']) ? trim($_POST['username']) : '';
if ($username === '') {
    echo json_encode(['status' => 'error', 'error' => 'No username provided']);
    exit();
}

// --- 3. Prepare and execute query ---
$stmt = $conn->prepare("SELECT id, username, device_id, name, public_key, public_key_created_at, balance FROM user_info WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result();

// --- 4. Bind results and fetch ---
if ($stmt->num_rows > 0) {
    $stmt->bind_result($id, $username, $device_id, $name, $public_key, $created_at, $balance);
    $stmt->fetch();

    $response = [
        'status' => 'success',
        'id' => $id,
        'username' => $username,
        'device_id' => $device_id,
        'name' => $name,
        'public_key' => $public_key,
        'public_key_created_at' => $created_at,
        'balance' => $balance
    ];
    echo json_encode($response);
} else {
    echo json_encode(['status' => 'no user']);
}

$stmt->close();
$conn->close();
?>
