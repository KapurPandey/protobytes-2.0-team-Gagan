<?php
header("Access-Control-Allow-Origin: *");

// Step 1: Connect to the database
// Step 1: Connect to the database
// Step 1: Connect to the database
include 'db_config.php';



if ($conn->connect_error) die("Connection failed");

// Get POST data
$username = $_POST['username'];
$password = $_POST['password'];
$email    = $_POST['email'];

// Check if user already exists in `users` or `pending_users`
$stmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
$stmt->bind_param("ss", $username, $email);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    echo "User already exists";
    exit;
}
$stmt->close();

// Check in pending_users
$stmt = $conn->prepare("SELECT id FROM pending_user WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    echo "OTP already sent";
    exit;
}
$stmt->close();

// Generate 6-digit OTP
$otp = rand(100000, 999999);

// Send email
$subject = "Your OTP Verification Code";
$message = "Your OTP is: $otp";
$headers = "From: noreply@yourdomain.com";

if (!mail($email, $subject, $message, $headers)) {
    echo "Failed to send email";
    exit;
}

// Store in pending_users
$stmt = $conn->prepare("INSERT INTO pending_user (username, email, password_hash, otp) VALUES (?, ?, ?, ?)");
$stmt->bind_param("ssss", $username, $email, $password, $otp);
if ($stmt->execute()) {
    echo "otp_sent";
} else {
    echo "DB error";
}
$stmt->close();
$conn->close();
?>
