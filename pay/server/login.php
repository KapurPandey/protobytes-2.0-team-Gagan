<?php
// Enable CORS if needed (optional during testing)
header("Access-Control-Allow-Origin: *");


// Step 1: Connect to the database
// Step 1: Connect to the database
include 'db_config.php';

// Step 2: Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Step 3: Get data from client
$user = $_POST['username'];
$pass = $_POST['password'];  // already hashed using SHA-256 by the Python client

// Step 4: Check credentials
$stmt = $conn->prepare("SELECT id FROM users WHERE username = ? AND password_hash = ?");
$stmt->bind_param("ss", $user, $pass);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    echo "success";  //'Only authorized users can access this app.Contact the admin if you believe you should have access.' login successful
} else {
    echo "Invalid credentials";//invalid cred
}

$stmt->close();
$conn->close();
?>
