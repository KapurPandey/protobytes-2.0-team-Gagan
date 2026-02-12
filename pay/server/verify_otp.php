<?php
header("Access-Control-Allow-Origin: *");

// Step 1: Connect to the database
// Step 1: Connect to the database
include 'db_config.php';

if ($conn->connect_error) die("Connection failed");

// Get POST data
$username = $_POST['username'];
$otp = $_POST['otp'];

// Check OTP in pending_users
$stmt = $conn->prepare("SELECT email, password_hash, otp FROM pending_user WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows == 0) {
    echo "No pending verification found";
    exit;
}

$stmt->bind_result($email, $password, $saved_otp);
$stmt->fetch();

if ($otp !== $saved_otp) {
    echo "Invalid OTP";
    exit;
}

// OTP is valid — insert into users table
$stmt->close();

$stmt = $conn->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $username, $email, $password);

if ($stmt->execute()) {
    // Delete from pending_users
    $del = $conn->prepare("DELETE FROM pending_user WHERE username = ?");
    $del->bind_param("s", $username);
    $del->execute();
    $del->close();

    echo "success";
} else {
    echo "DB insert error";
}

$stmt->close();
$conn->close();
?>
